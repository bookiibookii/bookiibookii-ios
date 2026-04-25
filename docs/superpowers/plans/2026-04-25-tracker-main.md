# 트래커 탭 메인 화면 (skeleton + 심플 카드) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 트래커 탭에 "내 그룹 / 참여한 그룹" 2-탭 세그먼트 + 진행 중 그룹 리스트(심플 카드) + 피그마 빈 상태 카드를 구현하고, Host/Guest 엔드포인트를 연결한다.

**Architecture:** Feature 레이어는 `Features/Tracker/{View,ViewModel,Domain}`, API 레이어는 `Common/DIContainer/API/Tracker/{APITarget,Service}`. DTO는 `Data/Models/TrackerModels.swift` 단일 파일에서 정의. 단일 `TrackerViewModel`이 host/guest 리스트·phase를 함께 보유하고 탭 전환은 "캐시 비었을 때만 재호출" 정책. 안드로이드 `TrkMainFragment`/`TrkMainViewModel`의 1:1 대응.

**Tech Stack:** SwiftUI, Combine(`@Published`), async/await, `AuthInterceptor` 기반 네트워킹, `ApiResponseDTO<T>` 공통 응답, Kingfisher(`KFImage`). 기존 `GroupService`/`NotificationService` 패턴 그대로 따름.

**Spec:** `docs/superpowers/specs/2026-04-25-tracker-main-design.md`

**Branch:** `feat/#30/tracker-main`

**Verification loop (iOS 프로젝트 컨벤션 — CLAUDE.md 반영):**
- 각 task 끝마다 `xcodebuild ... -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5` 로 `** BUILD SUCCEEDED **` 확인
- SourceKit 진단("Cannot find type in scope" 등)은 false positive — 실제 빌드 결과만 신뢰
- UI 자동 테스트 없음. 마지막 task 이후 시뮬레이터에서 수동 검증 (스펙 §9 체크리스트)

---

## File Structure

**Create**
- `Bookiibookii/Common/DIContainer/API/Tracker/APITarget/TrackerAPITarget.swift`
- `Bookiibookii/Common/DIContainer/API/Tracker/Service/TrackerService.swift`
- `Bookiibookii/Data/Models/TrackerModels.swift`
- `Bookiibookii/Features/Tracker/Domain/TrackerTab.swift`
- `Bookiibookii/Features/Tracker/ViewModel/TrackerViewModel.swift`
- `Bookiibookii/Features/Tracker/View/TrackerCard.swift`
- `Bookiibookii/Features/Tracker/View/TrackerEmptyCard.swift`

**Modify**
- `Bookiibookii/Common/DIContainer/API/Common/Domain.swift` — path 상수 추가
- `Bookiibookii/Common/DIContainer/API/Common/UseCaseProvider.swift` — `tracker` 프로퍼티 + 생성
- `Bookiibookii/Common/DIContainer/API/APIContainer.swift` — `tracker` 노출
- `Bookiibookii/Features/Tracker/View/TrackerView.swift` — 기존 stub 완전 교체
- `Bookiibookii/Common/Tabbar/BookiiTabCase.swift` — `.tracker` case 주입 인자 변경

---

### Task 1: API path 상수 추가

**Files:**
- Modify: `Bookiibookii/Common/DIContainer/API/Common/Domain.swift`

- [ ] **Step 1: path 상수 추가**

`Bookiibookii/Common/DIContainer/API/Common/Domain.swift`:

