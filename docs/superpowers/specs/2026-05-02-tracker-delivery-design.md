# Tracker 택배 교환 세부 로직 — 설계 문서

- 브랜치: `feat/#32/tracker-delivery`
- 작성일: 2026-05-02
- 범위: 택배(배송) 모드 한정. Host + Guest 양쪽 역할. 직거래(in-person) 모드는 별도 사이클로 분리.

## 0. 배경

`TrackerView`(리스트)와 `Delivery/{Host,Guest}` 시트 30종은 UI 셸이 이미 존재하지만, **모두 더미 상태**. 서비스 호출, ViewModel 로직, 시트 라우팅, 이미지 업로드 인프라가 비어 있음. 안드로이드(`trkHost/`, `trkGuest/`)에는 동일 기능이 완성되어 있고, iOS는 같은 백엔드 API를 사용. 본 사이클에서 안드로이드와 동등한 기능을 iOS에 포팅한다.

## 1. 목표

1. 트래커 카드 탭 → 역할별 Delivery 화면 진입
2. 8단계 phase 상태머신을 phase enum + 서버 status 매퍼로 표현
3. 각 phase에 매핑된 시트가 첫 진입 시 자동 표시 + 명시 탭 시 표시
4. 액션(읽기 시작 / 연장 / 완료 / 배송 / 수령 / 수령 확인) API 호출 후 상태 자동 갱신
5. S3 presigned PUT 업로드 흐름을 공통 헬퍼로 분리 (다른 도메인에서 재사용 가능하도록)
6. 에러 / 로딩은 기존 ToastView + dimmed overlay 패턴 재사용

## 2. 비목표 (Out of Scope)

- 직거래(`trkDirectHost`) 흐름
- 트래커 리스트 신규 기능 (이미 별 PR에서 처리됨)
- 푸시 알림 / 백그라운드 갱신
- 단위 테스트 추가 — 프로젝트에 테스트 인프라 부재, 컨벤션 유지
- 재시도 자동화 (사용자 수동 트리거만)
- 사진 캐싱 / 사진 뷰어 줌 같은 부가 기능

## 3. 디렉터리 / 파일 배치

```
Bookiibookii/
├─ Features/Tracker/
│  ├─ View/
│  │  ├─ TrackerView.swift                  ← 수정: navigationDestination + onTap push
│  │  └─ Delivery/
│  │     ├─ Host/
│  │     │  ├─ HostDeliveryView.swift       ← 수정: VM 주입, sheet(item:) 라우팅
│  │     │  └─ Sheets/...                   ← 수정: VM 액션 클로저 받도록
│  │     └─ Guest/...                       ← 동일
│  ├─ ViewModel/
│  │  ├─ TrackerViewModel.swift             ← 기존
│  │  ├─ HostDeliveryViewModel.swift        ← 신규
│  │  └─ GuestDeliveryViewModel.swift       ← 신규
│  └─ Domain/
│     ├─ DeliveryPhase.swift                ← 신규
│     └─ DeliverySheet.swift                ← 신규
├─ Common/DIContainer/API/
│  ├─ Common/Domain.swift                   ← 수정: 트래커 path 상수 10개 추가
│  ├─ Core/
│  │  └─ S3UploadClient.swift               ← 신규: presigned PUT 전용 (도메인 무관)
│  └─ Tracker/
│     ├─ APITarget/TrackerAPITarget.swift   ← 수정: case 10개 추가
│     └─ Service/TrackerService.swift       ← 수정: 메서드 9개 추가 + 업로드 묶음
└─ Data/Models/TrackerModels.swift          ← 수정: Detail/Shipping/Receive/Presigned/Image DTO 추가
```

## 4. API 레이어

### 4.1 path 상수 (`Common/DIContainer/API/Common/Domain.swift`)

