# Tracker 택배 교환 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 안드로이드 `trkHost` / `trkGuest`와 동등한 택배 교환 세부 흐름(8 phase 상태머신, 10개 API, S3 presigned 업로드, 시트 자동 라우팅)을 iOS에 구현.

**Architecture:** Service 레이어가 API 호출 + 디코딩 + 업로드 묶음을 흡수하고, Host/Guest ViewModel은 phase enum + 액션 디스패치만 담당. View는 `sheet(item:)`으로 단일 `activeSheet` 라우팅, 첫 진입 + phase advance 시 자동 표시(한 번만).

**Tech Stack:** Swift / SwiftUI (iOS 16+), URLSession, Photos UI(`PhotosPicker`), 자체 `AuthInterceptor` actor, 자체 `TrackerService`. 기존 컨벤션: `ApiResponseDTO<T>` wrapper, `APITargetType` 프로토콜, ViewModel은 `@MainActor final class : ObservableObject`.

**참고:** 단위 테스트 추가 안 함 (프로젝트 컨벤션). 검증은 `xcodebuild` + 시뮬레이터 시나리오 실행. 각 task의 마지막 Step은 항상 빌드 확인 + 커밋.

**빌드 명령 (모든 task에서 동일):**
```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 15' build \
  -quiet
```

**스펙 참조:** `docs/superpowers/specs/2026-05-02-tracker-delivery-design.md`

---

## File Structure

```
신규
├─ Bookiibookii/Common/DIContainer/API/Core/S3UploadClient.swift
├─ Bookiibookii/Features/Tracker/Domain/DeliveryPhase.swift
├─ Bookiibookii/Features/Tracker/Domain/DeliverySheet.swift
├─ Bookiibookii/Features/Tracker/ViewModel/HostDeliveryViewModel.swift
└─ Bookiibookii/Features/Tracker/ViewModel/GuestDeliveryViewModel.swift

수정
├─ Bookiibookii/Common/DIContainer/API/Common/Domain.swift           ← path 상수 추가
├─ Bookiibookii/Common/DIContainer/API/Tracker/APITarget/TrackerAPITarget.swift
├─ Bookiibookii/Common/DIContainer/API/Tracker/Service/TrackerService.swift
├─ Bookiibookii/Data/Models/TrackerModels.swift                      ← 상세/배송/수령 DTO
├─ Bookiibookii/Features/Tracker/View/TrackerView.swift              ← navigation push
├─ Bookiibookii/Features/Tracker/View/Delivery/Host/HostDeliveryView.swift
├─ Bookiibookii/Features/Tracker/View/Delivery/Host/Sheets/*.swift   ← 콜백 wiring
├─ Bookiibookii/Features/Tracker/View/Delivery/Guest/GuestDeliveryView.swift
└─ Bookiibookii/Features/Tracker/View/Delivery/Guest/Sheets/*.swift  ← 콜백 wiring
```

---

### Task 1: 트래커 path 상수 추가

**Files:**
- Modify: `Bookiibookii/Common/DIContainer/API/Common/Domain.swift:7-19`

- [ ] **Step 1: `API.Path` 안에 트래커 상세 path 추가**

`Bookiibookii/Common/DIContainer/API/Common/Domain.swift`의 `enum Path { ... }` 블록 마지막 `static let library = "/api/library"` 바로 뒤에 다음 줄을 추가한다:

```swift
static func trackerDetail(groupId: Int)        -> String { "/api/groups/\(groupId)/tracker" }
static func trackerReading(groupId: Int)       -> String { "/api/groups/\(groupId)/tracker/reading" }
static func trackerPeriodExtension(groupId: Int) -> String { "/api/groups/\(groupId)/tracker/extension" }
static func trackerDone(groupId: Int)          -> String { "/api/groups/\(groupId)/tracker/done" }
static func trackerDelivery(groupId: Int)      -> String { "/api/groups/\(groupId)/tracker/delivery" }
static func trackerReception(groupId: Int)     -> String { "/api/groups/\(groupId)/tracker/reception" }
static func trackerVerification(groupId: Int)  -> String { "/api/groups/\(groupId)/tracker/reception/verification" }
static func trackerPresignedUrl(groupId: Int)  -> String { "/api/groups/\(groupId)/tracker/images/presigned-url" }
static func trackerImageDelivery(groupId: Int) -> String { "/api/groups/\(groupId)/tracker/images/delivery" }
static func trackerImageReceived(groupId: Int) -> String { "/api/groups/\(groupId)/tracker/images/received" }
```

호출 측에서 `API.Path.trackerDetail(groupId: groupId)`와 같이 타입 안전하게 호출한다. 기존 `static let trackers = "/api/groups/me/trackers"`는 그대로 유지.

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Common/DIContainer/API/Common/Domain.swift
git commit -m "feat(tracker): 택배 교환 path 상수 10개 추가"
```

---

### Task 2: `TrackerAPITarget`에 case 10개 추가

**Files:**
- Modify: `Bookiibookii/Common/DIContainer/API/Tracker/APITarget/TrackerAPITarget.swift`

- [ ] **Step 1: 파일 전체를 다음으로 교체**

```swift
import Foundation

// 안드로이드 TrkApi 대응 (택배 교환 포함).
enum TrackerAPITarget: APITargetType {
    case hostList
    case guestList

    case detail(groupId: Int)
    case startReading(groupId: Int)
    case requestExtension(groupId: Int, days: Int)
    case markDone(groupId: Int)
    case startShipping(groupId: Int, body: TrackerShippingStartRequest)
    case registerReceipt(groupId: Int, body: TrackerReceiveRequest)
    case verifyReception(groupId: Int)
    case presignedUrl(groupId: Int)
    case shippingImage(groupId: Int)
    case receivedImage(groupId: Int)

    var path: String {
        switch self {
        case .hostList:                            return API.Path.trackers + "/host"
        case .guestList:                           return API.Path.trackers + "/guest"
        case .detail(let id):                      return API.Path.trackerDetail(groupId: id)
        case .startReading(let id):                return API.Path.trackerReading(groupId: id)
        case .requestExtension(let id, _):         return API.Path.trackerPeriodExtension(groupId: id)
        case .markDone(let id):                    return API.Path.trackerDone(groupId: id)
        case .startShipping(let id, _):            return API.Path.trackerDelivery(groupId: id)
        case .registerReceipt(let id, _):          return API.Path.trackerReception(groupId: id)
        case .verifyReception(let id):             return API.Path.trackerVerification(groupId: id)
        case .presignedUrl(let id):                return API.Path.trackerPresignedUrl(groupId: id)
        case .shippingImage(let id):               return API.Path.trackerImageDelivery(groupId: id)
        case .receivedImage(let id):               return API.Path.trackerImageReceived(groupId: id)
        }
    }

    var method: HTTPMethod {
        switch self {
        case .hostList, .guestList,
             .detail, .shippingImage, .receivedImage:
            return .get
        case .startShipping, .presignedUrl:
            return .post
        case .startReading, .requestExtension, .markDone,
             .registerReceipt, .verifyReception:
            return .patch
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .requestExtension(_, let days):
            return [URLQueryItem(name: "days", value: "\(days)")]
        default:
            return []
        }
    }

    var body: Data? {
        switch self {
        case .startShipping(_, let body):
            return try? JSONEncoder().encode(body)
        case .registerReceipt(_, let body):
            return try? JSONEncoder().encode(body)
        default:
            return nil
        }
    }

    var headers: [String: String] {
        switch self {
        case .startShipping, .registerReceipt:
            return ["Content-Type": "application/json"]
        default:
            return [:]
        }
    }
}
```

`TrackerShippingStartRequest`와 `TrackerReceiveRequest`는 Task 3에서 정의한다 — 따라서 이 task만 먼저 빌드하면 컴파일 실패. **Task 3과 묶어서 한 번만 빌드**.

- [ ] **Step 2: 컴파일은 Task 3 끝나고 검증 — 일단 저장만**

(빌드 명령 실행 안 함, 다음 task와 묶음)

- [ ] **Step 3: 커밋 보류** — Task 3 끝나고 함께 커밋

---

### Task 3: 트래커 상세/배송/수령 DTO 추가

**Files:**
- Modify: `Bookiibookii/Data/Models/TrackerModels.swift` (파일 끝에 append)

- [ ] **Step 1: 파일 끝(line 173 이후)에 다음 블록 추가**

```swift
// MARK: - 택배 교환 상세 DTO (안드로이드 TrackerDetailResponseDto 대응)

struct TrackerDetailResponse: Decodable {
    let bookTitle: String?
    let partnerNickname: String?
    let trackerStatus: TrackerStatusDTO
    let startDate: String?
    let endDate: String?
    let extensionCount: Int?
    let extensionDays: Int?
    let readingPeriod: Int?
    let trackerId: Int?
    let deliveryInfo: DeliveryInfoDTO?
    let meetingInfo: MeetingInfoDTO?
}

struct DeliveryInfoDTO: Decodable {
    let receiverName: String?
    let receiverPhone: String?
    let receiverAddress: String?
    let deliveryCompany: String?
    let trackingNumber: String?
    let isVerified: Bool?
}

struct MeetingInfoDTO: Decodable {
    let meetingTime: String?
    let meetingPlace: String?
}