```swift
import Foundation

/// Vinny 스타일처럼 서버 주소/도메인별 path를 한곳에서 관리합니다.
enum API {
    static let baseURL = "https://bookii.gyeonseo.com"

    enum Path {
        static let auth = "/api/auth"
        static let users = "/api/users"
        static let onboarding = "/api/onboarding"
        static let mypage = "/api/mypage"
        static let groups = "/api/groups"
        static let books = "/api/books"
        static let recommendations = "/api/recommendations"
        static let notifications = "/api/notifications"
        static let keywords = "/api/keywords"
        static let trackers = "/api/groups/me/trackers"
    }
}
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Common/DIContainer/API/Common/Domain.swift
git commit -m "chore: 트래커 엔드포인트 path 상수 추가

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 2: TrackerAPITarget

**Files:**
- Create: `Bookiibookii/Common/DIContainer/API/Tracker/APITarget/TrackerAPITarget.swift`

- [ ] **Step 1: APITarget enum 작성**

`Bookiibookii/Common/DIContainer/API/Tracker/APITarget/TrackerAPITarget.swift`:

```swift
import Foundation

// 안드로이드 TrkApi.getHostTrackers / getGuestTrackers 대응.
enum TrackerAPITarget: APITargetType {
    case hostList   // GET /api/groups/me/trackers/host
    case guestList  // GET /api/groups/me/trackers/guest

    var path: String {
        switch self {
        case .hostList:  return API.Path.trackers + "/host"
        case .guestList: return API.Path.trackers + "/guest"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .hostList, .guestList: return .get
        }
    }
}
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Common/DIContainer/API/Tracker/APITarget/TrackerAPITarget.swift
git commit -m "feat: 트래커 APITarget 추가 (hostList / guestList)

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 3: TrackerModels (DTO + 도메인 모델 + 매퍼)

**Files:**
- Create: `Bookiibookii/Data/Models/TrackerModels.swift`

- [ ] **Step 1: 파일 작성**

`Bookiibookii/Data/Models/TrackerModels.swift`:

```swift
import Foundation

// MARK: - 서버 DTO (안드로이드 HostTrackerListItemDto / GuestTrackerListItemDto 대응)

struct HostTrackerListItemDto: Decodable {
    let groupId: Int
    let groupType: String?
    let bookTitle: String
    let bookImage: String?
    let bookAuthor: String?
    let bookCategory: String?
    let tradeType: String?
    let relayDetail: TrackerRelayDetailDto?
    let togetherDetail: TrackerTogetherDetailDto?
}

struct GuestTrackerListItemDto: Decodable {
    let groupId: Int
    let groupType: String?
    let bookTitle: String
    let bookImage: String?
    let bookAuthor: String?
    let bookCategory: String?
    let tradeType: String?
    let relayDetail: TrackerRelayDetailDto?
    let togetherDetail: TrackerTogetherDetailDto?
}

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

// MARK: - 도메인 모델

enum ExchangeRole {
    case host
    case guest
}

enum ExchangeType {
    case delivery   // 택배
    case direct     // 직거래
    case none       // 함께읽기

    static func from(raw: String?) -> ExchangeType {
        switch raw?.uppercased() {
        case "DELIVERY", "SHIPPING": return .delivery
        case "DIRECT":               return .direct
        default:                     return .none
        }
    }
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
    let withUserName: String?
}

// MARK: - 매퍼

extension HostTrackerListItemDto {
    func toTrackerItem() -> TrackerItem {
        let type = ExchangeType.from(raw: tradeType)
        let withName = TrackerModelsMapper.withUserName(
            exchangeType: type,
            relay: relayDetail,
            together: togetherDetail
        )
        return TrackerItem(
            id: groupId,
            groupId: groupId,
            role: .host,
            exchangeType: type,
            bookTitle: bookTitle,
            bookAuthor: bookAuthor ?? "",
            bookCategory: bookCategory,
            coverImageUrl: bookImage,
            withUserName: withName
        )
    }
}

extension GuestTrackerListItemDto {
    func toTrackerItem() -> TrackerItem {
        let type = ExchangeType.from(raw: tradeType)
        let withName = TrackerModelsMapper.withUserName(
            exchangeType: type,
            relay: relayDetail,
            together: togetherDetail
        )
        return TrackerItem(
            id: groupId,
            groupId: groupId,
            role: .guest,
            exchangeType: type,
            bookTitle: bookTitle,
            bookAuthor: bookAuthor ?? "",
            bookCategory: bookCategory,
            coverImageUrl: bookImage,
            withUserName: withName
        )
    }
}

enum TrackerModelsMapper {
    static func withUserName(
        exchangeType: ExchangeType,
        relay: TrackerRelayDetailDto?,
        together: TrackerTogetherDetailDto?
    ) -> String? {
        switch exchangeType {
        case .delivery, .direct:
            return relay?.partnerNickname
        case .none:
            guard let name = together?.hostNickname, !name.isEmpty else { return nil }
            if let count = together?.participantCount, count > 0 {
                return "\(name) +\(count)"
            }
            return name
        }
    }
}
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Data/Models/TrackerModels.swift
git commit -m "feat: 트래커 DTO + TrackerItem 도메인 모델 + 매퍼 추가

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 4: TrackerService

**Files:**
- Create: `Bookiibookii/Common/DIContainer/API/Tracker/Service/TrackerService.swift`

- [ ] **Step 1: 서비스 작성**

`Bookiibookii/Common/DIContainer/API/Tracker/Service/TrackerService.swift`:

```swift
import Foundation

