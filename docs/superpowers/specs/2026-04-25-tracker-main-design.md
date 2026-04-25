# 트래커 탭 메인 화면 — 설계

- Date: 2026-04-25
- Branch: `feat/#30/tracker-main`
- Scope: **B (골격 + 심플 카드)**. 릴레이 진행바/함께읽기 독서율 바 등 카드 템플릿 디테일은 후속 PR로 분리.

## 1. 목표와 범위

### 포함
- 트래커 탭 진입 화면(`TrackerView`) 재구현
- "내 그룹 / 참여한 그룹" 2-탭 세그먼트 (안드로이드 `TrkMainFragment` 대응)
- 탭별 진행 중 그룹 리스트 (심플 카드: 썸네일 + 제목/저자 + with)
- 빈 상태 카드 (피그마 node `3544-74773`와 동일 형태)
- Host/Guest 엔드포인트 각각 연결 + `TrackerItem` 도메인 모델 통합
- 풀 투 리프레시, 기본 로딩/에러 상태

### 제외 (후속 PR)
- 릴레이(DELIVERY/DIRECT) 4단계 진행바, 단계별 프로필·날짜
- 함께읽기(NONE) 나의/그룹 평균 독서율 비교 바, 격려 메시지
- 카드 탭 네비게이션, 트래커 상세/호스트/게스트 화면
- 릴레이 상태(READY/SHIPPING/…) 배지
- 홈 화면의 "진행 중 트래커" 미니 섹션

## 2. 참고 레퍼런스
- 안드로이드: `app/src/main/java/.../trkHost/TrkMainFragment.kt`, `TrkMainViewModel.kt`, `TrackerDataMapper.kt`
- 안드로이드 API: `TrkApi.kt` — `GET /api/groups/me/trackers/host`, `GET /api/groups/me/trackers/guest`
- 피그마:
  - 리스트 상태: node `3544-74839` (TRK-001-2)
  - 빈 상태: node `3544-74773` (TRK-001-3)

UI 충돌 시 안드로이드 XML 우선(프로젝트 컨벤션).

## 3. 파일 구조

### 신규
```
Bookiibookii/
├─ Common/DIContainer/API/
│  └─ Tracker/
│     ├─ APITarget/TrackerAPITarget.swift
│     └─ Service/TrackerService.swift
├─ Data/Models/TrackerModels.swift
└─ Features/Tracker/
   ├─ View/
   │  ├─ TrackerView.swift        (기존 stub 교체)
   │  ├─ TrackerCard.swift
   │  └─ TrackerEmptyCard.swift
   ├─ ViewModel/TrackerViewModel.swift
   └─ Domain/TrackerTab.swift
```

### 수정
- `Common/DIContainer/API/Common/Domain.swift` — `static let trackers = "/api/groups/me/trackers"` 추가
- `Common/DIContainer/API/Common/UseCaseProvider.swift` — `tracker: TrackerService` 프로퍼티 + 생성
- `Common/DIContainer/API/APIContainer.swift` — `tracker` 노출
- `Common/Tabbar/BookiiTabCase.swift` — `.tracker` case가 `TrackerView(trackerService: container.api.tracker, onNavigateToGroup: { selectTab(.group) })` 주입하도록 변경

## 4. 데이터 레이어

### 4.1 엔드포인트

| 메서드 | 경로 | 응답 |
|---|---|---|
| GET | `/api/groups/me/trackers/host` | `ApiResponseDTO<[HostTrackerListItemDto]>` |
| GET | `/api/groups/me/trackers/guest` | `ApiResponseDTO<[GuestTrackerListItemDto]>` |

### 4.2 DTO (`Data/Models/TrackerModels.swift`)

안드로이드 DTO 구조를 그대로 따르되, 이번 PR에서는 심플 카드에 필요한 필드만 실사용. 중첩 구조(`relayDetail`/`togetherDetail`)는 다음 PR에서 진행바/독서율 렌더에 사용할 수 있도록 정의해둠.

```swift
struct HostTrackerListItemDto: Decodable {
    let groupId: Int
    let groupType: String
    let bookTitle: String
    let bookImage: String?
    let bookAuthor: String?
    let bookCategory: String?
    let tradeType: String?
    let relayDetail: TrackerRelayDetailDto?
    let togetherDetail: TrackerTogetherDetailDto?
}

struct GuestTrackerListItemDto: Decodable { /* 동일 필드 */ }

struct TrackerRelayDetailDto: Decodable {
    let partnerNickname: String?
    let hostProfileImageUrl: String?
    let guestProfileImageUrls: [String]?
    let trackerStatus: String?
    let stepDates: [String?]?
}

struct TrackerTogetherDetailDto: Decodable {
    let hostNickname: String?
    let participantCount: Int?
    let myReadingRate: Int?
    let groupReadingRate: Int?
}
```

Host와 Guest의 relay/together 서브 구조는 안드로이드에서 이름만 중복 정의돼 있어서 실제로 동일 → iOS에서는 `TrackerRelayDetailDto`/`TrackerTogetherDetailDto` 단일 정의로 공유.

### 4.3 도메인 모델 & enum