enum TrackerStatusDTO: String, Decodable {
    case ready              = "READY"
    case hostReading        = "HOST_READING"
    case hostExtension      = "HOST_EXTENSION"
    case hostDone           = "HOST_DONE"
    case shippingToGuest    = "SHIPPING_TO_GUEST"
    case received           = "RECEIVED"
    case guestReading       = "GUEST_READING"
    case guestExtension     = "GUEST_EXTENSION"
    case guestDone          = "GUEST_DONE"
    case shippingToHost     = "SHIPPING_TO_HOST"
    case returned           = "RETURNED"
    case completed          = "COMPLETED"
    case unknown            = "UNKNOWN"

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = TrackerStatusDTO(rawValue: raw) ?? .unknown
    }
}

// MARK: - 배송/수령 요청·응답

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

- [ ] **Step 2: 빌드 확인 (Task 2와 함께)**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Common/DIContainer/API/Tracker/APITarget/TrackerAPITarget.swift \
        Bookiibookii/Data/Models/TrackerModels.swift
git commit -m "feat(tracker): 택배 교환 APITarget 케이스 + DTO 추가"
```

---

### Task 4: `S3UploadClient` 작성 (Core, 도메인 무관)

**Files:**
- Create: `Bookiibookii/Common/DIContainer/API/Core/S3UploadClient.swift`

- [ ] **Step 1: 신규 파일 작성**

`Bookiibookii/Common/DIContainer/API/Core/S3UploadClient.swift`:

```swift
import Foundation

/// presigned URL로 raw PUT 업로드 전용 (도메인 무관 공통 헬퍼).
/// AuthInterceptor 우회 — presigned URL은 자체 서명을 가지고 있어 Authorization 헤더 불필요.
struct S3UploadClient {
    func put(data: Data, to urlString: String, contentType: String) async throws {
        guard let url = URL(string: urlString) else {
            throw S3UploadError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.upload(for: request, from: data)

        guard let http = response as? HTTPURLResponse else {
            throw S3UploadError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw S3UploadError.unexpectedStatus(http.statusCode)
        }
    }
}

enum S3UploadError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unexpectedStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:                return "업로드 URL이 올바르지 않습니다."
        case .invalidResponse:           return "업로드 응답이 비정상입니다."
        case .unexpectedStatus(let c):   return "이미지 업로드 실패 (\(c))"
        }
    }
}
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Common/DIContainer/API/Core/S3UploadClient.swift
git commit -m "feat(core): S3 presigned PUT 업로드 공통 클라이언트 추가"
```

---

### Task 5: `TrackerService` 단순 액션 메서드 5종 추가

**Files:**
- Modify: `Bookiibookii/Common/DIContainer/API/Tracker/Service/TrackerService.swift`

- [ ] **Step 1: 파일에 헬퍼 + 5개 메서드 추가**

기존 `TrackerService` 클래스 안, `fetchGuestTrackers()` 메서드 아래(line 36 이후, 클래스 닫는 `}` 직전)에 다음을 삽입:

```swift
    // MARK: - 택배 교환 단순 액션

    /// GET /api/groups/{groupId}/tracker
    func fetchDetail(groupId: Int) async throws -> TrackerDetailResponse {
        try await requestDetail(target: .detail(groupId: groupId))
    }

    /// PATCH /api/groups/{groupId}/tracker/reading
    func startReading(groupId: Int) async throws -> TrackerDetailResponse {
        try await requestDetail(target: .startReading(groupId: groupId))
    }

    /// PATCH /api/groups/{groupId}/tracker/extension?days=
    func requestExtension(groupId: Int, days: Int = 3) async throws -> TrackerDetailResponse {
        try await requestDetail(target: .requestExtension(groupId: groupId, days: days))
    }

    /// PATCH /api/groups/{groupId}/tracker/done
    func markDone(groupId: Int) async throws -> TrackerDetailResponse {
        try await requestDetail(target: .markDone(groupId: groupId))
    }

    /// PATCH /api/groups/{groupId}/tracker/reception/verification
    func verifyReception(groupId: Int) async throws -> TrackerDetailResponse {
        try await requestDetail(target: .verifyReception(groupId: groupId))
    }

    // MARK: - 공통 디코딩 헬퍼

    private func requestDetail(target: TrackerAPITarget) async throws -> TrackerDetailResponse {
        let (data, http) = try await interceptor.request(target.asURLRequest())
        guard (200...299).contains(http.statusCode) else {
            throw TrackerServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<TrackerDetailResponse>.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw TrackerServiceError.server(response.message)
        }
        return result
    }
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Common/DIContainer/API/Tracker/Service/TrackerService.swift
git commit -m "feat(tracker): TrackerService 단순 액션 5종 추가 (detail/reading/extension/done/verify)"
```

---

### Task 6: `TrackerService` 이미지 URL 조회 + presignedUrl

**Files:**
- Modify: `Bookiibookii/Common/DIContainer/API/Tracker/Service/TrackerService.swift`

- [ ] **Step 1: 단순 액션 블록 아래에 이미지/presigned 메서드 추가**

`verifyReception(...)` 메서드 바로 아래(공통 헬퍼 `requestDetail` 위)에 추가:

```swift
    // MARK: - 이미지 URL 조회 / presigned

    /// GET /api/groups/{groupId}/tracker/images/delivery
    func fetchShippingImageURL(groupId: Int) async throws -> URL {
        try await requestImageURL(target: .shippingImage(groupId: groupId))
    }

    /// GET /api/groups/{groupId}/tracker/images/received
    func fetchReceivedImageURL(groupId: Int) async throws -> URL {
        try await requestImageURL(target: .receivedImage(groupId: groupId))
    }

    private func requestImageURL(target: TrackerAPITarget) async throws -> URL {
        let (data, http) = try await interceptor.request(target.asURLRequest())
        guard (200...299).contains(http.statusCode) else {
            throw TrackerServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<TrackerImageResponse>.self, from: data)
        guard response.isSuccess,
              let urlString = response.result?.imageUrl,
              let url = URL(string: urlString) else {
            throw TrackerServiceError.server(response.message)
        }
        return url
    }

    /// POST /api/groups/{groupId}/tracker/images/presigned-url
    private func fetchPresignedUrl(groupId: Int) async throws -> PresignedUrlResponse {
        let (data, http) = try await interceptor.request(
            TrackerAPITarget.presignedUrl(groupId: groupId).asURLRequest()
        )
        guard (200...299).contains(http.statusCode) else {
            throw TrackerServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<PresignedUrlResponse>.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw TrackerServiceError.server(response.message)
        }
        return result
    }
```

`fetchPresignedUrl`은 `private` — Task 7의 업로드 묶음이 내부에서만 호출.

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet
```
Expected: BUILD SUCCEEDED (단 `fetchPresignedUrl`이 미사용 경고 가능 — 다음 task에서 사용됨, 무시)

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Common/DIContainer/API/Tracker/Service/TrackerService.swift
git commit -m "feat(tracker): TrackerService 이미지 URL/presigned 조회 추가"
```

---

### Task 7: `TrackerService` 업로드 묶음 (`startShipping`, `registerReceipt`)

**Files:**
- Modify: `Bookiibookii/Common/DIContainer/API/Tracker/Service/TrackerService.swift`

- [ ] **Step 1: 파일 상단 import에 UIKit 추가**

```swift
import Foundation
import UIKit
```

- [ ] **Step 2: `S3UploadClient` 의존 주입**

`TrackerService` 클래스 정의 변경 — `interceptor` 옆에 `s3` 추가:

```swift
final class TrackerService {
    private let interceptor: AuthInterceptor
    private let s3: S3UploadClient

    init(interceptor: AuthInterceptor, s3: S3UploadClient = S3UploadClient()) {
        self.interceptor = interceptor
        self.s3 = s3
    }
```

- [ ] **Step 3: 업로드 묶음 메서드 추가**

`fetchPresignedUrl` 메서드 아래(`enum TrackerServiceError` 위)에 추가:

```swift
    // MARK: - 업로드 묶음 (presignedUrl → S3 PUT → 도메인 API)

    /// POST /api/groups/{groupId}/tracker/delivery (이미지 업로드 포함)
    func startShipping(
        groupId: Int,
        deliveryCompany: String,
        trackingNumber: String,
        image: UIImage
    ) async throws -> TrackerDetailResponse {
        let s3Key = try await uploadImage(groupId: groupId, image: image)
        let body = TrackerShippingStartRequest(
            deliveryCompany: deliveryCompany,
            trackingNumber: trackingNumber,
            s3Key: s3Key
        )
        return try await requestDetail(
            target: .startShipping(groupId: groupId, body: body)
        )
    }

    /// PATCH /api/groups/{groupId}/tracker/reception (이미지 업로드 포함)
    func registerReceipt(
        groupId: Int,
        image: UIImage
    ) async throws -> TrackerDetailResponse {
        let s3Key = try await uploadImage(groupId: groupId, image: image)
        let body = TrackerReceiveRequest(s3Key: s3Key)
        return try await requestDetail(
            target: .registerReceipt(groupId: groupId, body: body)
        )
    }

    private func uploadImage(groupId: Int, image: UIImage) async throws -> String {
        guard let jpeg = image.jpegData(compressionQuality: 0.85) else {
            throw TrackerServiceError.imageEncodingFailed
        }
        let presigned = try await fetchPresignedUrl(groupId: groupId)
        try await s3.put(data: jpeg, to: presigned.presignedPutUrl, contentType: "image/jpeg")
        return presigned.s3Key
    }
```

- [ ] **Step 4: `TrackerServiceError`에 `imageEncodingFailed` 추가**

기존 enum 끝에 case 추가:

```swift
enum TrackerServiceError: LocalizedError {
    case http(Int)
    case server(String)
    case imageEncodingFailed