// 안드로이드 TrkMainViewModel.loadHostTrackers / loadGuestTrackers 대응.
// ApiResponseDTO<[Dto]> 디코딩 후 도메인 모델(TrackerItem)로 매핑해서 반환.
final class TrackerService {
    private let interceptor: AuthInterceptor

    init(interceptor: AuthInterceptor) { self.interceptor = interceptor }

    /// GET /api/groups/me/trackers/host
    func fetchHostTrackers() async throws -> [TrackerItem] {
        let request = TrackerAPITarget.hostList.asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw TrackerServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<[HostTrackerListItemDto]>.self, from: data)
        guard response.isSuccess else {
            throw TrackerServiceError.server(response.message)
        }
        return (response.result ?? []).map { $0.toTrackerItem() }
    }

    /// GET /api/groups/me/trackers/guest
    func fetchGuestTrackers() async throws -> [TrackerItem] {
        let request = TrackerAPITarget.guestList.asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw TrackerServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<[GuestTrackerListItemDto]>.self, from: data)
        guard response.isSuccess else {
            throw TrackerServiceError.server(response.message)
        }
        return (response.result ?? []).map { $0.toTrackerItem() }
    }
}

enum TrackerServiceError: LocalizedError {
    case http(Int)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .http(let code): return "서버 오류 (\(code))"
        case .server(let msg): return msg
        }
    }
}
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Common/DIContainer/API/Tracker/Service/TrackerService.swift
git commit -m "feat: TrackerService + 호스트/게스트 리스트 조회 함수

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 5: DI 연결 (UseCaseProvider + APIContainer)

**Files:**
- Modify: `Bookiibookii/Common/DIContainer/API/Common/UseCaseProvider.swift`
- Modify: `Bookiibookii/Common/DIContainer/API/APIContainer.swift`

- [ ] **Step 1: UseCaseProvider 수정**

`Bookiibookii/Common/DIContainer/API/Common/UseCaseProvider.swift`:

```swift
import Foundation

protocol UseCaseProtocol {
    var auth: AuthService { get }
    var user: UserService { get }
    var group: GroupService { get }
    var recommendation: RecommendationService { get }
    var notification: NotificationService { get }
    var keyword: KeywordService { get }
    var tracker: TrackerService { get }
}

/// 도메인별 API UseCase 진입점을 한곳에서 제공합니다.
final class UseCaseProvider: UseCaseProtocol {
    let auth: AuthService
    let user: UserService
    let group: GroupService
    let recommendation: RecommendationService
    let notification: NotificationService
    let keyword: KeywordService
    let tracker: TrackerService

    init(auth: AuthService = AuthService()) {
        self.auth = auth
        let interceptor = AuthInterceptor(authService: auth)
        self.user = UserService(interceptor: interceptor)
        self.group = GroupService(interceptor: interceptor)
        self.recommendation = RecommendationService(interceptor: interceptor)
        self.notification = NotificationService(interceptor: interceptor)
        self.keyword = KeywordService(interceptor: interceptor)
        self.tracker = TrackerService(interceptor: interceptor)
    }
}
```