```swift
// Tracker delivery
static let trackerDetail        = "/api/groups/%@/tracker"
static let trackerReading       = "/api/groups/%@/tracker/reading"
static let trackerExtension     = "/api/groups/%@/tracker/extension"
static let trackerDone          = "/api/groups/%@/tracker/done"
static let trackerDelivery      = "/api/groups/%@/tracker/delivery"
static let trackerReception     = "/api/groups/%@/tracker/reception"
static let trackerVerification  = "/api/groups/%@/tracker/reception/verification"
static let trackerPresignedUrl  = "/api/groups/%@/tracker/images/presigned-url"
static let trackerImageDelivery = "/api/groups/%@/tracker/images/delivery"
static let trackerImageReceived = "/api/groups/%@/tracker/images/received"
```

`%@`는 groupId 자리. APITarget에서 `String(format:, groupId)`로 치환.

### 4.2 `TrackerAPITarget` 추가 case

| case | method | path | query/body |
|---|---|---|---|
| `detail(groupId)` | GET | `trackerDetail` | — |
| `startReading(groupId)` | PATCH | `trackerReading` | — |
| `requestExtension(groupId, days)` | PATCH | `trackerExtension` | query: `days=Int` (기본 3) |
| `markDone(groupId)` | PATCH | `trackerDone` | — |
| `startShipping(groupId, body: TrackerShippingStartRequest)` | POST | `trackerDelivery` | JSON |
| `registerReceipt(groupId, body: TrackerReceiveRequest)` | PATCH | `trackerReception` | JSON |
| `verifyReception(groupId)` | PATCH | `trackerVerification` | — |
| `presignedUrl(groupId)` | POST | `trackerPresignedUrl` | — |
| `shippingImage(groupId)` | GET | `trackerImageDelivery` | — |
| `receivedImage(groupId)` | GET | `trackerImageReceived` | — |

### 4.3 `S3UploadClient` (Core, 도메인 무관)

```swift
struct S3UploadClient {
    func put(data: Data, to url: URL, contentType: String) async throws
}
```

- `URLSession.shared.upload(for: request, from: data)` 사용
- 헤더: `Content-Type` 만 설정. 인증 헤더 안 붙임 (presigned URL 자체 서명 포함)
- 응답 status `200 || 204` 외에는 `S3UploadError.unexpectedStatus(Int)` throw
- `AuthInterceptor` 우회: `URLSession.shared` 직접 사용 (혹은 인터셉터 없는 별도 세션)

### 4.4 `TrackerService` 추가 메서드

```swift
extension TrackerService {
    func fetchDetail(groupId: Int) async throws -> TrackerDetailResponse
    func startReading(groupId: Int) async throws -> TrackerDetailResponse
    func requestExtension(groupId: Int, days: Int = 3) async throws -> TrackerDetailResponse
    func markDone(groupId: Int) async throws -> TrackerDetailResponse
    func verifyReception(groupId: Int) async throws -> TrackerDetailResponse
    func fetchShippingImageURL(groupId: Int) async throws -> URL
    func fetchReceivedImageURL(groupId: Int) async throws -> URL

    // 업로드 묶음 — 내부에서 3단 호출
    func startShipping(
        groupId: Int,
        deliveryCompany: String,
        trackingNumber: String,
        image: UIImage
    ) async throws -> TrackerDetailResponse

    func registerReceipt(
        groupId: Int,
        image: UIImage
    ) async throws -> TrackerDetailResponse
}
```

**업로드 묶음 흐름** (`startShipping` / `registerReceipt` 공통):
1. `image.jpegData(compressionQuality: 0.85)` → `Data`
2. `presignedUrl(groupId)` → `(s3Key, presignedPutUrl)`
3. `s3Upload.put(data:, to: presignedPutUrl, contentType: "image/jpeg")`
4. `startShipping`이면 `POST /tracker/delivery` (s3Key 포함), `registerReceipt`이면 `PATCH /tracker/reception` (s3Key 포함)
5. 응답 → `TrackerDetailResponse` 반환

### 4.5 DTO (`Data/Models/TrackerModels.swift` 추가)

