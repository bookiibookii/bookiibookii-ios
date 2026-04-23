# 그룹 메인 화면 iOS 재구현 설계

**작성일**: 2026-04-22
**대상 기능**: 그룹 탭 메인 리스트 (필터 · 정렬 · 무한스크롤 · FAB)
**원본 참고**: 안드로이드 `GroupFragment.kt` / `fragment_grp.xml` / `item_grp_card.xml`
**피그마**: [node 7224:40943](https://www.figma.com/design/jgd8qddBiXrPnZ1LMvHmDi/-v1--BOOKIIBOOKII?node-id=7224-40943)

---

## 1. 범위

### 포함
- 그룹 메인 화면: 헤더, 필터 칩 3종, 정렬 row, 카드 리스트, FAB
- 필터 바텀시트 3종 (그룹유형·지역별·분야별)
- FAB 확장 메뉴 (함께읽기·이어읽기 진입 — 이번 사이클은 placeholder 토스트)
- 실제 API 연동 (`GET /api/groups`)
- Pull-to-refresh + 무한스크롤 (size=20)
- Kingfisher 도입 (그룹 화면 한정)
- Pretendard Variable 폰트 도입 (그룹 화면 한정)

### 제외 (다음 사이클)
- 그룹 검색 화면 (돋보기 탭 → 토스트 `"준비 중"`)
- 그룹 생성 화면 (FAB 옵션 탭 → 토스트 `"준비 중"`)
- 그룹 상세 화면 (카드 탭 → 토스트 `"준비 중"`)
- 배송지 검증 다이얼로그 (RELAY 그룹 탭 시 주소 확인 — 피그마 존재하지 않음, 상세 사이클로 이월)

### UI 기준점
안드로이드 XML 레이아웃이 피그마와 상충하면 **안드로이드 XML을 기준**으로 구현한다. 색상 토큰/타이포 스케일은 피그마 값을 채택.

---

## 2. 파일 구조

```
Bookiibookii/
├── Common/
│   ├── Components/
│   │   └── ToastView.swift               (신규 — 하단 토스트)
│   └── Extensions/
│       └── Font+Pretendard.swift         (신규 — Font.pretendard(size:weight:) 헬퍼)
├── Data/
│   ├── API/
│   │   └── GroupService.swift            (신규)
│   └── Models/
│       └── GroupModels.swift             (신규)
├── Features/Group/
│   ├── GroupView.swift                   (기존 placeholder 대체)
│   ├── GroupViewModel.swift              (신규)
│   ├── GroupCard.swift                   (신규)
│   ├── GroupFilterSheet.swift            (신규 — 그룹유형·분야별 공용)
│   ├── GroupRegionSheet.swift            (신규 — 지역별)
│   ├── GroupFabMenu.swift                (신규)
│   └── RegionData.swift                  (신규 — 17개 시·도 하드코딩)
├── Resources/Fonts/
│   └── PretendardVariable.ttf            (신규 — 안드로이드에서 복사)
├── Common/DIContainer/API/APIContainer.swift  (수정 — GroupService 주입 추가)
└── Common/Tabbar/BookiiTabCase.swift     (수정 — GroupView(groupService:) 전달)
```

Info.plist에 `UIAppFonts: [PretendardVariable.ttf]` 추가.

---

## 3. 의존성 변경

### Kingfisher (SPM 추가)
- Repository: `https://github.com/onevcat/Kingfisher` / version 8.x
- 사용 범위: 이번 사이클은 **그룹 화면만**. MyPage/Onboarding의 `AsyncImage`는 별도 사이클에서 일괄 마이그레이션
- 카드 내 표지·프로필 이미지 로딩에 `KFImage` 사용

### 색상 업데이트
- `grey100`: #F4F3F1 → **#F6F6F6** (피그마 `UI/bg` 토큰과 정확히 일치시킴). 기존 `grey100` 사용처(온보딩·마이페이지) 자동 반영

---

## 4. 데이터 모델 (`Data/Models/GroupModels.swift`)

```swift
// 응답 래퍼
struct GroupListResponse: Codable {
    let isSuccess: Bool
    let code: String
    let message: String
    let result: GroupPageResult?
}

struct GroupPageResult: Codable {
    let groupList: [GroupItemDto]?
    let currentPage: Int
    let hasNext: Bool
}

struct GroupItemDto: Codable, Identifiable {
    let groupId: Int
    let title: String
    let author: String?
    let genre: String?
    let bookImage: String?
    let hostProfileImageUrl: String?
    let hostNickname: String?
    let tags: [String]?
    let groupStatus: String          // RECRUITING | MATCHED | COMPLETED | 기타
    let currentCount: Int
    let maxCapacity: Int
    let readingPeriod: Int
    let customTag: String?
    let groupType: String            // TOGETHER | RELAY
    let tradeType: String?           // DELIVERY | DIRECT | nil
    let startDate: String?
    let isHot: Bool
    let pictureBadge: String?

    var id: Int { groupId }
}

// 표시용 파생 프로퍼티
extension GroupItemDto {
    var uiStatus: String {
        switch groupStatus {
        case "RECRUITING": return "모집 중"
        case "MATCHED":    return "진행 중"
        case "COMPLETED":  return "종료"
        default:           return "마감"
        }
    }
    var displayAuthor: String { author ?? "저자 미상" }
    var displayNickname: String { hostNickname ?? "알 수 없음" }
    var displayDate: String {
        guard let d = startDate else { return "날짜 미정" }
        return d.replacingOccurrences(of: "-", with: ".")
    }
    var badgeText: String { pictureBadge ?? "모집" }
    var isTogether: Bool { groupType == "TOGETHER" }
}

// 필터/정렬 enum
enum GroupSort: String { case recommend = "RECOMMEND", latest = "LATEST", popular = "POPULAR" }

enum GroupTypeFilter: String, CaseIterable, Identifiable {
    case together, delivery, direct
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .together: return "함께 읽기"
        case .delivery: return "택배 교환"
        case .direct:   return "직접 교환"
        }
    }
}

enum CategoryFilter: String, CaseIterable, Identifiable {
    case econBiz = "ECON_BIZ"
    case sciIt = "SCI_IT"
    case novelGenre = "NOVEL_GENRE"
    case poemEssay = "POEM_ESSAY"
    case homeHobby = "HOME_HOBBY"
    case artCulture = "ART_CULTURE"
    case humanHistory = "HUMAN_HISTORY"
    case selfDev = "SELF_DEV"
    case polSoc = "POL_SOC"
    // ETC는 UI 비노출

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .econBiz: return "경제/경영"
        case .sciIt: return "과학/IT"
        case .novelGenre: return "소설/장르"
        case .poemEssay: return "시/에세이"
        case .homeHobby: return "가정/취미"
        case .artCulture: return "예술/문화"
        case .humanHistory: return "인문/역사"
        case .selfDev: return "자기계발"
        case .polSoc: return "정치/사회"
        }
    }
}

struct RegionSelection: Equatable {
    let city: String            // "서울" | "경기" | ... (빈 문자열이면 전체)
    let districts: [String]     // 빈 배열이면 해당 시·도의 "전체"
    static let all = RegionSelection(city: "", districts: [])
    var isAll: Bool { city.isEmpty }
    var isCityAll: Bool { !city.isEmpty && districts.isEmpty }

    var chipLabel: String {
        if isAll { return "지역별" }
        if isCityAll { return city }
        return districts.joined(separator: " · ")
    }

    /// 서버 `meetPlace` 파라미터 값
    /// - "전체" → nil
    /// - "시·도 전체" → [시·도 이름]
    /// - 구·군 선택 → 구·군 배열
    var serverMeetPlace: [String]? {
        if isAll { return nil }
        if isCityAll { return [city] }
        return districts
    }
}

// 태그 raw → 한글 매핑 (안드로이드 GroupTagMapper.kt 그대로 포팅)
enum GroupTagMapper {
    static func koreanTag(_ raw: String) -> String {
        switch raw {
        // METHOD
        case "MEMO": return "#메모환영"
        case "POSTIT": return "#포스트잇"
        case "CLEAN": return "#깔끔하게"
        // VIBE
        case "SERIOUS": return "#진지함"
        case "LIGHT_FUN": return "#재미있게"
        case "INSIGHT": return "#인사이트"
        // SPEED
        case "FAST": return "#약 3일"
        case "NORMAL": return "#약 1주"
        case "SLOW": return "#약 1개월"
        case "UNKNOWN": return "#속도모름"
        // GENRE
        case "ECON_BIZ": return "#경제/경영"
        case "SCI_IT": return "#과학/IT"
        case "NOVEL_GENRE": return "#소설/장르"
        case "POEM_ESSAY": return "#시/에세이"
        case "HOME_HOBBY": return "#가정/취미"
        case "ART_CULTURE": return "#예술/문화"
        case "HUMAN_HISTORY": return "#인문/역사"
        case "SELF_DEV": return "#자기계발"
        case "POL_SOC": return "#정치/사회"
        case "ESC": return "#기타"
        // REVIEW
        case "KINDNESS": return "#친절매너"
        case "GOOD_HANDWRITING": return "#예쁜글씨"
        case "SWEET_COMMENT": return "#다정한코멘트"
        case "INSIGHTFUL": return "#인사이트넘침"
        case "FAST_SHIPPING": return "#빠른배송"
        case "FUNNY": return "#재미있는코멘트"
        case "CLEAN_CONDITION": return "#깔끔한상태"
        // 커스텀
        default: return raw.hasPrefix("#") ? raw : "#\(raw)"
        }
    }
}
```

---

## 5. API (`Data/API/GroupService.swift`)

```swift
final class GroupService {
    private let baseURL = URL(string: "https://bookii.gyeonseo.com/")!
    private let interceptor: AuthInterceptor
    init(interceptor: AuthInterceptor) { self.interceptor = interceptor }

    func fetchGroups(
        groupTypes: [String]?,
        tradeTypes: [String]?,
        meetPlace: [String]?,
        categories: [String]?,
        sort: GroupSort,
        page: Int,
        size: Int = 20
    ) async throws -> GroupPageResult
}
```

### 쿼리 파라미터 빌드 규칙

안드로이드 `GroupFragment.loadGroupData()` 그대로 포팅:

| 필터 상태 | groupTypes | tradeTypes |
|---|---|---|
| 전체 | nil | nil |
| 함께 읽기만 | `[TOGETHER]` | nil |
| 택배 교환만 | `[RELAY]` | `[DELIVERY]` |
| 직접 교환만 | `[RELAY]` | `[DIRECT]` |
| 함께+택배 | `[TOGETHER, RELAY]` | `[DELIVERY]` |
| 함께+직접 | `[TOGETHER, RELAY]` | `[DIRECT]` |
| 택배+직접 | `[RELAY]` | `[DELIVERY, DIRECT]` |
| 전부 | `[TOGETHER, RELAY]` | `[DELIVERY, DIRECT]` |

| 지역 상태 | meetPlace |
|---|---|
| 전체 | nil |
| "서울 전체" | `["서울"]` |
| "서울 강남구" | `["강남구"]` |
| "서울 강남구 · 서초구" | `["강남구", "서초구"]` |

| 분야 상태 | categories |
|---|---|
| 전체 | nil |
| 선택 있음 | enum rawValue 배열 |

### APIContainer 수정

```swift
final class APIContainer: Sendable {
    let auth: AuthService
    let interceptor: AuthInterceptor
    let user: UserService
    let group: GroupService   // 추가

    init(auth: AuthService = AuthService()) {
        self.auth = auth
        let interceptor = AuthInterceptor(authService: auth)
        self.interceptor = interceptor
        self.user = UserService(interceptor: interceptor)
        self.group = GroupService(interceptor: interceptor)   // 추가
    }
}
```

---

## 6. ViewModel (`GroupViewModel.swift`)

```swift
@MainActor
final class GroupViewModel: ObservableObject {
    // 필터 상태 (UI 바인딩)
    @Published var groupTypes: Set<GroupTypeFilter> = []     // empty == 전체
    @Published var categories: Set<CategoryFilter> = []      // empty == 전체
    @Published var region: RegionSelection = .all
    @Published var sort: GroupSort = .recommend

    // 리스트 상태
    @Published private(set) var items: [GroupItemDto] = []
    @Published private(set) var page: Int = 0
    @Published private(set) var hasNext: Bool = false
    @Published private(set) var phase: Phase = .idle
    @Published var toast: String? = nil

    enum Phase { case idle, loading, loadingMore, refreshing, failed }

    private let service: GroupService

    init(service: GroupService) { self.service = service }

    func onAppear() async        // items.isEmpty일 때만 로드
    func refresh() async          // page=0부터 재로드 (pull-to-refresh)
    func reload() async          // 필터/정렬 변경 시 (내부)
    func loadNextPage() async    // hasNext && phase == .idle 일 때만

    func applyGroupTypes(_ next: Set<GroupTypeFilter>) async
    func applyCategories(_ next: Set<CategoryFilter>) async
    func applyRegion(_ next: RegionSelection) async
    func changeSort(_ next: GroupSort) async
    func showComingSoon()         // 토스트 "준비 중입니다"
}
```

**로직 디테일**
- `onAppear`: `items.isEmpty && phase == .idle` 조건에서만 `loadFirstPage()` 실행. 탭 전환으로 뷰 재등장 시 중복 호출 방지
- `applyXxx` / `changeSort`: 값 변경 감지 후 `items = []; page = 0; hasNext = false; reload()`
- `reload`: `phase = .loading`, page 0 페칭, 성공 시 `items = new`, 실패 시 `phase = .failed`, `toast = "불러오기 실패"`
- `loadNextPage`: `phase = .loadingMore`, `page + 1` 페칭, 성공 시 `items.append(contentsOf:)`, 실패 시 `phase = .failed`, `toast = "추가 로드 실패"`
- `refresh`: `phase = .refreshing`, 리로드, 성공 시 `items` 교체

---

## 7. View 구조

### GroupView

```swift
struct GroupView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: GroupViewModel
    @State private var activeSheet: ActiveSheet? = nil
    @State private var isFabOpen: Bool = false

    enum ActiveSheet: String, Identifiable {
        case groupType, region, category
        var id: String { rawValue }
    }

    init(groupService: GroupService) {
        _viewModel = StateObject(wrappedValue: GroupViewModel(service: groupService))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color("grey100").ignoresSafeArea()
            VStack(spacing: 0) {
                header
                filterChipsRow
                sortRow
                listSection
            }
            fabOverlay           // isFabOpen이면 딤 오버레이
            fab                  // FAB + 확장 메뉴
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .groupType:
                GroupFilterSheet<GroupTypeFilter>(
                    kind: .groupType,
                    preSelected: viewModel.groupTypes,
                    onConfirm: { next in Task { await viewModel.applyGroupTypes(next) } }
                )
                .presentationDetents([.height(240)])
                .presentationDragIndicator(.visible)
            case .category:
                GroupFilterSheet<CategoryFilter>(
                    kind: .category,
                    preSelected: viewModel.categories,
                    onConfirm: { next in Task { await viewModel.applyCategories(next) } }
                )
                .presentationDetents([.height(344)])
                .presentationDragIndicator(.visible)
            case .region:
                GroupRegionSheet(
                    preSelected: viewModel.region,
                    onConfirm: { next in Task { await viewModel.applyRegion(next) } }
                )
                .presentationDetents([.height(346)])
                .presentationDragIndicator(.visible)
            }
        }
        .task { await viewModel.onAppear() }
        .refreshable { await viewModel.refresh() }
        .toast($viewModel.toast)
    }
}
```

### 레이아웃 스펙 (안드로이드 XML + 피그마)

| 요소 | 스펙 |
|---|---|
| 배경 | `grey100` (#F6F6F6) |
| 좌우 여백 | 24pt (전역) |
| 헤더 — "그룹" title | Pretendard Bold 24pt `grey700`, top 20pt, leading |
| 헤더 — 검색 아이콘 | 40×40 원형 흰 bg `grey200` border 1pt, 내부 `ic_search` 24pt `grey900`, trailing |
| 필터칩 row | HStack scrollable, h 36pt, chip spacing 8, top 16pt. 각 칩 좌우 padding 16 |
| 필터칩 비활성 | white bg, `grey200` border 1pt, `grey500` text Regular 13pt |
| 필터칩 활성 | `grey900` bg, border 0, white text Medium 13pt |
| 정렬 row | HStack `Spacer + (추천순 | 최신순 | 인기순)`, top 32pt, trailing 24 |
| 리스트 | ScrollView + LazyVStack spacing 16, top 12, bottom inset 80 |
| FAB | 70×70 원, `grey900` bg, trailing 24 bottom 16 |

### 카드 (`GroupCard`)

```swift
struct GroupCard: View {
    let item: GroupItemDto
    let onTap: () -> Void
}
```

카드 외형: white bg, 코너 20pt, padding 16pt.

**구성 (세로)**
1. 표지(74×94, 코너 10pt, `KFImage`) + 정보 블럭(제목/저자/메타) + 상태 뱃지(우상단)
2. 프로필 row (top 12): 20×20 원형 프로필 + 닉네임 + 날짜
3. 태그 row (top 12): `FlowLayout` 으로 최대 3개 + "+N"

**상태 뱃지 규칙**
- `isTogether` → `grey900` bg + white text, 텍스트 `"함께읽기(\(maxCapacity))"`
- 아니면 → `main200` bg + white text, 텍스트 `item.badgeText`
- 공통: Capsule, h 23pt, Medium 11pt, padding h 8pt

**HOT 뱃지**
- 조건: `item.isHot`
- `main100` bg + `main200` text, Capsule, h 16pt, Medium 11pt, padding h 6pt
- 메타 row 끝 `"N명 대기"` 우측

**태그 칩**
- `#\(customTag)` (있으면) + `tags.map { GroupTagMapper.koreanTag($0) }` 합쳐서 처음 3개 칩, 4번째 이후는 `+N` 칩
- 각 칩: Capsule h 23pt, `sub100` bg, `sub200` text, Medium 11pt, padding h 10pt

**메타 row**
- 📅 `ic_cal` 16pt `grey500` + space 4 + `readingPeriod`일 + space 4 + 구분선(`Rectangle` 1×10 `grey400`) + space 4 + 👥 `ic_group` 16pt `grey500` + space 4 + `currentCount`명 대기 + (optional) HOT 뱃지
- 폰트 Regular 11pt `grey500`

**전체 탭**: `.contentShape(Rectangle()).onTapGesture(onTap)`.

### FAB 메뉴 (`GroupFabMenu`)

```swift
struct GroupFabMenu: View {
    @Binding var isOpen: Bool
    let onTapTogether: () -> Void
    let onTapRelay: () -> Void
}
```

**수축**: 70×70 원, `grey900` bg, 중앙 `ic_fab_plus` 24pt white. 탭 → `isOpen = true`.

**확장**:
- 두 옵션 pill (위 → 아래 순): 함께읽기, 이어읽기
  - 108×48 white bg, 코너 20pt, shadow 미약
  - 내부 HStack 중앙: 아이콘 16pt + 텍스트 14pt Medium `grey900`
  - 간격: 스택 12pt, FAB 위쪽 12pt
- 탭 → 해당 콜백 + `isOpen = false`
- FAB 아이콘 `ic_fab_plus` → `ic_fab_close`로 교체
- 등장 애니메이션: `opacity 0→1, offset y +50 → 0`, `.easeOut(duration: 0.3)`

**딤 오버레이**: `isOpen`일 때 `Color.black.opacity(0.5)` 전체 덮고 탭 시 닫음. FAB 영역만 hit 제외 (`allowsHitTesting`).

### 필터 바텀시트

`.sheet(item: $activeSheet)` 내부에서 분기해 `GroupFilterSheet` 또는 `GroupRegionSheet` 렌더.  
`.presentationDetents([.height(240)])` (그룹유형), `.height(344)` (분야별), `.height(346)` (지역별)  
`.presentationDragIndicator(.visible)`.

#### GroupFilterSheet (그룹유형·분야별 공용)

```swift
struct GroupFilterSheet<Item: Hashable & Identifiable>: View {
    enum Kind { case groupType, category }
    let kind: Kind
    let preSelected: Set<Item>
    let onConfirm: (Set<Item>) -> Void
}
```

공통 구조: 상단 타이틀+요약 / 중간 칩 영역 / 하단 취소·확인 버튼.

**칩 선택 로직**:
- `전체` 탭 → 나머지 전부 해제, selection 비움
- 다른 칩 탭 → selection에 add/remove, `전체` 자동 해제
- 모두 해제되면 `전체` 자동 재활성
- 확인 → `selection.isEmpty ? [] : selection` 을 `onConfirm`으로 전달 (empty set == "전체")

**그룹유형 칩 배열**: `전체`, 세로 divider(1×28 `grey300`), `함께 읽기`, `직접 교환`, `택배 교환`.  
HStack 가로 스크롤, 칩 spacing 8.

**분야별 칩 배열**: `전체`, `경제/경영`, `과학/IT`, `소설/장르`, `시/에세이`, `가정/취미`, `예술/문화`, `인문/역사`, `자기계발`, `정치/사회`.  
`FlowLayout`(SwiftUI `Layout`) 2~3줄 자동 줄바꿈, spacing 8.

**요약 텍스트** (타이틀 우측):
- 0개: `"전체"` (`main200`)
- 1~3개: `"A · B · C"` (`main200`)
- 4개 이상: `"A · B · C 외 N개"` (중간점은 `grey300`)

#### GroupRegionSheet

```swift
struct GroupRegionSheet: View {
    let preSelected: RegionSelection
    let onConfirm: (RegionSelection) -> Void
}
```

**레이아웃** (HStack):
- **좌측 (w 64pt)**: 시·도 리스트 `ScrollView`+`LazyVStack` spacing 4. 각 row h 36pt. 선택된 시·도는 좌측에 3×24 세로 bar `main200`, 텍스트 Bold 14pt `grey900`. 미선택 Regular 14pt `grey500`
- **우측 (나머지)**: 선택된 시·도의 구·군 칩 그리드 `FlowLayout` 3열, `ScrollView`. 칩 스타일은 공통 필터 칩과 동일

**선택 로직**:
- 시·도 바꾸면 `selectedDistricts = []`
- `전체` 칩: 탭 → 다른 구 해제. 해제하려는데 다른 구 없으면 재선택
- 다른 구 최대 3개 (4번째 탭 시 토스트 `"최대 3개까지 선택 가능합니다."`, 체크 상태 되돌림)
- 확인 → `RegionSelection(city, districts)` 전달

**초기 상태**: `preSelected.city`가 있으면 해당 시·도 선택 + 리스트 스크롤 이동, districts 프리체크. `isAll`이면 기본 `서울`.

**17개 시·도 데이터** (`RegionData.swift`)  
안드로이드 `GrpRegionBottomSheetFragment.getMockCityData()` 내용 그대로 포팅. 순서: 서울·경기·인천·대전·대구·광주·울산·부산·세종·강원·충북·충남·전북·전남·경북·경남·제주.

### 정렬 row

`추천순 | 최신순 | 인기순` HStack 오른쪽 정렬.

| 상태 | 스타일 |
|---|---|
| 활성 | Medium 14pt `main200` |
| 비활성 | Regular 14pt `grey500` |
| 구분자 | Regular 14pt `grey400`, padding 좌우 4pt |

탭 → 같은 정렬이면 무시, 다르면 `vm.changeSort()`.

### 무한스크롤

`LazyVStack` 안 마지막 카드(`items[items.count - 1]`)에 `.onAppear { if vm.hasNext && vm.phase == .idle { Task { await vm.loadNextPage() } } }`.  
로드 중에는 리스트 마지막에 `ProgressView` 48pt 높이 셀 표시.

### 빈/로딩 상태

| 조건 | 표시 |
|---|---|
| `phase == .loading && items.isEmpty` | 중앙 `ProgressView` |
| `phase == .idle && items.isEmpty` | 중앙 `"조건에 맞는 그룹이 없어요"` (`grey500` 14pt) |
| `phase == .failed && items.isEmpty` | 중앙 `"불러오기 실패"` + `"다시 시도"` 버튼 (탭 → `viewModel.reload()`) |

---

## 8. Toast (`Common/Components/ToastView.swift`)

```swift
struct ToastView: ViewModifier {
    @Binding var message: String?
    func body(content: Content) -> some View { ... }
}

extension View {
    func toast(_ message: Binding<String?>) -> some View {
        modifier(ToastView(message: message))
    }
}
```

- 하단 중앙, safe area bottom + 80pt
- 배경 `grey900.opacity(0.9)`, 흰 텍스트, 코너 12pt, padding h 16 v 10
- 등장: fade in 0.2s, 2초 후 fade out 0.3s
- 한 번에 1개만 표시. 표시 중 새 메시지 오면 즉시 교체

---

## 9. Font 헬퍼 (`Common/Extensions/Font+Pretendard.swift`)

```swift
extension Font {
    static func pretendard(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("Pretendard Variable", size: size).weight(weight)
    }
}
```

(폰트 이름은 실제 `.ttf` 설치 후 UIFont로 확인)

사용 예: `.font(.pretendard(size: 14, weight: .medium))`

---

## 10. 에러 처리

- 네트워크 에러(`URLError`) → 토스트 `"네트워크 연결을 확인해주세요"`
- 서버 `isSuccess == false` → 토스트에 `response.message` 표시
- 401 → `AuthInterceptor`가 자동 갱신 (기존 패턴). 재시도 실패 시 `authTokenExpired` 통지 → 앱 레벨 로그아웃
- 디코딩 실패 → 토스트 `"데이터 처리 오류"`, `phase = .failed`

---

## 11. 자산 (사용자 제공 완료)

`Assets.xcassets/CommonAssets/`에 추가된 것:
- `ic_search`, `ic_cal`, `ic_group`, `ic_fab_plus`, `ic_fab_close`, `ic_fab_together`, `ic_fab_relay`

폰트: `/Users/qhrtj07/StudioProjects/bookiibookii-android/app/src/main/res/font/pretendard_variable.ttf` → `Bookiibookii/Resources/Fonts/PretendardVariable.ttf` 복사.

---

## 12. 단위 기능 체크리스트

구현 중 아래 시나리오로 수동 검증:

- [ ] 앱 시작 → 홈 → 그룹 탭: 첫 페이지 20개 표시
- [ ] 그룹 탭 → 다른 탭 → 돌아옴: 재페칭 없음
- [ ] 맨 아래 스크롤: 다음 페이지 자동 로드, `hasNext=false`면 중단
- [ ] Pull-to-refresh: 첫 페이지부터 다시 로드
- [ ] 그룹유형 바텀시트 `함께 읽기`만 선택 → 확인: 리스트가 TOGETHER만으로 필터
- [ ] 그룹유형 바텀시트 `택배 교환` + `직접 교환` → 확인: groupTypes=[RELAY], tradeTypes=[DELIVERY,DIRECT]
- [ ] 지역 바텀시트 `서울` → 4개째 구 선택 시도: 토스트 `"최대 3개..."` + 체크 되돌림
- [ ] 지역 바텀시트 `서울 전체` → 확인: meetPlace=[서울]
- [ ] 분야별 `과학/IT` + `자기계발` → 확인 → 요약 텍스트 `"과학/IT · 자기계발"`
- [ ] 정렬 최신순 탭: 리스트 재로드
- [ ] 카드 탭: 토스트 `"상세는 준비 중"`
- [ ] FAB 탭: 확장 + 딤. 딤 탭 → 닫힘. 함께읽기/이어읽기 탭 → 토스트
- [ ] 돋보기 탭: 토스트 `"검색은 준비 중"`
- [ ] 네트워크 차단 후 Pull-to-refresh: 토스트 `"네트워크..."`, 기존 리스트 유지

---

## 13. 다음 사이클로 이월

- 그룹 검색 화면 (돋보기 진입)
- 그룹 생성 화면 (FAB 옵션 → `GroupGenerationView`)
- 그룹 상세 화면 (카드 탭 → `GroupDetailView`)
- 배송지 검증 다이얼로그 (RELAY 그룹 진입 전 주소 확인)
- Kingfisher 전면 마이그레이션 (MyPage, Onboarding)
- Pretendard 전면 적용 (MyPage, Onboarding)