- [ ] **Step 2: APIContainer 수정**

`Bookiibookii/Common/DIContainer/API/APIContainer.swift`:

```swift
import Foundation

final class APIContainer: Sendable {
    let useCaseProvider: UseCaseProvider

    init(auth: AuthService = AuthService()) {
        self.useCaseProvider = UseCaseProvider(auth: auth)
    }

    // 하위 호환: 기존 호출부(api.auth / api.user / api.group) 유지
    var auth: AuthService { useCaseProvider.auth }
    var user: UserService { useCaseProvider.user }
    var group: GroupService { useCaseProvider.group }
    var recommendation: RecommendationService { useCaseProvider.recommendation }
    var notification: NotificationService { useCaseProvider.notification }
    var keyword: KeywordService { useCaseProvider.keyword }
    var tracker: TrackerService { useCaseProvider.tracker }
}
```

- [ ] **Step 3: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: 커밋**

```bash
git add Bookiibookii/Common/DIContainer/API/Common/UseCaseProvider.swift Bookiibookii/Common/DIContainer/API/APIContainer.swift
git commit -m "feat: DIContainer에 TrackerService 주입

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 6: TrackerTab + 카테고리 한글 매퍼

**Files:**
- Create: `Bookiibookii/Features/Tracker/Domain/TrackerTab.swift`

- [ ] **Step 1: 파일 작성**

`Bookiibookii/Features/Tracker/Domain/TrackerTab.swift`:

```swift
import Foundation

// 안드로이드 TrkMainViewModel.TrackerTab 대응.
enum TrackerTab: Int, CaseIterable, Identifiable {
    case myGroup     // 내 그룹 (host)
    case joined      // 참여한 그룹 (guest)

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .myGroup: return "내 그룹"
        case .joined:  return "참여한 그룹"
        }
    }

    /// 리스트 비어있을 때 표시할 빈 카드 상단 문구
    var emptyTitle: String {
        switch self {
        case .myGroup: return "아직 그룹을 만들지 않았어요 😭"
        case .joined:  return "아직 참여한 그룹이 없어요 😭"
        }
    }

    /// 리스트 비어있을 때 표시할 빈 카드 설명 문구
    var emptyDescription: String {
        switch self {
        case .myGroup: return "읽고 싶은 책을 골라 그룹을 만들어볼까요?"
        case .joined:  return "독서 그룹에 참여하러 가볼까요?"
        }
    }
}

/// 안드로이드 TrackerAdapter.mapCategoryToKo 대응.
enum TrackerCategoryMapper {
    static func displayKo(_ raw: String?) -> String {
        guard let key = raw?.trimmingCharacters(in: .whitespaces), !key.isEmpty else { return "" }
        switch key {
        case "ECON_BIZ":      return "경제/경영"
        case "SCI_IT":        return "과학/IT"
        case "NOVEL_GENRE":   return "소설"
        case "POEM_ESSAY":    return "시/에세이"
        case "HOME_HOBBY":    return "가정/취미"
        case "ART_CULTURE":   return "예술/문화"
        case "HUMAN_HISTORY": return "인문/역사"
        case "SELF_DEV":      return "자기계발"
        case "POL_SOC":       return "정치/사회"
        case "ETC":           return "기타"
        default:              return key
        }
    }
}
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Features/Tracker/Domain/TrackerTab.swift
git commit -m "feat: TrackerTab + 카테고리 한글 매퍼 추가

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 7: TrackerViewModel

**Files:**
- Create: `Bookiibookii/Features/Tracker/ViewModel/TrackerViewModel.swift`

- [ ] **Step 1: ViewModel 작성**

`Bookiibookii/Features/Tracker/ViewModel/TrackerViewModel.swift`:

```swift
import Foundation
import Combine

// 안드로이드 TrkMainViewModel 대응.
// host/guest 리스트와 탭별 phase를 단일 VM에서 보유.
@MainActor
final class TrackerViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case loading
        case refreshing
        case failed(String)
        case loaded
    }

    @Published private(set) var hostItems: [TrackerItem] = []
    @Published private(set) var guestItems: [TrackerItem] = []
    @Published private(set) var hostPhase: Phase = .idle
    @Published private(set) var guestPhase: Phase = .idle
    @Published var selectedTab: TrackerTab = .myGroup
    @Published var toast: String? = nil

    private let service: TrackerService

    init(service: TrackerService) {
        self.service = service
    }

    // MARK: - 파생값

    var currentItems: [TrackerItem] {
        switch selectedTab {
        case .myGroup: return hostItems
        case .joined:  return guestItems
        }
    }

    var currentPhase: Phase {
        switch selectedTab {
        case .myGroup: return hostPhase
        case .joined:  return guestPhase
        }
    }

    // MARK: - 진입 / 탭 전환

    func onAppear() async {
        // 최초 진입 시 선택 탭만 로드. 이미 .loaded면 skip.
        await loadIfNeeded(tab: selectedTab)
    }

    func selectTab(_ tab: TrackerTab) async {
        guard tab != selectedTab else { return }
        selectedTab = tab
        await loadIfNeeded(tab: tab)
    }

    func refresh() async {
        await reload(tab: selectedTab, isRefresh: true)
    }

    // MARK: - Private

    private func loadIfNeeded(tab: TrackerTab) async {
        let phase: Phase
        switch tab {
        case .myGroup: phase = hostPhase
        case .joined:  phase = guestPhase
        }
        if case .loaded = phase { return }
        await reload(tab: tab, isRefresh: false)
    }

    private func reload(tab: TrackerTab, isRefresh: Bool) async {
        // 리프레시면 기존 리스트 유지 + phase만 변경, 초기 로드면 loading
        setPhase(tab: tab, phase: isRefresh ? .refreshing : .loading)
        do {
            let items: [TrackerItem]
            switch tab {
            case .myGroup: items = try await service.fetchHostTrackers()
            case .joined:  items = try await service.fetchGuestTrackers()
            }
            switch tab {
            case .myGroup: hostItems = items
            case .joined:  guestItems = items
            }
            setPhase(tab: tab, phase: .loaded)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? "불러오기에 실패했어요"
            setPhase(tab: tab, phase: .failed(message))
            // 기존 리스트가 있었다면 토스트로 알림 (리스트 자체는 유지)
            let hadItems: Bool = {
                switch tab {
                case .myGroup: return !hostItems.isEmpty
                case .joined:  return !guestItems.isEmpty
                }
            }()
            if hadItems {
                toast = message
            }
        }
    }

    private func setPhase(tab: TrackerTab, phase: Phase) {
        switch tab {
        case .myGroup: hostPhase = phase
        case .joined:  guestPhase = phase
        }
    }
}
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Features/Tracker/ViewModel/TrackerViewModel.swift
git commit -m "feat: TrackerViewModel 추가 (host/guest 리스트 + 탭별 phase + refresh)

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 8: TrackerCard (심플 카드)

**Files:**
- Create: `Bookiibookii/Features/Tracker/View/TrackerCard.swift`

- [ ] **Step 1: 카드 작성**

`Bookiibookii/Features/Tracker/View/TrackerCard.swift`:

```swift
import SwiftUI
import Kingfisher