```swift
struct TrackerDetailResponse: Decodable {
    let bookTitle: String
    let partnerNickname: String
    let trackerStatus: TrackerStatusDTO    // 서버 enum 문자열
    let startDate: String?                  // ISO8601 or yyyy-MM-dd
    let endDate: String?
    let extensionCount: Int
    let extensionDays: Int
    let readingPeriod: Int
    let trackerId: Int
    let deliveryInfo: DeliveryInfoDTO?
    let meetingInfo: MeetingInfoDTO?       // 직거래 전용 — 택배 모드에서는 nil 가능
}

struct DeliveryInfoDTO: Decodable {
    let receiverName: String?
    let receiverPhone: String?
    let receiverAddress: String?
    let deliveryCompany: String?
    let trackingNumber: String?
    let isVerified: Bool
}

struct MeetingInfoDTO: Decodable {
    let meetingTime: String?
    let meetingPlace: String?
}

enum TrackerStatusDTO: String, Decodable {
    case ready = "READY"
    case hostReading = "HOST_READING"
    case hostExtension = "HOST_EXTENSION"
    case hostDone = "HOST_DONE"
    case shippingToGuest = "SHIPPING_TO_GUEST"
    case received = "RECEIVED"
    case guestReading = "GUEST_READING"
    case guestExtension = "GUEST_EXTENSION"
    case guestDone = "GUEST_DONE"
    case shippingToHost = "SHIPPING_TO_HOST"
    case returned = "RETURNED"
    case completed = "COMPLETED"
    case unknown = "UNKNOWN"
}

struct TrackerShippingStartRequest: Encodable {
    let deliveryCompany: String
    let trackingNumber: String
    let s3Key: String
}

struct TrackerReceiveRequest: Encodable {
    let s3Key: String
}

struct PresignedUrlResponse: Decodable {
    let s3Key: String
    let presignedPutUrl: String
}

struct TrackerImageResponse: Decodable {
    let imageUrl: String
}
```

서버 status는 `unknown` fallback으로 디코딩 안전하게(`init(from:)`에서 default).

## 5. Domain 모델

### 5.1 `DeliveryPhase`

```swift
enum DeliveryPhase {
    case initState
    case hostReading
    case hostShippingReady
    case hostShipped
    case guestReading
    case guestShippingReady
    case guestShipped
    case finished

    static func from(_ status: TrackerStatusDTO) -> DeliveryPhase {
        switch status {
        case .ready: return .initState
        case .hostReading, .hostExtension: return .hostReading
        case .hostDone: return .hostShippingReady
        case .shippingToGuest: return .hostShipped
        case .received: return .guestReading
        case .guestReading, .guestExtension: return .guestReading
        case .guestDone: return .guestShippingReady
        case .shippingToHost: return .guestShipped
        case .returned, .completed: return .finished
        case .unknown: return .initState
        }
    }
}
```

### 5.2 `DeliverySheet`

```swift
enum DeliverySheet: String, Identifiable {
    case start, reading, readingStatus, readingDone
    case extendPeriod, extendRequest
    case shipping, shippingInput, shippingPhoto, shipped, shippingStatus
    case receiveConfirm, tradeFinish
    case groupManage, photoSelection, sendConfirm

    var id: String { rawValue }
}
```

각 ViewModel에 phase → 기본 시트 매퍼:

```swift
// Host
func defaultSheet(for phase: DeliveryPhase) -> DeliverySheet? {
    switch phase {
    case .initState:           return .start
    case .hostReading:         return .reading
    case .hostShippingReady:   return .shippingInput
    case .hostShipped:         return .shipped
    case .guestReading:        return .readingStatus
    case .guestShippingReady:  return .readingDone
    case .guestShipped:        return .receiveConfirm
    case .finished:            return .tradeFinish
    }
}

// Guest
func defaultSheet(for phase: DeliveryPhase) -> DeliverySheet? {
    switch phase {
    case .initState, .hostReading: return .readingStatus
    case .hostShippingReady, .hostShipped: return .shippingStatus
    case .guestReading: return .reading
    case .guestShippingReady: return .shippingInput
    case .guestShipped: return .shipped
    case .finished: return .tradeFinish
    }
}
```

## 6. ViewModel

### 6.1 공통 구조