    var errorDescription: String? {
        switch self {
        case .http(let code):       return "서버 오류 (\(code))"
        case .server(let msg):      return msg
        case .imageEncodingFailed:  return "이미지를 변환하지 못했습니다."
        }
    }
}
```

- [ ] **Step 5: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 6: 커밋**

```bash
git add Bookiibookii/Common/DIContainer/API/Tracker/Service/TrackerService.swift
git commit -m "feat(tracker): startShipping/registerReceipt 업로드 묶음 (presigned→S3→도메인 API)"
```

---

### Task 8: `DeliveryPhase` enum + 매퍼

**Files:**
- Create: `Bookiibookii/Features/Tracker/Domain/DeliveryPhase.swift`

- [ ] **Step 1: 신규 파일 작성**

```swift
import Foundation

/// 안드로이드 TradeConstants.Phase 대응.
enum DeliveryPhase: String, Equatable, Hashable {
    case initState
    case hostReading
    case hostShippingReady
    case hostShipped
    case guestReading
    case guestShippingReady
    case guestShipped
    case finished

    /// 서버 status → phase 매퍼 (안드로이드 TrackerDataMapper.statusToPhase 대응).
    static func from(_ status: TrackerStatusDTO) -> DeliveryPhase {
        switch status {
        case .ready:                        return .initState
        case .hostReading, .hostExtension:  return .hostReading
        case .hostDone:                     return .hostShippingReady
        case .shippingToGuest:              return .hostShipped
        case .received,
             .guestReading,
             .guestExtension:               return .guestReading
        case .guestDone:                    return .guestShippingReady
        case .shippingToHost:               return .guestShipped
        case .returned, .completed:         return .finished
        case .unknown:                      return .initState
        }
    }
}
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Features/Tracker/Domain/DeliveryPhase.swift
git commit -m "feat(tracker): DeliveryPhase enum + 서버 status 매퍼 추가"
```

---

### Task 9: `DeliverySheet` enum

**Files:**
- Create: `Bookiibookii/Features/Tracker/Domain/DeliverySheet.swift`

- [ ] **Step 1: 신규 파일 작성**

```swift
import Foundation

/// `sheet(item:)`에 사용할 단일 라우팅 enum (Host/Guest 공통).
enum DeliverySheet: String, Identifiable {
    case start
    case reading
    case readingStatus
    case readingDone
    case extendPeriod
    case extendRequest
    case shipping
    case shippingInput
    case shippingPhoto
    case shipped
    case shippingStatus
    case receiveConfirm
    case tradeFinish
    case groupManage
    case photoSelection
    case sendConfirm

    var id: String { rawValue }
}
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Features/Tracker/Domain/DeliverySheet.swift
git commit -m "feat(tracker): DeliverySheet 라우팅 enum 추가"
```

---

### Task 10: `HostDeliveryViewModel` 작성

**Files:**
- Create: `Bookiibookii/Features/Tracker/ViewModel/HostDeliveryViewModel.swift`

- [ ] **Step 1: 신규 파일 작성**

```swift
import Foundation
import UIKit

@MainActor
final class HostDeliveryViewModel: ObservableObject {
    @Published private(set) var detail: TrackerDetailResponse?
    @Published private(set) var phase: DeliveryPhase = .initState
    @Published var activeSheet: DeliverySheet?
    @Published private(set) var isLoading: Bool = false
    @Published var toastMessage: String?

    let groupId: Int
    private let service: TrackerService
    private var presentedPhases: Set<DeliveryPhase> = []

    init(groupId: Int, service: TrackerService) {
        self.groupId = groupId
        self.service = service
    }

    // MARK: - 진입 / 시트 조작

    func onAppear() async {
        await runAction(autoPresent: true) {
            try await self.service.fetchDetail(groupId: self.groupId)
        }
    }

    func tapStep(_ sheet: DeliverySheet) {
        activeSheet = sheet
    }

    func dismissSheet() {
        activeSheet = nil
    }

    // MARK: - 액션

    func startReading() async {
        await runAction { try await self.service.startReading(groupId: self.groupId) }
    }

    func requestExtension(days: Int) async {
        await runAction { try await self.service.requestExtension(groupId: self.groupId, days: days) }
    }

    func markDone() async {
        await runAction { try await self.service.markDone(groupId: self.groupId) }
    }

    func startShipping(company: String, trackingNumber: String, image: UIImage) async {
        await runAction {
            try await self.service.startShipping(
                groupId: self.groupId,
                deliveryCompany: company,
                trackingNumber: trackingNumber,
                image: image
            )
        }
    }

    func registerReceipt(image: UIImage) async {
        await runAction {
            try await self.service.registerReceipt(groupId: self.groupId, image: image)
        }
    }

    func verifyReception() async {
        await runAction { try await self.service.verifyReception(groupId: self.groupId) }
    }

    // MARK: - 첫 진입 / phase advance 시 자동 시트 표시

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

    // MARK: - 내부 헬퍼

    private func runAction(
        autoPresent: Bool = true,
        _ block: @escaping () async throws -> TrackerDetailResponse
    ) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await block()
            handle(response, autoPresent: autoPresent)
        } catch {
            toastMessage = (error as? LocalizedError)?.errorDescription
                ?? "네트워크 오류, 다시 시도해주세요"
        }
    }

    private func handle(_ response: TrackerDetailResponse, autoPresent: Bool) {
        detail = response
        let newPhase = DeliveryPhase.from(response.trackerStatus)
        let phaseChanged = newPhase != phase
        phase = newPhase
        if autoPresent && phaseChanged {
            autoPresentIfNeeded()
        } else if autoPresent && presentedPhases.isEmpty {
            // 첫 진입 (initState→initState로 변화 없음일 때도 한 번 표시)
            autoPresentIfNeeded()
        }
    }

    private func autoPresentIfNeeded() {
        guard !presentedPhases.contains(phase),
              let sheet = defaultSheet(for: phase) else { return }
        presentedPhases.insert(phase)
        activeSheet = sheet
    }
}
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Features/Tracker/ViewModel/HostDeliveryViewModel.swift
git commit -m "feat(tracker): HostDeliveryViewModel 작성 (phase + 액션 + 자동 시트)"
```

---

### Task 11: `HostDeliveryView` VM 주입 + `sheet(item:)` 라우팅

**Files:**
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Host/HostDeliveryView.swift`

- [ ] **Step 1: 파일 전체를 다음으로 교체** (기존 더미 파라미터 init 제거 + VM 기반 init)

```swift
import SwiftUI

// 안드 HostActivity 대응. ViewModel이 phase / 시트 / 액션을 관리.
struct HostDeliveryView: View {
    @StateObject private var vm: HostDeliveryViewModel
    private let onBack: () -> Void

    init(groupId: Int, service: TrackerService, onBack: @escaping () -> Void = {}) {
        _vm = StateObject(wrappedValue: HostDeliveryViewModel(groupId: groupId, service: service))
        self.onBack = onBack
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Rectangle()
                .fill(Color(red: 0xEE/255, green: 0xEE/255, blue: 0xEE/255))
                .frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    statusTitle.padding(.leading, 20).padding(.top, 24)
                    statusCard.padding(.horizontal, 20).padding(.top, 16)
                }
                .padding(.bottom, 50)
            }
        }
        .background(Color("grey100"))
        .task { await vm.onAppear() }
        .sheet(item: $vm.activeSheet, onDismiss: { /* 자동 dismiss 시 별도 처리 없음 */ }) { sheet in
            sheetView(for: sheet)
        }
        .overlay {
            if vm.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(ProgressView().tint(.white))
            }
        }
        .toast($vm.toastMessage)
    }

    // MARK: - 툴바

    private var toolbar: some View {
        ZStack {
            Text(vm.detail?.bookTitle ?? "")
                .font(.pretendard(size: 18, weight: .medium))
                .foregroundColor(Color("black"))
                .lineLimit(1)
                .padding(.horizontal, 60)

            HStack {
                Button(action: onBack) {
                    Image("ic_back")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color("black"))
                }
                .buttonStyle(.plain)
                .padding(.leading, 16)

                Spacer()

                Button { vm.tapStep(.groupManage) } label: {
                    Image("ic_more")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
            }
        }
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
    }

    // MARK: - 상태 카드

    private var statusTitle: some View {
        HStack(spacing: 0) {
            Text(vm.detail?.partnerNickname ?? "")
                .font(.pretendard(size: 18, weight: .medium))
                .foregroundColor(Color("main200"))
            Text(" 님과의 현황")
                .font(.pretendard(size: 18))
                .foregroundColor(Color("black"))
        }
    }

    private var statusCard: some View {
        VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { index in
                let row = rows[index]
                Button {
                    if let sheet = row.sheet { vm.tapStep(sheet) }
                } label: {
                    TradeStatusRow(item: row.step)
                }
                .buttonStyle(.plain)
                if index != rows.count - 1 {
                    Rectangle()
                        .fill(Color("grey100"))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    /// 현재 phase에 맞춰 7단계 row를 생성. 안드로이드 TrackerDataMapper.buildRows 대응(간소화 버전).
    private var rows: [DeliveryRow] {
        let p = vm.phase
        return [
            DeliveryRow(step: .init(title: "호스트 독서", description: "책을 읽고 있어요",
                                    badge: badge(for: p, threshold: .hostReading)),
                        sheet: .reading),
            DeliveryRow(step: .init(title: "게스트에게 발송", description: "운송장 등록 후 발송",
                                    badge: badge(for: p, threshold: .hostShipped)),
                        sheet: .shippingInput),
            DeliveryRow(step: .init(title: "게스트 수령", description: "게스트가 책을 수령",
                                    badge: badge(for: p, threshold: .guestReading)),
                        sheet: .readingStatus),
            DeliveryRow(step: .init(title: "게스트 독서", description: "게스트가 책을 읽는 중",
                                    badge: badge(for: p, threshold: .guestReading)),
                        sheet: .readingStatus),
            DeliveryRow(step: .init(title: "호스트에게 회수", description: "게스트가 발송",
                                    badge: badge(for: p, threshold: .guestShipped)),
                        sheet: .shippingStatus),
            DeliveryRow(step: .init(title: "호스트 수령", description: "수령 사진 등록",
                                    badge: badge(for: p, threshold: .guestShipped)),
                        sheet: .receiveConfirm),
            DeliveryRow(step: .init(title: "거래 종료", description: "리뷰 작성",
                                    badge: badge(for: p, threshold: .finished)),
                        sheet: .tradeFinish),
        ]
    }

    private func badge(for phase: DeliveryPhase, threshold: DeliveryPhase) -> String {
        let order: [DeliveryPhase] = [
            .initState, .hostReading, .hostShippingReady, .hostShipped,
            .guestReading, .guestShippingReady, .guestShipped, .finished
        ]
        let current = order.firstIndex(of: phase) ?? 0
        let target = order.firstIndex(of: threshold) ?? 0
        if current > target { return "완료" }
        if current == target { return "진행중" }
        return "대기"
    }

    // MARK: - 시트 라우팅 (Task 12~17에서 case별 시트 채움)

    @ViewBuilder
    private func sheetView(for sheet: DeliverySheet) -> some View {
        switch sheet {
        default:
            // 임시 placeholder — Task 12~17에서 각 시트로 교체
            Text("시트: \(sheet.rawValue)")
                .padding(40)
                .presentationDetents([.medium])
        }
    }
}

private struct DeliveryRow {
    let step: TradeStepRow
    let sheet: DeliverySheet?
}

#Preview("HostDelivery") {
    HostDeliveryView(
        groupId: 1,
        service: TrackerService(interceptor: AuthInterceptor(authService: AuthService()))
    )
}
```