```swift
enum ExchangeRole { case host, guest }

enum ExchangeType {
    case delivery   // 택배
    case direct     // 직거래
    case none       // 함께읽기
}

struct TrackerItem: Identifiable, Equatable {
    let id: Int            // = groupId
    let groupId: Int
    let role: ExchangeRole
    let exchangeType: ExchangeType
    let bookTitle: String
    let bookAuthor: String
    let bookCategory: String?
    let coverImageUrl: String?
    let withUserName: String?   // 심플 카드용 통합 표시명
}

enum TrackerTab { case myGroup, joined }
```

### 4.4 매퍼
- `HostTrackerListItemDto.toTrackerItem()` — `role = .host`
- `GuestTrackerListItemDto.toTrackerItem()` — `role = .guest`
- `exchangeType`: `tradeType`("DELIVERY"/"SHIPPING" → .delivery, "DIRECT" → .direct, else → .none)
- `withUserName`:
  - 릴레이: `relayDetail?.partnerNickname`
  - 함께읽기: `togetherDetail?.hostNickname` (+ participantCount > 0 이면 ` +N`)

### 4.5 Service

```swift
final class TrackerService {
    func fetchHostTrackers() async throws -> [TrackerItem]
    func fetchGuestTrackers() async throws -> [TrackerItem]
}
```

기존 `GroupService`와 동일한 패턴(`AuthInterceptor`, `ApiResponseDTO` 디코딩, 에러 enum). `TrackerServiceError`는 `http(Int)`, `server(String)`, `decoding(Error)`, `transport(Error)` 4종.

## 5. ViewModel — `TrackerViewModel`

```swift
@MainActor
final class TrackerViewModel: ObservableObject {
    enum Phase { case idle, loading, refreshing, failed(String), loaded }

    @Published private(set) var hostItems: [TrackerItem] = []
    @Published private(set) var guestItems: [TrackerItem] = []
    @Published private(set) var hostPhase: Phase = .idle
    @Published private(set) var guestPhase: Phase = .idle
    @Published var selectedTab: TrackerTab = .myGroup
    @Published var toast: ToastState? = nil

    var currentItems: [TrackerItem] { /* 선택 탭 기준 */ }
    var currentPhase: Phase        { /* 선택 탭 기준 */ }

    func onAppear() async
    func selectTab(_ tab: TrackerTab) async
    func refresh() async
}
```

### 5.1 로드 정책
- **onAppear()**: 선택된 탭만 로드 (최초 진입 시 `.myGroup`). 이미 `.loaded`면 skip
- **selectTab(.joined)**: `guestPhase == .idle` 또는 `.failed`이면 guest 로드. `.loaded`면 재호출 없음 (안드로이드 동일)
- **refresh()**: 현재 탭 phase를 `.refreshing`으로 세팅 후 강제 재호출. 성공 시 리스트 교체, 실패 시 기존 리스트 유지 + `toast` 노출

### 5.2 에러 처리
- 리스트 비어있을 때 실패 → 빈 상태 대신 "불러오기 실패 / 다시 시도" 재시도 뷰 (그룹 탭 `emptyOrLoadingState` 패턴 재사용)
- 리스트 있을 때 실패(리프레시 실패) → 기존 리스트 유지 + `toast`에 "불러오기에 실패했어요"

## 6. 뷰 레이아웃

### 6.1 `TrackerView` 구성
```
ZStack(alignment: .bottomTrailing)
  Color("grey100").ignoresSafeArea()
  VStack(spacing: 0)
    header          // 흰색 bg, border-b grey200
    tabSegment      // grey100 bg
    content         // switch(phase, items)
```

### 6.2 header
- 흰색 bg, 높이 77, padding top 20 / bottom 17 / horizontal 24
- 하단 1px grey200 경계선 (overlay alignment: .bottom)
- `Text("북 트래커")` Pretendard Medium 24 / grey800

### 6.3 tabSegment
- bg `grey100`, 패딩 `horizontal 24`, `vertical 16`
- `HStack(spacing: 12)` 내 버튼 2개, `flex 1`, height 48, radius 16
- 선택: bg `grey900`, text white
- 미선택: bg white, 1px grey200 border, text grey900
- 공통: Pretendard Medium 14

### 6.4 content 분기
- `.loading` & 빈 리스트 → 중앙 `ProgressView`
- `.failed` & 빈 리스트 → 중앙 "불러오기 실패" + "다시 시도" 텍스트 버튼 (재시도는 `refresh()` 호출)
- `.loaded` & 빈 리스트 → `TrackerEmptyCard` (탭에 따라 문구 스왑)
- 그 외 → `ScrollView` + `LazyVStack(spacing: 16)` + `TrackerCard` × N
- ScrollView에 `.refreshable { await vm.refresh() }`, horizontal padding 24
- 리프레시 중에도 기존 리스트 유지 (시스템 스피너만 동작)