```swift
@MainActor final class HostDeliveryViewModel: ObservableObject {
    @Published private(set) var detail: TrackerDetailResponse?
    @Published private(set) var phase: DeliveryPhase = .initState
    @Published var activeSheet: DeliverySheet?
    @Published private(set) var isLoading = false
    @Published var toastMessage: String?

    private var presentedPhases: Set<DeliveryPhase> = []

    private let groupId: Int
    private let service: TrackerService

    init(groupId: Int, service: TrackerService) { ... }

    func onAppear() async {
        await refreshDetail(autoPresent: true)
    }

    func tapStep(_ sheet: DeliverySheet) { activeSheet = sheet }
    func dismissSheet() { activeSheet = nil }

    // 액션 메서드 (시트에서 호출)
    func startReading() async             // -> service.startReading
    func requestExtension(days: Int) async // -> service.requestExtension
    func markDone() async                 // -> service.markDone
    func startShipping(company: String, trackingNumber: String, image: UIImage) async
    func registerReceipt(image: UIImage) async
    func verifyReception() async

    // private helpers
    private func refreshDetail(autoPresent: Bool) async
    private func handle(_ response: TrackerDetailResponse, autoPresent: Bool)
    private func autoPresentIfNeeded()
    private func setError(_ error: Error)
}
```

### 6.2 핵심 흐름 의사코드

```swift
private func runAction(_ block: () async throws -> TrackerDetailResponse) async {
    isLoading = true
    defer { isLoading = false }
    do {
        let response = try await block()
        handle(response, autoPresent: true)
    } catch {
        setError(error)
    }
}

private func handle(_ response: TrackerDetailResponse, autoPresent: Bool) {
    detail = response
    let newPhase = DeliveryPhase.from(response.trackerStatus)
    let phaseChanged = newPhase != phase
    phase = newPhase
    if phaseChanged && autoPresent { autoPresentIfNeeded() }
}

private func autoPresentIfNeeded() {
    guard !presentedPhases.contains(phase),
          let sheet = defaultSheet(for: phase) else { return }
    presentedPhases.insert(phase)
    activeSheet = sheet
}
```

**규칙**:
- API 액션 메서드는 모두 `runAction { try await service.xxx(...) }` 래퍼로 통일
- phase가 advance되면 새 기본 시트를 자동 표시 (한 번만)
- 사용자가 dismiss 후 같은 phase에서는 재표시 안 함, 명시 탭으로만 다시 열림

### 6.3 Guest VM 차이

- `startReading()` 없음 (Host 전용 — Guest는 수령 등록 시점에 자동으로 GUEST_READING 진입)
- 액션 가능 메서드: `requestExtension`, `markDone`, `startShipping`, `registerReceipt` 만
- `defaultSheet(for:)` 매핑이 다름 (위 5.2 참조)

## 7. View 레이어

### 7.1 진입 (`TrackerView.swift`)

```swift
@State private var path = NavigationPath()

NavigationStack(path: $path) {
    // 기존 리스트 ...
    .navigationDestination(for: TrackerItem.self) { item in
        switch (item.role, item.exchangeType) {
        case (.host, .delivery):
            HostDeliveryView(groupId: item.groupId, container: container)
        case (.guest, .delivery):
            GuestDeliveryView(groupId: item.groupId, container: container)
        default:
            EmptyView()  // 직거래는 이번 사이클 제외
        }
    }
}

TrackerCard(item: item, onTap: { path.append(item) })
```

`TrackerItem`이 `Hashable` 채택 필요 (이미 채택 안 됐으면 추가).

### 7.2 Delivery 화면

```swift
struct HostDeliveryView: View {
    @StateObject private var vm: HostDeliveryViewModel

    init(groupId: Int, container: DIContainer) {
        _vm = StateObject(wrappedValue: HostDeliveryViewModel(
            groupId: groupId,
            service: container.api.tracker
        ))
    }

    var body: some View {
        VStack { /* 7-step 카드 — 기존 UI */ }
            .task { await vm.onAppear() }
            .sheet(item: $vm.activeSheet, onDismiss: vm.dismissSheet) { sheet in
                sheetView(for: sheet)
            }
            .overlay { if vm.isLoading { LoadingOverlay() } }
            .toast($vm.toastMessage)  // 기존 ToastView modifier (signature: View.toast(_ message: Binding<String?>))
    }

    @ViewBuilder
    private func sheetView(for sheet: DeliverySheet) -> some View { ... }
}
```