기존 `TradeStepRow` / `TradeStatusRow` private struct는 동일 파일 안에 그대로 둔다 (위 코드 블록에서 `TradeStatusRow`는 변경 없으므로 삭제하지 않음 — 그대로 유지).

**주의**: 위 코드는 `TradeStatusRow` 정의를 포함하지 않음. 기존 파일 하단의 `private struct TradeStatusRow: View { ... }` 블록은 **삭제하지 말고 유지**. `TradeStepRow` struct도 삭제하지 말고 위 `DeliveryRow.step` 타입으로 그대로 사용.

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet
```
Expected: BUILD SUCCEEDED. `TrackerView.swift`에서 기존 `HostDeliveryView` 호출 사이트가 바뀌어 깨질 수 있음 — 이 시점엔 호출 사이트가 없으니 문제없음.

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Features/Tracker/View/Delivery/Host/HostDeliveryView.swift
git commit -m "feat(tracker): HostDeliveryView VM 주입 + sheet(item:) 라우팅 골격"
```

---

### Task 12: Host Start / Reading / ReadingStatus 시트 콜백 wiring

**Files:**
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Host/Sheets/HostStartSheet.swift`
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Host/Sheets/HostReadingSheet.swift`
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Host/Sheets/HostReadingStatusSheet.swift`
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Host/HostDeliveryView.swift`

- [ ] **Step 1: `HostStartSheet`에 onStart 콜백 추가**

기존 파일의 init / body에서 더미 buttons → `let onStart: () -> Void; let onCancel: () -> Void` 도입. 기존 파일 구조를 다음 패턴으로 정렬:

```swift
struct HostStartSheet: View {
    let onStart: () -> Void
    let onCancel: () -> Void

    var body: some View {
        SheetContainer {
            // 기존 텍스트/카드 유지
            VStack(spacing: 16) {
                // ... (기존 상단 안내 + ReadingPeriodCard 등 유지)
                PrimarySheetButton(title: "독서 시작", action: onStart)
                OutlineSheetButton(title: "닫기", action: onCancel)
            }
        }
    }
}
```

기존 시트 본문(텍스트, ReadingPeriodCard, InfoBannerCard 등) 그대로 유지. 변경 부분은 **상단 두 프로퍼티 추가 + 버튼 action 두 개를 콜백으로 연결**만.

- [ ] **Step 2: `HostReadingSheet`에 콜백 추가**

```swift
struct HostReadingSheet: View {
    let onRequestExtension: () -> Void   // → vm.tapStep(.extendPeriod)
    let onMarkDone: () -> Void           // → vm.markDone()
    let onClose: () -> Void

    var body: some View {
        SheetContainer {
            VStack(spacing: 12) {
                // 기존 본문 유지
                PrimarySheetButton(title: "독서 완료", action: onMarkDone)
                OutlineSheetButton(title: "기간 연장 요청", action: onRequestExtension)
                OutlineSheetButton(title: "닫기", action: onClose)
            }
        }
    }
}
```

- [ ] **Step 3: `HostReadingStatusSheet`에 콜백 추가**

```swift
struct HostReadingStatusSheet: View {
    let onClose: () -> Void

    var body: some View {
        SheetContainer {
            VStack(spacing: 12) {
                // 기존 게스트 독서 상태 표시 유지
                PrimarySheetButton(title: "닫기", action: onClose)
            }
        }
    }
}
```

- [ ] **Step 4: `HostDeliveryView.sheetView(for:)`에 case 3개 채움**

`HostDeliveryView.swift`의 `sheetView(for:)` switch를 다음으로 변경:

```swift
@ViewBuilder
private func sheetView(for sheet: DeliverySheet) -> some View {
    switch sheet {
    case .start:
        HostStartSheet(
            onStart: { Task { await vm.startReading(); vm.dismissSheet() } },
            onCancel: vm.dismissSheet
        )
        .presentationDetents([.medium])
    case .reading:
        HostReadingSheet(
            onRequestExtension: { vm.tapStep(.extendPeriod) },
            onMarkDone: { Task { await vm.markDone(); vm.dismissSheet() } },
            onClose: vm.dismissSheet
        )
        .presentationDetents([.medium])
    case .readingStatus:
        HostReadingStatusSheet(onClose: vm.dismissSheet)
            .presentationDetents([.medium])
    default:
        Text("시트: \(sheet.rawValue)")
            .padding(40)
            .presentationDetents([.medium])
    }
}
```

- [ ] **Step 5: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 6: 커밋**

```bash
git add Bookiibookii/Features/Tracker/View/Delivery/Host/
git commit -m "feat(tracker): Host Start/Reading/ReadingStatus 시트 VM 콜백 연결"
```

---

### Task 13: Host ExtendPeriod / ExtendRequest / ReadingDone 시트 wiring

**Files:**
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Host/Sheets/HostExtendPeriodSheet.swift`
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Host/Sheets/HostExtendRequestSheet.swift`
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Host/Sheets/HostReadingDoneSheet.swift`
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Host/HostDeliveryView.swift`

- [ ] **Step 1: `HostExtendPeriodSheet`에 onConfirm(days:) 추가**

```swift
struct HostExtendPeriodSheet: View {
    let onConfirm: (Int) -> Void
    let onCancel: () -> Void

    @State private var days: Int = 3

    var body: some View {
        SheetContainer {
            VStack(spacing: 16) {
                // 기존 상단 안내 텍스트 유지
                HStack(spacing: 8) {
                    ForEach([1, 3, 5, 7], id: \.self) { d in
                        Button {
                            days = d
                        } label: {
                            Text("\(d)일")
                                .font(.pretendard(size: 14, weight: .medium))
                                .foregroundColor(days == d ? Color("white") : Color("grey900"))
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(days == d ? Color("grey900") : Color("white"))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color("grey200")))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                PrimarySheetButton(title: "연장 요청", action: { onConfirm(days) })
                OutlineSheetButton(title: "닫기", action: onCancel)
            }
        }
    }
}
```

- [ ] **Step 2: `HostExtendRequestSheet`에 onClose 추가**

```swift
struct HostExtendRequestSheet: View {
    let onClose: () -> Void

    var body: some View {
        SheetContainer {
            VStack(spacing: 12) {
                // 기존 본문 (게스트 연장 요청 도착 알림) 유지
                PrimarySheetButton(title: "확인", action: onClose)
            }
        }
    }
}
```

- [ ] **Step 3: `HostReadingDoneSheet`에 onShipping(시트 전환) 추가**

게스트 독서 완료 → 호스트 수령 흐름의 안내 시트. 액션은 "수령 인증으로 이동"만.

```swift
struct HostReadingDoneSheet: View {
    let onProceedToReceive: () -> Void   // → vm.tapStep(.receiveConfirm)
    let onClose: () -> Void

    var body: some View {
        SheetContainer {
            VStack(spacing: 12) {
                // 기존 본문 유지
                PrimarySheetButton(title: "수령 인증하기", action: onProceedToReceive)
                OutlineSheetButton(title: "닫기", action: onClose)
            }
        }
    }
}
```

- [ ] **Step 4: `HostDeliveryView.sheetView(for:)`에 3개 case 추가**

기존 switch에 case 3개 삽입 (default 블록 위):

```swift
case .extendPeriod:
    HostExtendPeriodSheet(
        onConfirm: { days in Task { await vm.requestExtension(days: days); vm.dismissSheet() } },
        onCancel: vm.dismissSheet
    )
    .presentationDetents([.medium])
case .extendRequest:
    HostExtendRequestSheet(onClose: vm.dismissSheet)
        .presentationDetents([.medium])
case .readingDone:
    HostReadingDoneSheet(
        onProceedToReceive: { vm.tapStep(.receiveConfirm) },
        onClose: vm.dismissSheet
    )
    .presentationDetents([.medium])
```