// 심플 버전 — 이번 PR 범위.
// 릴레이 진행바 / 함께읽기 독서율 바는 후속 PR에서 exchangeType 분기로 추가.
struct TrackerCard: View {
    let item: TrackerItem
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            cover
            info
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private var cover: some View {
        KFImage(item.coverImageUrl.flatMap(URL.init(string:)))
            .placeholder { Color("grey300") }
            .retry(maxCount: 2)
            .cancelOnDisappear(true)
            .resizable()
            .scaledToFill()
            .frame(width: 60, height: 85)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color("grey200"), lineWidth: 1)
            )
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.bookTitle)
                .font(.pretendard(size: 16, weight: .medium))
                .foregroundColor(Color("grey800"))
                .lineLimit(1)
                .truncationMode(.tail)

            Text(authorLine)
                .font(.pretendard(size: 12))
                .foregroundColor(Color("grey600"))
                .lineLimit(1)

            Spacer().frame(height: 8)

            if let name = item.withUserName, !name.isEmpty {
                HStack(spacing: 4) {
                    Text("with")
                        .font(.pretendard(size: 12, weight: .medium))
                        .foregroundColor(Color("grey500"))
                    Text(name)
                        .font(.pretendard(size: 12, weight: .medium))
                        .foregroundColor(Color("grey800"))
                        .lineLimit(1)
                }
            }
        }
    }

    private var authorLine: String {
        let category = TrackerCategoryMapper.displayKo(item.bookCategory)
        if category.isEmpty { return item.bookAuthor }
        return "\(item.bookAuthor) (\(category))"
    }
}

#Preview("릴레이 Host") {
    TrackerCard(
        item: TrackerItem(
            id: 1, groupId: 1,
            role: .host, exchangeType: .delivery,
            bookTitle: "참을 수 없는 존재의 가벼움",
            bookAuthor: "밀란 쿤데라", bookCategory: "NOVEL_GENRE",
            coverImageUrl: nil, withUserName: "noshel"
        ),
        onTap: {}
    )
    .padding()
    .background(Color("grey100"))
}

#Preview("함께읽기 participant+N") {
    TrackerCard(
        item: TrackerItem(
            id: 2, groupId: 2,
            role: .host, exchangeType: .none,
            bookTitle: "살인자의 기억법",
            bookAuthor: "김영하", bookCategory: "NOVEL_GENRE",
            coverImageUrl: nil, withUserName: "noshel +29"
        ),
        onTap: {}
    )
    .padding()
    .background(Color("grey100"))
}
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Features/Tracker/View/TrackerCard.swift
git commit -m "feat: TrackerCard 심플 카드 (썸네일 + 제목/저자 + with)

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 9: TrackerEmptyCard (피그마 빈 상태)

**Files:**
- Create: `Bookiibookii/Features/Tracker/View/TrackerEmptyCard.swift`

- [ ] **Step 1: 빈 상태 카드 작성**

`Bookiibookii/Features/Tracker/View/TrackerEmptyCard.swift`:

```swift
import SwiftUI

// 피그마 node 3544-74773 대응.
// 탭에 따라 문구만 스왑됨. 버튼 탭 시 그룹 탭으로 이동.
struct TrackerEmptyCard: View {
    let tab: TrackerTab
    let onNavigateToGroup: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(tab.emptyTitle)
                    .font(.pretendard(size: 16, weight: .medium))
                    .foregroundColor(Color("grey900"))
                    .multilineTextAlignment(.center)

                Text(tab.emptyDescription)
                    .font(.pretendard(size: 14))
                    .foregroundColor(Color("grey600"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            Button(action: onNavigateToGroup) {
                Text("그룹 둘러보기")
                    .font(.pretendard(size: 15))
                    .foregroundColor(Color("grey100"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color("grey900"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

#Preview("내 그룹") {
    TrackerEmptyCard(tab: .myGroup, onNavigateToGroup: {})
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("grey100"))
}

#Preview("참여한 그룹") {
    TrackerEmptyCard(tab: .joined, onNavigateToGroup: {})
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("grey100"))
}
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Features/Tracker/View/TrackerEmptyCard.swift
git commit -m "feat: TrackerEmptyCard 빈 상태 카드 (피그마 3544-74773)

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 10: TrackerView 교체 + BookiiTabCase 주입 업데이트

**Files:**
- Modify: `Bookiibookii/Features/Tracker/View/TrackerView.swift` (기존 stub 완전 교체)
- Modify: `Bookiibookii/Common/Tabbar/BookiiTabCase.swift`

**주의:** `TrackerView`의 init 시그니처가 바뀌므로 같은 커밋에서 `BookiiTabCase`도 함께 수정해야 컴파일된다.

- [ ] **Step 1: TrackerView 교체**

`Bookiibookii/Features/Tracker/View/TrackerView.swift`:

```swift
import SwiftUI