각 단계 카드 탭 → `vm.tapStep(.shippingInput)` 등.

### 7.3 시트 인터페이스

각 시트는 `@ObservedObject`를 보유하지 않고 액션 클로저만 받음:

```swift
struct HostShippingInputSheet: View {
    let onSubmit: (_ company: String, _ tracking: String, _ image: UIImage) -> Void
    let onCancel: () -> Void

    @State private var company = ""
    @State private var tracking = ""
    @State private var pickedItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?

    var body: some View { ... }   // 폼 + PhotosPicker + 제출 버튼

    private var canSubmit: Bool {
        !company.isEmpty && !tracking.isEmpty && pickedImage != nil
    }
}
```

`HostDeliveryView`에서 클로저로 VM 액션 트리거:
```swift
case .shippingInput:
    HostShippingInputSheet(
        onSubmit: { c, t, img in
            Task { await vm.startShipping(company: c, trackingNumber: t, image: img) }
        },
        onCancel: vm.dismissSheet
    )
```

이미지 표시(`HostShippingPhotoSheet`, `HostReceiveConfirmSheet` 등)는 `service.fetchShippingImageURL(groupId:)`로 URL 받아 `AsyncImage`로 표시. URL 로딩은 시트 내부에서 자체 `task` 처리.

## 8. 에러 / 로딩 / 토스트

- **로딩**: `vm.isLoading` true면 `Color.black.opacity(0.3)` + `ProgressView` overlay. 시트 외부 인터랙션 차단. 시트 내부는 차단 안 함 (중첩 시 시각적 혼동 방지 위해 시트보다 zIndex 낮게)
- **토스트**: `vm.toastMessage` (옵셔널 String) 바인딩 → `Common/Components/ToastView` modifier, 자동 dismiss (기존 패턴)
- **에러 매핑**: `TrackerService` 내부에서 HTTP status / `BookiiError` 타입에 맞춰 사용자 친화 메시지로 변환:
  - 4xx → 서버 메시지 그대로
  - 401 → 인터셉터가 처리 (기존 동작)
  - 5xx / 네트워크 → "네트워크 오류, 다시 시도해주세요"
- **재시도**: 자동화 안 함. 사용자가 시트 다시 열거나 액션 다시 트리거

## 9. 검증 (테스트 대체)

자동 단위 테스트는 추가하지 않음 (프로젝트 컨벤션 유지). 대신 수동 검증 체크리스트:

### 9.1 컴파일
- `xcodebuild build` 성공

### 9.2 Host 8 phase 시뮬레이터 시나리오

| # | 진입 phase | 자동 표시 시트 | 액션 | 다음 phase | 확인 |
|---|---|---|---|---|---|
| H1 | initState | start | 읽기 시작 | hostReading | reading 시트 자동 표시 |
| H2 | hostReading | reading | 연장 요청 | hostReading (extensionCount+1) | 토스트 + 시트 갱신 |
| H3 | hostReading | reading | 완료 | hostShippingReady | shippingInput 자동 표시 |
| H4 | hostShippingReady | shippingInput | 배송 정보 + 사진 제출 | hostShipped | shipped 자동 표시, 이미지 업로드 성공 |
| H5 | hostShipped | shipped | (대기, 상대 액션) | — | 로딩/에러 없이 정보 표시. 화면 재진입 시 phase 갱신 |
| H6 | guestReading | readingStatus | (대기, 상대 액션) | — | guest 정보 표시. 화면 재진입 시 phase 갱신 |
| H7 | guestShippingReady | readingDone | (대기, 상대 액션) | — | 화면 재진입(`onAppear`) 시 guestShipped로 갱신, receiveConfirm 자동 표시 |
| H8 | guestShipped | receiveConfirm | 수령 사진 등록 | finished | tradeFinish 자동 표시 |