- [ ] **Step 5: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 6: 커밋**

```bash
git add Bookiibookii/Features/Tracker/View/Delivery/Host/
git commit -m "feat(tracker): Host ExtendPeriod/ExtendRequest/ReadingDone 시트 wiring"
```

---

### Task 14: Host ShippingInput 시트 — 폼 + PhotosPicker + onSubmit

**Files:**
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Host/Sheets/HostShippingInputSheet.swift`
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Host/HostDeliveryView.swift`

- [ ] **Step 1: 시트 본문 교체 (PhotosUI import + 폼 + 제출)**

```swift
import SwiftUI
import PhotosUI

struct HostShippingInputSheet: View {
    let onSubmit: (_ company: String, _ trackingNumber: String, _ image: UIImage) -> Void
    let onCancel: () -> Void

    @State private var company: String = ""
    @State private var trackingNumber: String = ""
    @State private var pickedItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?

    private var canSubmit: Bool {
        !company.isEmpty && !trackingNumber.isEmpty && pickedImage != nil
    }

    var body: some View {
        SheetContainer {
            VStack(alignment: .leading, spacing: 16) {
                Text("배송 정보 입력")
                    .font(.pretendard(size: 18, weight: .medium))
                    .foregroundColor(Color("grey900"))

                inputField(title: "택배사", text: $company, placeholder: "예: CJ대한통운")
                inputField(title: "운송장 번호", text: $trackingNumber, placeholder: "운송장 번호 입력")

                photoPickerArea

                PrimarySheetButton(title: "제출", action: submit)
                    .opacity(canSubmit ? 1 : 0.5)
                    .disabled(!canSubmit)
                OutlineSheetButton(title: "닫기", action: onCancel)
            }
        }
        .onChange(of: pickedItem) { _, new in
            Task {
                guard let new,
                      let data = try? await new.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                pickedImage = image
            }
        }
    }

    private func submit() {
        guard let pickedImage else { return }
        onSubmit(company, trackingNumber, pickedImage)
    }

    @ViewBuilder
    private func inputField(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.pretendard(size: 13, weight: .medium))
                .foregroundColor(Color("grey700"))
            TextField(placeholder, text: text)
                .padding(12)
                .background(Color("grey100"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var photoPickerArea: some View {
        PhotosPicker(selection: $pickedItem, matching: .images) {
            HStack {
                if let pickedImage {
                    Image(uiImage: pickedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    HStack(spacing: 8) {
                        Image("ic_upload")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text("운송장 사진 업로드")
                            .font(.pretendard(size: 14))
                            .foregroundColor(Color("grey500"))
                    }
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .background(Color("grey100"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: `HostDeliveryView.sheetView(for:)`에 `.shippingInput` case 추가**

기존 switch에 default 블록 위로 삽입:

```swift
case .shippingInput:
    HostShippingInputSheet(
        onSubmit: { company, tracking, image in
            Task {
                await vm.startShipping(company: company, trackingNumber: tracking, image: image)
                vm.dismissSheet()
            }
        },
        onCancel: vm.dismissSheet
    )
    .presentationDetents([.large])
```

- [ ] **Step 3: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 4: 커밋**

```bash
git add Bookiibookii/Features/Tracker/View/Delivery/Host/
git commit -m "feat(tracker): Host ShippingInput 시트 폼 + PhotosPicker + 업로드 연동"
```

---

### Task 15: Host Shipped / ShippingStatus / ShippingPhoto 시트 (이미지 표시)

**Files:**
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Host/Sheets/HostShippedSheet.swift`
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Host/Sheets/HostShippingStatusSheet.swift`
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Host/Sheets/HostShippingPhotoSheet.swift`
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Host/HostDeliveryView.swift`

- [ ] **Step 1: `HostShippedSheet` — 운송장 정보 표시 + 사진 보기 진입**

```swift
struct HostShippedSheet: View {
    let deliveryCompany: String?
    let trackingNumber: String?
    let onShowPhoto: () -> Void   // → vm.tapStep(.shippingPhoto)
    let onClose: () -> Void

    var body: some View {
        SheetContainer {
            VStack(alignment: .leading, spacing: 12) {
                Text("게스트에게 발송 완료")
                    .font(.pretendard(size: 18, weight: .medium))
                infoLine("택배사", deliveryCompany ?? "-")
                infoLine("운송장 번호", trackingNumber ?? "-")
                PrimarySheetButton(title: "운송장 사진 보기", action: onShowPhoto)
                OutlineSheetButton(title: "닫기", action: onClose)
            }
        }
    }

    private func infoLine(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundColor(Color("grey500"))
            Spacer()
            Text(value).foregroundColor(Color("grey900"))
        }
        .font(.pretendard(size: 14))
    }
}
```

- [ ] **Step 2: `HostShippingStatusSheet` — 게스트 회수 진행 안내**

```swift
struct HostShippingStatusSheet: View {
    let deliveryCompany: String?
    let trackingNumber: String?
    let onShowPhoto: () -> Void
    let onClose: () -> Void

    var body: some View {
        SheetContainer {
            VStack(alignment: .leading, spacing: 12) {
                Text("게스트가 책을 발송했어요")
                    .font(.pretendard(size: 18, weight: .medium))
                Text("택배사: \(deliveryCompany ?? "-")")
                Text("운송장 번호: \(trackingNumber ?? "-")")
                PrimarySheetButton(title: "운송장 사진 보기", action: onShowPhoto)
                OutlineSheetButton(title: "닫기", action: onClose)
            }
            .font(.pretendard(size: 14))
            .foregroundColor(Color("grey900"))
        }
    }
}
```

- [ ] **Step 3: `HostShippingPhotoSheet` — `service.fetchShippingImageURL()` → AsyncImage**

```swift
struct HostShippingPhotoSheet: View {
    let groupId: Int
    let service: TrackerService
    let onClose: () -> Void

    @State private var imageURL: URL?
    @State private var loadError: String?

    var body: some View {
        SheetContainer {
            VStack(spacing: 16) {
                Text("운송장 사진")
                    .font(.pretendard(size: 18, weight: .medium))

                Group {
                    if let url = imageURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:    ProgressView().frame(height: 240)
                            case .success(let image): image.resizable().scaledToFit()
                            case .failure:  Text("사진을 불러오지 못했습니다.")
                            @unknown default: EmptyView()
                            }
                        }
                    } else if let loadError {
                        Text(loadError).foregroundColor(Color("grey500"))
                    } else {
                        ProgressView().frame(height: 240)
                    }
                }

                PrimarySheetButton(title: "닫기", action: onClose)
            }
        }
        .task {
            do { imageURL = try await service.fetchShippingImageURL(groupId: groupId) }
            catch { loadError = (error as? LocalizedError)?.errorDescription ?? "오류" }
        }
    }
}
```

- [ ] **Step 4: `HostDeliveryView.sheetView(for:)`에 case 3개 추가**

```swift
case .shipped:
    HostShippedSheet(
        deliveryCompany: vm.detail?.deliveryInfo?.deliveryCompany,
        trackingNumber: vm.detail?.deliveryInfo?.trackingNumber,
        onShowPhoto: { vm.tapStep(.shippingPhoto) },
        onClose: vm.dismissSheet
    )
    .presentationDetents([.medium])
case .shippingStatus:
    HostShippingStatusSheet(
        deliveryCompany: vm.detail?.deliveryInfo?.deliveryCompany,
        trackingNumber: vm.detail?.deliveryInfo?.trackingNumber,
        onShowPhoto: { vm.tapStep(.shippingPhoto) },
        onClose: vm.dismissSheet
    )
    .presentationDetents([.medium])
case .shippingPhoto:
    HostShippingPhotoSheet(
        groupId: vm.groupId,
        service: vm.service,   // 다음 step에서 expose
        onClose: vm.dismissSheet
    )
    .presentationDetents([.large])
```

- [ ] **Step 5: `HostDeliveryViewModel`에 `service` getter 노출**

`HostDeliveryViewModel.swift`의 `private let service` → `let service`로 변경 (VM이 자체 노출하는 read-only 의존성). 보안/캡슐화 측면에서 약간 느슨하지만, 이미지 시트는 VM 액션이 아니라 직접 GET이라 단순한 게 낫다.

```swift
let service: TrackerService
```

- [ ] **Step 6: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 7: 커밋**

```bash
git add Bookiibookii/Features/Tracker/View/Delivery/Host/ \
        Bookiibookii/Features/Tracker/ViewModel/HostDeliveryViewModel.swift
git commit -m "feat(tracker): Host Shipped/ShippingStatus/ShippingPhoto 시트 wiring"
```

---

### Task 16: Host ReceiveConfirm 시트 — 사진 picker + 수령 등록

**Files:**
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Host/Sheets/HostReceiveConfirmSheet.swift`
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Host/HostDeliveryView.swift`

- [ ] **Step 1: 시트 본문 교체**

```swift
import SwiftUI
import PhotosUI

struct HostReceiveConfirmSheet: View {
    let onSubmit: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var pickedItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?