### 6.5 `TrackerCard`
```
RoundedRectangle radius 20, bg white, padding 16, width = maxWidth
HStack(spacing: 12, alignment: .top)
  BookThumbnail  // 60×85, radius 10, grey200 1px border, AsyncImage + grey300 placeholder
  VStack(spacing: 4, alignment: .leading)
    Text(title)    Pretendard Medium 16 / grey800, 1 line, ellipsis
    Text("\(author) (\(category))") Pretendard Regular 12 / grey600
    Spacer().frame(height: 8)
    HStack(spacing: 4)
      Text("with")  Pretendard Medium 12 / grey500
      Text(name)    Pretendard Medium 12 / grey800
```
- `onTap` 클로저는 받되 현재 PR에서 `TrackerView`가 빈 클로저 주입 (no-op)
- 카테고리 원시값 → 한글 매핑 유틸은 안드로이드 `mapCategoryToKo`와 동일. `TrackerItem` 매퍼 시점에서 변환해서 저장하지 않고, 카드 표기 시점에서 변환 (`Features/Tracker/Domain/` 내 `TrackerCategory.displayKo(rawValue:)` 함수)

### 6.6 `TrackerEmptyCard`
- bg white, radius 24, padding 24, gap 20
- 상: `VStack(spacing: 8)` 중앙 정렬
  - title: Pretendard Medium 16 / grey900
  - desc: Pretendard Regular 14 / grey600
- 하: grey900 bg 버튼, height 56, radius 20, full width, Pretendard Regular 15 / grey100, text "그룹 둘러보기"
- 버튼 탭 → `onNavigateToGroup()` 호출 (TrackerView 인자로 주입받음)
- 탭별 문구:
  - `.myGroup` → "아직 그룹을 만들지 않았어요 😭" / "읽고 싶은 책을 골라 그룹을 만들어볼까요?"
  - `.joined` → "아직 참여한 그룹이 없어요 😭" / "독서 그룹에 참여하러 가볼까요?"

## 7. 통합

### 7.1 `TrackerView` init
```swift
init(
    trackerService: TrackerService,
    onNavigateToGroup: @escaping () -> Void
)
```

### 7.2 `BookiiTabCase.contentView`
```swift
case .tracker:
    TrackerView(
        trackerService: container.api.tracker,
        onNavigateToGroup: { selectTab(.group) }
    )
```

### 7.3 DI 주입 플로우
- `UseCaseProvider.init` 안에서 `TrackerService(interceptor: interceptor)` 생성
- `APIContainer`가 `tracker` 프로퍼티로 노출
- `MainTabView` → `BookiiTabCase.contentView` → `TrackerView`

## 8. 실행 순서

1. `Domain.swift`에 `static let trackers` 추가
2. `TrackerAPITarget.swift` 작성 (`.hostList`, `.guestList`)
3. `TrackerModels.swift` 작성 (DTO × 2 + 서브 DTO × 2 + `TrackerItem` + enums + 매퍼)
4. `TrackerService.swift` 작성 (`fetchHostTrackers()`, `fetchGuestTrackers()`, 에러 enum)
5. `UseCaseProvider.swift` / `APIContainer.swift`에 `tracker` 연결
6. `Features/Tracker/Domain/TrackerTab.swift` 작성 (+ 카테고리 한글 매퍼)
7. `TrackerViewModel.swift` 작성
8. `TrackerCard.swift` + `TrackerEmptyCard.swift` 작성
9. `TrackerView.swift` 교체 (stub 삭제, VM + UI 바인딩)
10. `BookiiTabCase.swift`에서 `.tracker` case 업데이트
11. `xcodebuild` 빌드 확인 (iphonesimulator)

## 9. 검증 체크리스트

- [ ] 빌드 성공 (`xcodebuild ... -destination 'generic/platform=iOS Simulator'`)
- [ ] `.myGroup` 기본 선택, 진입 시 host API 1회 호출
- [ ] `.joined` 탭 → guest API 1회 호출 (재클릭 시 재호출 없음)
- [ ] 서버 빈 배열 → `TrackerEmptyCard` 노출, 탭별 문구 스왑 확인
- [ ] 빈 상태 "그룹 둘러보기" 탭 → 그룹 탭으로 전환
- [ ] 리스트 존재 시 아래로 당겨 새로고침 → 현재 탭 재호출
- [ ] 네트워크 실패 & 빈 리스트 → "불러오기 실패 / 다시 시도" 뷰
- [ ] 네트워크 실패 & 리스트 있음 → 기존 리스트 유지 + 토스트 노출
- [ ] 심플 카드 3종 데이터(릴레이 host, 릴레이 guest, 함께읽기) 모두 썸네일/제목/저자/with 정상 표시

## 10. 후속 작업 메모 (별도 PR)

- 카드 템플릿 분기: `TrackerItem.exchangeType`으로 `TrackerRelayCard` / `TrackerTogetherCard` 선택 렌더
- 릴레이 진행바 컴포넌트: 4단계 dots + 현재 단계 #37AAFF highlight + 단계별 프로필/날짜
- 함께읽기 오버랩 바: 나의 독서율(메인 주황) + 그룹 평균(grey) + 격려 메시지
- 카드 탭 → 트래커 상세 진입. 상세 화면은 추가 큰 단위(#31?) 피처로 분리