### 9.3 Guest 8 phase 시뮬레이터 시나리오

| # | 진입 phase | 자동 표시 시트 | 액션 | 다음 phase | 확인 |
|---|---|---|---|---|---|
| G1 | initState | readingStatus | (대기, 상대 액션) | — | host 진행 안내. 화면 재진입 시 phase 갱신 |
| G2 | hostShipped | shippingStatus | "수령 등록" 탭 → receiveConfirm 시트 → 사진 제출 | guestReading | 사진 업로드 성공, reading 자동 표시 |
| G3 | guestReading | reading | 연장 | guestReading | extensionCount+1, 토스트 + 시트 유지 |
| G4 | guestReading | reading | 완료 | guestShippingReady | shippingInput 자동 표시 |
| G5 | guestShippingReady | shippingInput | 배송 제출 | guestShipped | shipped 자동 표시, 이미지 업로드 성공 |
| G6 | guestShipped | shipped | (대기, 상대 액션) | — | 화면 재진입 시 finished로 갱신 가능 |
| G7 | finished | tradeFinish | — | — | 리뷰 화면 진입은 Out of scope. 시트 닫기까지만 검증 |

### 9.4 에러 케이스 수동 검증
- 네트워크 오프라인 상태에서 액션 → 토스트 노출
- 사진 미선택 후 제출 버튼 비활성 확인
- 4xx 에러 응답 시 메시지 표시

## 10. 구현 순서 제안

1. DTO + path 상수 + APITarget case 추가 (빌드만 통과)
2. `S3UploadClient` 작성 + 단독 빌드 확인
3. `TrackerService` 메서드 9개 + 업로드 묶음 추가
4. `DeliveryPhase` / `DeliverySheet` enum + 매퍼
5. `HostDeliveryViewModel` 작성 + Host 시트 바인딩
6. `HostDeliveryView` 라우팅 / `TrackerView` 진입 wire
7. Host 시뮬레이터 시나리오 H1~H8 검증
8. `GuestDeliveryViewModel` + Guest 화면/시트 바인딩
9. Guest 시뮬레이터 시나리오 G1~G7 검증
10. 에러/로딩/토스트 폴리싱

## 11. 위험 / 확정 안 된 점

- **상대 액션 대기 phase 갱신**: 폴링/푸시가 없어, 상대 액션으로 phase가 advance돼도 본 화면이 자동 갱신되지 않음. **`onAppear`(화면 재진입) 시점에만 refresh** — 사용자가 탭 전환 후 돌아와야 다음 단계가 보임. 명시적인 "새로고침" 버튼은 본 사이클에서 추가하지 않음 (안드로이드도 동일 동작). 이슈 제기 시 pull-to-refresh로 보강
- **서버 응답 구조 추측**: `TrackerDetailResponse` 필드 일부는 안드로이드 DTO로부터 추론. 실제 서버 응답과 맞지 않으면 디코딩 실패 가능 — 첫 단계 `fetchDetail` 실호출로 확인 필요
- **이미지 압축 품질**: 0.85 가정. 서버 용량 정책 확인 안 됨. 문제 발견 시 0.7로 낮춤
- **`MeetingInfoDTO`**: 직거래 전용이지만 같은 응답 객체에 옵셔널로 들어옴. 택배 모드에선 무시
- **`unknown` 상태 fallback**: `initState`로 처리. 실제 서버에서 unknown 응답이 오는 경우 별도 에러 화면이 더 나을 수 있음 — 향후 관찰 후 보강

---

부록: 파일 변경 영향 범위

- 신규 파일: 5개 (S3UploadClient, DeliveryPhase, DeliverySheet, HostDeliveryViewModel, GuestDeliveryViewModel)
- 수정 파일: TrackerView, HostDeliveryView, GuestDeliveryView, 시트 30종, Domain.swift, TrackerAPITarget, TrackerService, TrackerModels — 약 38개 파일