    var body: some View {
        SheetContainer {
            VStack(spacing: 16) {
                Text("수령 인증")
                    .font(.pretendard(size: 18, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)

                PhotosPicker(selection: $pickedItem, matching: .images) {
                    Group {
                        if let pickedImage {
                            Image(uiImage: pickedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Text("수령한 책 사진 업로드")
                                .font(.pretendard(size: 14))
                                .foregroundColor(Color("grey500"))
                                .frame(maxWidth: .infinity, minHeight: 200)
                                .background(Color("grey100"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .buttonStyle(.plain)

                PrimarySheetButton(title: "수령 등록", action: { if let pickedImage { onSubmit(pickedImage) } })
                    .opacity(pickedImage == nil ? 0.5 : 1)
                    .disabled(pickedImage == nil)
                OutlineSheetButton(title: "닫기", action: onCancel)
            }
        }
        .onChange(of: pickedItem) { _, new in
            Task {
                guard let new,
                      let data = try? await new.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                pickedImage = image
            }
        }
    }
}
```

- [ ] **Step 2: `HostDeliveryView.sheetView(for:)`에 case 추가**

```swift
case .receiveConfirm:
    HostReceiveConfirmSheet(
        onSubmit: { image in
            Task { await vm.registerReceipt(image: image); vm.dismissSheet() }
        },
        onCancel: vm.dismissSheet
    )
    .presentationDetents([.large])
```

- [ ] **Step 3: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 4: 커밋**

```bash
git add Bookiibookii/Features/Tracker/View/Delivery/Host/
git commit -m "feat(tracker): Host ReceiveConfirm 시트 사진 등록 + 수령 API 연동"
```

---

### Task 17: Host TradeFinish / GroupManage / SendConfirm / PhotoSelection 시트 (placeholder)

**Files:**
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Host/Sheets/HostTradeFinishSheet.swift`
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Host/Sheets/HostGroupManageSheet.swift`
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Host/Sheets/HostSendConfirmView.swift`
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Host/Sheets/HostPhotoSelectionSheet.swift`
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Host/HostDeliveryView.swift`

- [ ] **Step 1: 4개 시트에 onClose 콜백 추가**

각 파일을 다음 패턴으로 정렬 (본문 텍스트는 기존 유지, 액션 콜백만 추가):

```swift
struct HostTradeFinishSheet: View {
    let onClose: () -> Void
    var body: some View {
        SheetContainer {
            VStack(spacing: 12) {
                Text("거래가 완료되었어요").font(.pretendard(size: 18, weight: .medium))
                Text("리뷰는 다음 사이클에서 연결됩니다.")
                    .font(.pretendard(size: 13)).foregroundColor(Color("grey500"))
                PrimarySheetButton(title: "닫기", action: onClose)
            }
        }
    }
}

struct HostGroupManageSheet: View {
    let onClose: () -> Void
    var body: some View {
        SheetContainer {
            VStack(spacing: 12) {
                Text("그룹 관리").font(.pretendard(size: 18, weight: .medium))
                PrimarySheetButton(title: "닫기", action: onClose)
            }
        }
    }
}

// HostSendConfirmView도 같은 패턴 — let onConfirm: () -> Void; let onCancel: () -> Void
struct HostSendConfirmView: View {
    let onConfirm: () -> Void
    let onCancel: () -> Void
    var body: some View {
        SheetContainer {
            VStack(spacing: 12) {
                Text("정말 보내시겠어요?").font(.pretendard(size: 18, weight: .medium))
                PrimarySheetButton(title: "확인", action: onConfirm)
                OutlineSheetButton(title: "취소", action: onCancel)
            }
        }
    }
}

struct HostPhotoSelectionSheet: View {
    let onClose: () -> Void
    var body: some View {
        SheetContainer {
            VStack(spacing: 12) {
                Text("사진 선택").font(.pretendard(size: 18, weight: .medium))
                PrimarySheetButton(title: "닫기", action: onClose)
            }
        }
    }
}
```

- [ ] **Step 2: `HostDeliveryView.sheetView(for:)`에 4개 case + default 정리**

기존 switch의 default 블록을 다음으로 교체:

```swift
case .tradeFinish:
    HostTradeFinishSheet(onClose: vm.dismissSheet)
        .presentationDetents([.medium])
case .groupManage:
    HostGroupManageSheet(onClose: vm.dismissSheet)
        .presentationDetents([.medium])
case .sendConfirm:
    HostSendConfirmView(onConfirm: vm.dismissSheet, onCancel: vm.dismissSheet)
        .presentationDetents([.medium])
case .photoSelection:
    HostPhotoSelectionSheet(onClose: vm.dismissSheet)
        .presentationDetents([.medium])
case .shipping:
    // 호스트는 shipping 안 씀 — 안전하게 닫기
    Color.clear.onAppear { vm.dismissSheet() }
}
```

(주의: switch가 모든 case를 커버하므로 default 블록 제거.)

- [ ] **Step 3: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 4: 커밋**

```bash
git add Bookiibookii/Features/Tracker/View/Delivery/Host/
git commit -m "feat(tracker): Host 잔여 시트(TradeFinish/GroupManage 등) 콜백 wiring + switch exhaustive"
```

---

### Task 18: `GuestDeliveryViewModel` 작성

**Files:**
- Create: `Bookiibookii/Features/Tracker/ViewModel/GuestDeliveryViewModel.swift`

- [ ] **Step 1: 신규 파일 작성** (Host와 구조 동일, `startReading` 없음 + `defaultSheet` 매핑 다름)

```swift
import Foundation
import UIKit

@MainActor
final class GuestDeliveryViewModel: ObservableObject {
    @Published private(set) var detail: TrackerDetailResponse?
    @Published private(set) var phase: DeliveryPhase = .initState
    @Published var activeSheet: DeliverySheet?
    @Published private(set) var isLoading: Bool = false
    @Published var toastMessage: String?

    let groupId: Int
    let service: TrackerService
    private var presentedPhases: Set<DeliveryPhase> = []

    init(groupId: Int, service: TrackerService) {
        self.groupId = groupId
        self.service = service
    }

    func onAppear() async {
        await runAction(autoPresent: true) {
            try await self.service.fetchDetail(groupId: self.groupId)
        }
    }

    func tapStep(_ sheet: DeliverySheet) { activeSheet = sheet }
    func dismissSheet() { activeSheet = nil }

    func requestExtension(days: Int) async {
        await runAction { try await self.service.requestExtension(groupId: self.groupId, days: days) }
    }

    func markDone() async {
        await runAction { try await self.service.markDone(groupId: self.groupId) }
    }

    func startShipping(company: String, trackingNumber: String, image: UIImage) async {
        await runAction {
            try await self.service.startShipping(
                groupId: self.groupId,
                deliveryCompany: company,
                trackingNumber: trackingNumber,
                image: image
            )
        }
    }

    func registerReceipt(image: UIImage) async {
        await runAction {
            try await self.service.registerReceipt(groupId: self.groupId, image: image)
        }
    }

    func defaultSheet(for phase: DeliveryPhase) -> DeliverySheet? {
        switch phase {
        case .initState, .hostReading:           return .readingStatus
        case .hostShippingReady, .hostShipped:   return .shippingStatus
        case .guestReading:                       return .reading
        case .guestShippingReady:                 return .shippingInput
        case .guestShipped:                       return .shipped
        case .finished:                           return .tradeFinish
        }
    }

    private func runAction(
        autoPresent: Bool = true,
        _ block: @escaping () async throws -> TrackerDetailResponse
    ) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await block()
            handle(response, autoPresent: autoPresent)
        } catch {
            toastMessage = (error as? LocalizedError)?.errorDescription
                ?? "네트워크 오류, 다시 시도해주세요"
        }
    }

    private func handle(_ response: TrackerDetailResponse, autoPresent: Bool) {
        detail = response
        let newPhase = DeliveryPhase.from(response.trackerStatus)
        let phaseChanged = newPhase != phase
        phase = newPhase
        if autoPresent && (phaseChanged || presentedPhases.isEmpty) {
            autoPresentIfNeeded()
        }
    }

    private func autoPresentIfNeeded() {
        guard !presentedPhases.contains(phase),
              let sheet = defaultSheet(for: phase) else { return }
        presentedPhases.insert(phase)
        activeSheet = sheet
    }
}
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Features/Tracker/ViewModel/GuestDeliveryViewModel.swift
git commit -m "feat(tracker): GuestDeliveryViewModel 작성 (phase + 액션 + 자동 시트)"
```

---

### Task 19: `GuestDeliveryView` VM 주입 + 시트 라우팅 골격

**Files:**
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Guest/GuestDeliveryView.swift`

- [ ] **Step 1: 파일 전체를 다음으로 교체**

`HostDeliveryView`와 동일 구조. 차이는 `partnerNickname` 색상이 `sub200`(파랑)이고 `vm`이 `GuestDeliveryViewModel`. 시트 case도 게스트 흐름에 맞춰 골격만:

```swift
import SwiftUI

struct GuestDeliveryView: View {
    @StateObject private var vm: GuestDeliveryViewModel
    private let onBack: () -> Void

    init(groupId: Int, service: TrackerService, onBack: @escaping () -> Void = {}) {
        _vm = StateObject(wrappedValue: GuestDeliveryViewModel(groupId: groupId, service: service))
        self.onBack = onBack
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Rectangle()
                .fill(Color(red: 0xEE/255, green: 0xEE/255, blue: 0xEE/255))
                .frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    statusTitle.padding(.leading, 20).padding(.top, 24)
                    statusCard.padding(.horizontal, 20).padding(.top, 16)
                }
                .padding(.bottom, 50)
            }
        }
        .background(Color("grey100"))
        .task { await vm.onAppear() }
        .sheet(item: $vm.activeSheet) { sheet in sheetView(for: sheet) }
        .overlay {
            if vm.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                    .overlay(ProgressView().tint(.white))
            }
        }
        .toast($vm.toastMessage)
    }

    private var toolbar: some View {
        ZStack {
            Text(vm.detail?.bookTitle ?? "")
                .font(.pretendard(size: 18, weight: .medium))
                .foregroundColor(Color("black"))
                .lineLimit(1)
                .padding(.horizontal, 60)
            HStack {
                Button(action: onBack) {
                    Image("ic_back").resizable().scaledToFit().frame(width: 24, height: 24)
                }.buttonStyle(.plain).padding(.leading, 16)
                Spacer()
                Button { vm.tapStep(.groupManage) } label: {
                    Image("ic_more").resizable().scaledToFit().frame(width: 24, height: 24)
                }.buttonStyle(.plain).padding(.trailing, 16)
            }
        }
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
    }

    private var statusTitle: some View {
        HStack(spacing: 0) {
            Text(vm.detail?.partnerNickname ?? "")
                .font(.pretendard(size: 18, weight: .medium))
                .foregroundColor(Color("sub200"))   // 게스트는 파랑
            Text(" 님과의 현황")
                .font(.pretendard(size: 18))
                .foregroundColor(Color("black"))
        }
    }

    private var statusCard: some View {
        VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { index in
                let row = rows[index]
                Button { if let s = row.sheet { vm.tapStep(s) } } label: {
                    TradeStatusRow(item: row.step)
                }.buttonStyle(.plain)
                if index != rows.count - 1 {
                    Rectangle().fill(Color("grey100")).frame(height: 1).padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var rows: [DeliveryRow] {
        let p = vm.phase
        return [
            DeliveryRow(step: .init(title: "호스트 독서", description: "호스트가 책을 읽는 중",
                                    badge: badge(for: p, threshold: .hostReading)),
                        sheet: .readingStatus),
            DeliveryRow(step: .init(title: "게스트에게 발송", description: "호스트가 책을 발송",
                                    badge: badge(for: p, threshold: .hostShipped)),
                        sheet: .shippingStatus),
            DeliveryRow(step: .init(title: "게스트 수령", description: "수령 사진 등록",
                                    badge: badge(for: p, threshold: .guestReading)),
                        sheet: .receiveConfirm),
            DeliveryRow(step: .init(title: "게스트 독서", description: "내가 책을 읽는 중",
                                    badge: badge(for: p, threshold: .guestReading)),
                        sheet: .reading),
            DeliveryRow(step: .init(title: "호스트에게 회수", description: "운송장 등록 후 발송",
                                    badge: badge(for: p, threshold: .guestShipped)),
                        sheet: .shippingInput),
            DeliveryRow(step: .init(title: "호스트 수령", description: "호스트가 수령",
                                    badge: badge(for: p, threshold: .finished)),
                        sheet: .shipped),
            DeliveryRow(step: .init(title: "거래 종료", description: "리뷰 작성",
                                    badge: badge(for: p, threshold: .finished)),
                        sheet: .tradeFinish),
        ]
    }

    private func badge(for phase: DeliveryPhase, threshold: DeliveryPhase) -> String {
        let order: [DeliveryPhase] = [
            .initState, .hostReading, .hostShippingReady, .hostShipped,
            .guestReading, .guestShippingReady, .guestShipped, .finished
        ]
        let current = order.firstIndex(of: phase) ?? 0
        let target = order.firstIndex(of: threshold) ?? 0
        if current > target { return "완료" }
        if current == target { return "진행중" }
        return "대기"
    }

    @ViewBuilder
    private func sheetView(for sheet: DeliverySheet) -> some View {
        // Task 20에서 case 채움
        Text("게스트 시트: \(sheet.rawValue)")
            .padding(40)
            .presentationDetents([.medium])
    }
}

private struct DeliveryRow {
    let step: TradeStepRow
    let sheet: DeliverySheet?
}

#Preview("GuestDelivery") {
    GuestDeliveryView(
        groupId: 1,
        service: TrackerService(interceptor: AuthInterceptor(authService: AuthService()))
    )
}
```

`TradeStepRow` / `TradeStatusRow`는 `HostDeliveryView.swift`에 정의되어 있어 재사용. 게스트 파일에는 별도 정의 없음.

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Features/Tracker/View/Delivery/Guest/
git commit -m "feat(tracker): GuestDeliveryView VM 주입 + 시트 라우팅 골격"
```

---

### Task 20: Guest 시트 콜백 wiring (호스트 미러)

**Files:**
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Guest/Sheets/*.swift`
- Modify: `Bookiibookii/Features/Tracker/View/Delivery/Guest/GuestDeliveryView.swift`

각 시트는 Host와 동일 패턴 (콜백 클로저 받기, body는 기존 텍스트 유지). 차이는 색상(`sub200`)과 일부 본문 문구.

- [ ] **Step 1: Guest 시트 13개 콜백 wiring**

다음 시트들을 Host의 동일 이름 시트와 1:1로 정렬:

| 파일 | 콜백 시그니처 |
|---|---|
| `GuestStartSheet.swift` | `let onStart: () -> Void; let onCancel: () -> Void` |
| `GuestReadingSheet.swift` | `let onRequestExtension: () -> Void; let onMarkDone: () -> Void; let onClose: () -> Void` |
| `GuestReadingStatusSheet.swift` | `let onClose: () -> Void` |
| `GuestReadingDoneSheet.swift` | `let onClose: () -> Void` |
| `GuestExtendPeriodSheet.swift` | `let onConfirm: (Int) -> Void; let onCancel: () -> Void` |
| `GuestExtendRequestSheet.swift` | `let onClose: () -> Void` |
| `GuestShippingInputSheet.swift` | `let onSubmit: (String, String, UIImage) -> Void; let onCancel: () -> Void` |
| `GuestShippingPhotoSheet.swift` | `let groupId: Int; let service: TrackerService; let onClose: () -> Void; @State var imageURL: URL?` (Host 패턴 그대로) |
| `GuestShippingSheet.swift` | `let onClose: () -> Void` (안내 시트) |
| `GuestShippedSheet.swift` | `let deliveryCompany: String?; let trackingNumber: String?; let onShowPhoto: () -> Void; let onClose: () -> Void` |
| `GuestShippingStatusSheet.swift` | 위와 동일 |
| `GuestReceiveConfirmSheet.swift` | `let onSubmit: (UIImage) -> Void; let onCancel: () -> Void` |
| `GuestTradeFinishSheet.swift` | `let onClose: () -> Void` |
| `GuestGroupManageSheet.swift` | `let onClose: () -> Void` |
| `GuestSendConfirmView.swift` | `let onConfirm: () -> Void; let onCancel: () -> Void` |

각 시트는 Task 12~17의 Host 동등 시트와 **본문 코드를 동일 패턴**으로 만든다 (단, `pretendard` 색상 강조가 필요한 곳은 `sub200`으로). Host에서 작성한 `HostShippingInputSheet` / `HostReceiveConfirmSheet` / `HostShippingPhotoSheet`의 PhotosPicker / AsyncImage 본문을 그대로 복사하여 `Guest...Sheet`로 이름만 바꾸어 적용.

`GuestReadingSheet`는 Host와 달리 게스트 모드의 액션:
```swift
struct GuestReadingSheet: View {
    let onRequestExtension: () -> Void
    let onMarkDone: () -> Void
    let onClose: () -> Void

    var body: some View {
        SheetContainer {
            VStack(spacing: 12) {
                Text("내가 책을 읽는 중").font(.pretendard(size: 18, weight: .medium))
                PrimarySheetButton(title: "독서 완료 (호스트에게 회수 요청)", action: onMarkDone)
                OutlineSheetButton(title: "기간 연장 요청", action: onRequestExtension)
                OutlineSheetButton(title: "닫기", action: onClose)
            }
        }
    }
}
```

- [ ] **Step 2: `GuestDeliveryView.sheetView(for:)` 전체 case 채움**

기존 placeholder switch를 다음으로 교체:

```swift
@ViewBuilder
private func sheetView(for sheet: DeliverySheet) -> some View {
    switch sheet {
    case .start:
        GuestStartSheet(onStart: vm.dismissSheet, onCancel: vm.dismissSheet)
            .presentationDetents([.medium])
    case .reading:
        GuestReadingSheet(
            onRequestExtension: { vm.tapStep(.extendPeriod) },
            onMarkDone: { Task { await vm.markDone(); vm.dismissSheet() } },
            onClose: vm.dismissSheet
        ).presentationDetents([.medium])
    case .readingStatus:
        GuestReadingStatusSheet(onClose: vm.dismissSheet).presentationDetents([.medium])
    case .readingDone:
        GuestReadingDoneSheet(onClose: vm.dismissSheet).presentationDetents([.medium])
    case .extendPeriod:
        GuestExtendPeriodSheet(
            onConfirm: { d in Task { await vm.requestExtension(days: d); vm.dismissSheet() } },
            onCancel: vm.dismissSheet
        ).presentationDetents([.medium])
    case .extendRequest:
        GuestExtendRequestSheet(onClose: vm.dismissSheet).presentationDetents([.medium])
    case .shipping:
        GuestShippingSheet(onClose: vm.dismissSheet).presentationDetents([.medium])
    case .shippingInput:
        GuestShippingInputSheet(
            onSubmit: { c, t, img in
                Task { await vm.startShipping(company: c, trackingNumber: t, image: img); vm.dismissSheet() }
            },
            onCancel: vm.dismissSheet
        ).presentationDetents([.large])
    case .shippingPhoto:
        GuestShippingPhotoSheet(groupId: vm.groupId, service: vm.service, onClose: vm.dismissSheet)
            .presentationDetents([.large])
    case .shipped:
        GuestShippedSheet(
            deliveryCompany: vm.detail?.deliveryInfo?.deliveryCompany,
            trackingNumber: vm.detail?.deliveryInfo?.trackingNumber,
            onShowPhoto: { vm.tapStep(.shippingPhoto) },
            onClose: vm.dismissSheet
        ).presentationDetents([.medium])
    case .shippingStatus:
        GuestShippingStatusSheet(
            deliveryCompany: vm.detail?.deliveryInfo?.deliveryCompany,
            trackingNumber: vm.detail?.deliveryInfo?.trackingNumber,
            onShowPhoto: { vm.tapStep(.shippingPhoto) },
            onClose: vm.dismissSheet
        ).presentationDetents([.medium])
    case .receiveConfirm:
        GuestReceiveConfirmSheet(
            onSubmit: { img in Task { await vm.registerReceipt(image: img); vm.dismissSheet() } },
            onCancel: vm.dismissSheet
        ).presentationDetents([.large])
    case .tradeFinish:
        GuestTradeFinishSheet(onClose: vm.dismissSheet).presentationDetents([.medium])
    case .groupManage:
        GuestGroupManageSheet(onClose: vm.dismissSheet).presentationDetents([.medium])
    case .photoSelection:
        Color.clear.onAppear { vm.dismissSheet() }
    case .sendConfirm:
        GuestSendConfirmView(onConfirm: vm.dismissSheet, onCancel: vm.dismissSheet)
            .presentationDetents([.medium])
    }
}
```

- [ ] **Step 3: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 4: 커밋**

```bash
git add Bookiibookii/Features/Tracker/View/Delivery/Guest/
git commit -m "feat(tracker): Guest 시트 13종 콜백 wiring + 라우팅 case 채움"
```

---

### Task 21: `TrackerView`에서 Delivery 상세로 NavigationStack push

**Files:**
- Modify: `Bookiibookii/Features/Tracker/View/TrackerView.swift`
- Modify: `Bookiibookii/Data/Models/TrackerModels.swift` (TrackerItem `Hashable` 채택 확인)

- [ ] **Step 1: `TrackerItem`에 `Hashable` 채택**

`Bookiibookii/Data/Models/TrackerModels.swift`의 `TrackerItem` 정의 변경:

```swift
struct TrackerItem: Identifiable, Equatable, Hashable {
    // 기존 필드 동일
}
```

기존 `Equatable` 자동 합성에 `Hashable` 더해도 모든 필드가 `Hashable`(`Int`, `String?`, `[String?]`, `ExchangeRole`, `ExchangeType`)이므로 자동 합성 가능. `ExchangeRole`/`ExchangeType`이 `Hashable` 채택 안 되어 있을 수 있으므로 동일 파일에서 확인:

```swift
enum ExchangeRole: Hashable { ... }
enum ExchangeType: Hashable { ... }
```

(둘 다 단순 case enum이므로 자동 채택 — 명시만 추가.)

- [ ] **Step 2: `TrackerView`에 `NavigationStack` + `path` + `navigationDestination` 추가**

기존 `var body: some View { ZStack { ... } }`를 `NavigationStack` 으로 감싸고, 카드 onTap을 `path.append`로 변경.

```swift
struct TrackerView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: TrackerViewModel
    @State private var path = NavigationPath()
    private let onNavigateToGroup: () -> Void

    init(
        trackerService: TrackerService,
        onNavigateToGroup: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: TrackerViewModel(service: trackerService))
        self.onNavigateToGroup = onNavigateToGroup
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color("grey100").ignoresSafeArea()
                VStack(spacing: 0) {
                    header
                    tabSegment
                    content
                }
            }
            .task { await viewModel.onAppear() }
            .toast($viewModel.toast)
            .navigationDestination(for: TrackerItem.self) { item in
                deliveryDestination(for: item)
            }
        }
    }

    @ViewBuilder
    private func deliveryDestination(for item: TrackerItem) -> some View {
        switch (item.role, item.exchangeType) {
        case (.host, .delivery):
            HostDeliveryView(groupId: item.groupId,
                             service: container.api.tracker,
                             onBack: { path.removeLast() })
                .toolbar(.hidden, for: .navigationBar)
        case (.guest, .delivery):
            GuestDeliveryView(groupId: item.groupId,
                              service: container.api.tracker,
                              onBack: { path.removeLast() })
                .toolbar(.hidden, for: .navigationBar)
        default:
            Text("이번 사이클에서 미지원")  // 직거래 / 함께읽기
                .foregroundColor(Color("grey500"))
        }
    }
```

- [ ] **Step 3: `list(items:)`에서 `onTap` → `path.append(item)`**

기존 line 136 부근:

```swift
TrackerCard(item: item, onTap: { path.append(item) })
```

- [ ] **Step 4: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 15' build -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 5: 커밋**

```bash
git add Bookiibookii/Features/Tracker/View/TrackerView.swift \
        Bookiibookii/Data/Models/TrackerModels.swift
git commit -m "feat(tracker): 카드 탭 시 Host/Guest Delivery로 NavigationStack push"
```

---

### Task 22: 시뮬레이터 수동 검증 시나리오 실행

**Files:** (변경 없음 — 검증만)

**참조:** spec §9.2 (Host H1~H8), §9.3 (Guest G1~G7)

- [ ] **Step 1: 디버그 빌드 + 시뮬레이터 부팅**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -configuration Debug build -quiet

xcrun simctl boot "iPhone 15" 2>/dev/null || true
open -a Simulator
```

- [ ] **Step 2: 앱 실행 후 Host 시나리오 H1~H8 수동 진행**

각 phase에서 다음을 확인 (spec §9.2 표):
- 자동 표시되는 시트가 매핑과 일치하는지
- 액션 후 phase 가 advance되고 새 시트가 자동으로 뜨는지
- 사용자 dismiss 후 같은 phase에서 재표시되지 않는지
- 명시적으로 step 카드 탭하면 해당 시트가 다시 열리는지

발견 이슈는 `docs/superpowers/specs/2026-05-02-tracker-delivery-design.md` §11 "위험 / 확정 안 된 점"에 보강 항목으로 적는다 (커밋은 별도 task로 분리).

- [ ] **Step 3: Guest 시나리오 G1~G7 수동 진행**

동일 방식, spec §9.3 표 기준.

- [ ] **Step 4: 에러 케이스 검증**

- 비행기 모드 → 액션 트리거 → 토스트 노출 확인 (예: "네트워크 오류, 다시 시도해주세요")
- ShippingInput 시트에서 사진 미선택 → 제출 버튼 disabled 확인
- ShippingInput 시트에서 택배사/운송장 빈 값 → 제출 버튼 disabled 확인

- [ ] **Step 5: 검증 로그 작성 (선택)**

발견된 결함 / 서버 응답 구조 불일치 등이 있으면 `docs/superpowers/specs/...-design.md` §11에 보강. 결함이 없으면 다음 step.

- [ ] **Step 6: 빈 커밋 — 검증 완료 표시**

(코드 변경 없으면 생략 가능. 변경 있으면 해당 task로 별도 커밋.)

```bash
git status
# (변경 없으면 종료, 있으면 별도 task로 다룸)
```

---

## Self-Review

### 1. Spec 커버리지

| Spec section | Implementing Task |
|---|---|
| §3 디렉터리 / 파일 배치 | 전체 task로 분산 (생성/수정 명시) |
| §4.1 path 상수 10개 | Task 1 |
| §4.2 APITarget case 10개 | Task 2 |
| §4.3 S3UploadClient | Task 4 |
| §4.4 Service 메서드 | Task 5, 6, 7 |
| §4.5 DTO | Task 3 |
| §5.1 DeliveryPhase | Task 8 |
| §5.2 DeliverySheet + defaultSheet | Task 9, 10, 18 |
| §6 ViewModel | Task 10 (Host), Task 18 (Guest) |
| §7.1 진입점 | Task 21 |
| §7.2 Delivery 화면 + sheet(item:) | Task 11 (Host), Task 19 (Guest) |
| §7.3 시트 인터페이스 | Task 12~17 (Host), Task 20 (Guest) |
| §8 에러/로딩/토스트 | Task 11, 19에 overlay + toast 포함 |
| §9 검증 시나리오 | Task 22 |

빠진 항목 없음.

### 2. Placeholder 스캔

- "TBD" / "TODO" — 없음 (Task 22의 "선택" 표시는 결과 의존이라 OK)
- "Similar to Task N" — Task 20 표가 시그니처를 정확히 명시 + 본문은 Host 동등 코드 그대로 복사 지시 (placeholder 아님, 명확한 instruction)
- "fill in details" / "appropriate error handling" — 없음

### 3. Type / Method 일관성

- `HostDeliveryViewModel.service`: Task 10에서 `private let`, Task 15에서 `let`로 변경 — 명시적으로 Task 15 Step 5에 변경 지시 포함 (의도적)
- `defaultSheet(for:)`: Host와 Guest 둘 다 같은 시그니처
- `runAction` / `handle` / `autoPresentIfNeeded`: Host/Guest 모두 동일 패턴
- `DeliverySheet.shipping` 케이스: Host(Task 17)와 Guest(Task 20)가 둘 다 처리 — 일관됨
- `TrackerService.service` 노출: `interceptor`는 `private`, 신규 `s3`도 `private` — Task 7 작성 시점에 의도된 캡슐화

이슈 없음. 플랜 진행 가능.

---

## Execution Handoff

이 플랜은 약 22개 task로, 각 task는 2~10분 단위로 atomic 커밋. iOS 시뮬레이터 빌드는 task당 30~60초 소요 — 빌드를 매번 안 돌리려면 의존 task 묶음 단위로 검증해도 됨.