// 안드로이드 TrkMainFragment 대응.
struct TrackerView: View {
    @StateObject private var viewModel: TrackerViewModel
    private let onNavigateToGroup: () -> Void

    init(
        trackerService: TrackerService,
        onNavigateToGroup: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: TrackerViewModel(service: trackerService))
        self.onNavigateToGroup = onNavigateToGroup
    }

    var body: some View {
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
    }

    // MARK: - 헤더

    private var header: some View {
        HStack {
            Text("북 트래커")
                .font(.pretendard(size: 24, weight: .medium))
                .foregroundColor(Color("grey800"))
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 17)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color("grey200"))
                .frame(height: 1)
        }
    }

    // MARK: - 탭 세그먼트

    private var tabSegment: some View {
        HStack(spacing: 12) {
            tabButton(.myGroup)
            tabButton(.joined)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color("grey100"))
    }

    private func tabButton(_ tab: TrackerTab) -> some View {
        let isSelected = viewModel.selectedTab == tab
        return Button {
            Task { await viewModel.selectTab(tab) }
        } label: {
            Text(tab.title)
                .font(.pretendard(size: 14, weight: .medium))
                .foregroundColor(isSelected ? Color("white") : Color("grey900"))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color("grey900") : Color("white"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.clear : Color("grey200"), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 본문

    @ViewBuilder
    private var content: some View {
        let items = viewModel.currentItems
        let phase = viewModel.currentPhase

        if items.isEmpty {
            emptyState(phase: phase)
        } else {
            list(items: items)
        }
    }

    @ViewBuilder
    private func emptyState(phase: TrackerViewModel.Phase) -> some View {
        ScrollView {
            VStack {
                switch phase {
                case .loading:
                    ProgressView()
                        .padding(.top, 80)
                case .failed(let message):
                    VStack(spacing: 16) {
                        Text(message)
                            .font(.pretendard(size: 14))
                            .foregroundColor(Color("grey500"))
                        Button("다시 시도") {
                            Task { await viewModel.refresh() }
                        }
                        .font(.pretendard(size: 14, weight: .medium))
                        .foregroundColor(Color("main200"))
                    }
                    .padding(.top, 80)
                case .idle, .refreshing, .loaded:
                    TrackerEmptyCard(
                        tab: viewModel.selectedTab,
                        onNavigateToGroup: onNavigateToGroup
                    )
                    .padding(.horizontal, 24)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .refreshable { await viewModel.refresh() }
    }

    private func list(items: [TrackerItem]) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(items) { item in
                    TrackerCard(item: item, onTap: { /* no-op: 다음 PR에서 상세 이동 */ })
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
            .padding(.bottom, 80)
        }
        .refreshable { await viewModel.refresh() }
    }
}
```

- [ ] **Step 2: BookiiTabCase 수정**

`Bookiibookii/Common/Tabbar/BookiiTabCase.swift`:

```swift
import SwiftUI

/// 메인 탭 식별자 (안드로이드 하단 네비 5탭 대응)
enum BookiiTabCase: Int, CaseIterable {
    case home
    case group
    case tracker
    case library
    case myPage

    var title: String {
        switch self {
        case .home: return "홈"
        case .group: return "그룹"
        case .tracker: return "트래커"
        case .library: return "서재"
        case .myPage: return "마이페이지"
        }
    }

    var iconName: String {
        switch self {
        case .home: return "ic_tab_home"
        case .group: return "ic_tab_group"
        case .tracker: return "ic_tab_tracker"
        case .library: return "ic_tab_library"
        case .myPage: return "ic_tab_mypage"
        }
    }

    @ViewBuilder
    func contentView(
        container: DIContainer,
        selectTab: @escaping (BookiiTabCase) -> Void
    ) -> some View {
        switch self {
        case .home:
            HomeView(
                recommendationService: container.api.recommendation,
                groupService: container.api.group,
                notificationService: container.api.notification,
                keywordService: container.api.keyword,
                onNavigateToGroup: { selectTab(.group) }
            )
        case .group: GroupView(groupService: container.api.group)
        case .tracker:
            TrackerView(
                trackerService: container.api.tracker,
                onNavigateToGroup: { selectTab(.group) }
            )
        case .library: LibraryView()
        case .myPage: MyPageView(userService: container.api.user)
        }
    }
}
```

- [ ] **Step 3: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: 커밋**

```bash
git add Bookiibookii/Features/Tracker/View/TrackerView.swift Bookiibookii/Common/Tabbar/BookiiTabCase.swift
git commit -m "feat: 트래커 탭 메인 화면 연결 (탭 세그먼트 + 리스트 + 빈 상태)

TrackerView를 TrackerViewModel과 연결하고 BookiiTabCase가 서비스/네비게이션 콜백을 주입하도록 갱신.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## 실행 후 수동 검증 (스펙 §9 체크리스트)

시뮬레이터에서 다음 확인:

- [ ] 앱 실행 → 트래커 탭 이동 → `내 그룹` 기본 선택
- [ ] Host API 호출 1회 확인 (Xcode 네트워크 로그)
- [ ] `참여한 그룹` 탭 최초 탭 → Guest API 호출, 재클릭 시 재호출 없음
- [ ] 서버 빈 배열 응답 → `TrackerEmptyCard` 노출, 탭별 문구 스왑 확인
- [ ] 빈 상태 `그룹 둘러보기` 버튼 → 그룹 탭으로 전환
- [ ] 리스트 존재 시 아래로 당겨 리프레시 → 현재 탭만 재호출
- [ ] 릴레이(HOST/GUEST) + 함께읽기 3종 모두 썸네일/제목/저자/with 정상 표시
- [ ] 네트워크 오프라인으로 실패 → 빈 리스트이면 "다시 시도" 뷰, 기존 리스트 있으면 토스트

---

## Self-Review

**Spec coverage:**
- §3 파일 구조: Task 1-10에 모두 매핑. ✓
- §4 데이터 레이어 (path/DTO/도메인/매퍼/서비스): Task 1, 3, 4. ✓
- §5 ViewModel: Task 7. ✓
- §6 뷰 레이아웃 (header/tabSegment/content/TrackerCard/TrackerEmptyCard): Task 8, 9, 10. ✓
- §7 통합 (TrackerView init + BookiiTabCase): Task 10. ✓
- §8 실행 순서 11단계 → 10 Task (기존 step 10+11 병합). ✓
- §9 검증 체크리스트: "실행 후 수동 검증" 섹션에 복사. ✓

**Placeholder 스캔:** TBD/TODO/"similar to" 없음. "no-op: 다음 PR에서 상세 이동" 주석은 PR 스코프 명시이지 플레이스홀더 아님.

**Type consistency:**
- `TrackerItem`: Task 3에서 정의, Task 7/8/10에서 참조. 필드 일치 ✓
- `ExchangeRole`/`ExchangeType`: Task 3 정의, Task 8 프리뷰에서 참조 ✓
- `TrackerTab`: Task 6 정의, Task 7/9/10에서 참조 ✓
- `TrackerService.fetchHostTrackers()/fetchGuestTrackers()`: Task 4 정의, Task 7에서 호출 ✓
- `TrackerViewModel.Phase`: Task 7 정의, Task 10에서 `emptyState(phase:)` 파라미터로 참조 ✓
- `ApiResponseDTO<T>`: 기존 프로젝트 타입 재사용, Task 4에서 참조 ✓
- `AuthInterceptor`: 기존 프로젝트 타입 재사용, Task 4/5에서 참조 ✓
- Toast binding 타입 `String?`: Task 7 `@Published var toast: String?`, Task 10 `.toast($viewModel.toast)` ✓
