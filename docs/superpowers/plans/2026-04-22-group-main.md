# 그룹 메인 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 안드로이드 그룹 탭의 메인 화면(목록 · 필터 3종 · 정렬 · 무한스크롤 · FAB)을 iOS SwiftUI로 재구현한다. 실제 API 연동, Kingfisher 이미지 로딩, Pretendard 폰트 도입을 포함한다.

**Architecture:** MVVM (`GroupView` + `@StateObject GroupViewModel`), `GroupService`를 `APIContainer`에 주입. 공용 `GroupFilterSheet`(그룹유형·분야별)과 `GroupRegionSheet`(지역별)을 `.sheet(item:)`로 표시. 모든 뷰는 `.environmentObject(DIContainer)` 상위에서 렌더.

**Tech Stack:** Swift 5.9+ / SwiftUI iOS 16+ / async-await / URLSession / Kingfisher / Pretendard Variable

**스펙 문서:** [`docs/superpowers/specs/2026-04-22-group-main-design.md`](../specs/2026-04-22-group-main-design.md)

## 테스트 전략

현재 프로젝트에 XCTest 테스트 타겟이 없고 이번 사이클은 테스트 인프라 도입 범위가 아님. 각 작업은 다음 3가지 방식으로 검증한다:

1. **컴파일 검증**: `xcodebuild -scheme Bookiibookii -destination 'platform=iOS Simulator,name=iPhone 15' build` 로 빌드 성공 확인
2. **Xcode 프리뷰**: 각 View 컴포넌트마다 `#Preview` 블록 포함해 시각적 확인
3. **수동 체크리스트** (Phase 6): 시뮬레이터에서 스펙 §12의 13가지 시나리오 확인

---

## Phase 0: 의존성 셋업

### Task 0.1: Kingfisher SPM 추가 (사용자 수동 단계)

**Files:**
- Modify: `Bookiibookii.xcodeproj/project.pbxproj` (Xcode가 자동 수정)
- Modify: `Bookiibookii.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`

- [ ] **Step 1: Xcode에서 Kingfisher 패키지 추가**

Xcode를 열고 다음을 수행한다:
1. `File` → `Add Package Dependencies...`
2. 우측 상단 검색창에 URL 입력: `https://github.com/onevcat/Kingfisher`
3. Dependency Rule: `Up to Next Major Version` `8.0.0`
4. `Add Package` 클릭
5. Target: `Bookiibookii` 체크, `Add Package` 확정

- [ ] **Step 2: 추가 확인**

Bash에서:
```bash
grep -q "kingfisher" Bookiibookii.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved && echo OK || echo MISSING
```
예상 출력: `OK`

- [ ] **Step 3: 임포트 테스트 (임시)**

`Bookiibookii/BookiibookiiApp.swift` 최상단에 한 줄 추가 후 빌드로 확인:
```swift
import Kingfisher
```

빌드 성공 확인 후 import 문 제거 (실제 사용처는 이후 태스크에서).

- [ ] **Step 4: 커밋**

```bash
git add Bookiibookii.xcodeproj/project.pbxproj \
        Bookiibookii.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
git commit -m "chore: Kingfisher SPM 패키지 추가"
```

---

### Task 0.2: Pretendard Variable 폰트 추가

**Files:**
- Create: `Bookiibookii/Resources/Fonts/PretendardVariable.ttf` (안드로이드에서 복사)
- Modify: `Bookiibookii/Info.plist` (UIAppFonts 배열 추가)

- [ ] **Step 1: 폰트 파일 복사**

```bash
mkdir -p Bookiibookii/Resources/Fonts
cp /Users/qhrtj07/StudioProjects/bookiibookii-android/app/src/main/res/font/pretendard_variable.ttf \
   Bookiibookii/Resources/Fonts/PretendardVariable.ttf
ls -la Bookiibookii/Resources/Fonts/
```
예상: `PretendardVariable.ttf` 파일 존재 (약 2MB)

- [ ] **Step 2: Xcode에서 Resources 폴더 추가 (사용자 수동)**

Xcode Project Navigator에서:
1. `Bookiibookii` 프로젝트 루트 우클릭 → `Add Files to "Bookiibookii"...`
2. `Bookiibookii/Resources` 폴더 선택
3. Options: `Create groups` 선택, Target: `Bookiibookii` 체크
4. `Add`

**중요**: 폴더 참조(`Create folder references`) 방식이 아닌 **그룹(`Create groups`)** 방식으로 추가해야 `Copy Bundle Resources`에 자동 포함된다.

- [ ] **Step 3: Info.plist에 UIAppFonts 추가**

`Bookiibookii/Info.plist`의 `<dict>` 내부 마지막에 추가:

```xml
	<key>UIAppFonts</key>
	<array>
		<string>PretendardVariable.ttf</string>
	</array>
</dict>
</plist>
```

- [ ] **Step 4: 폰트 등록 확인**

`Bookiibookii/BookiibookiiApp.swift`의 `init()`을 임시로 아래처럼 교체 (기존 KakaoSDK 초기화를 보존한 채 디버그 로그만 추가):

```swift
init() {
    #if DEBUG
    UIFont.familyNames.filter { $0.contains("Pretendard") }.forEach {
        print("Font family:", $0, UIFont.fontNames(forFamilyName: $0))
    }
    #endif
    // 안드로이드 KakaoSdk.init 대응
    let appKey = Bundle.main.object(forInfoDictionaryKey: "KAKAO_NATIVE_APP_KEY") as? String ?? ""
    KakaoSDK.initSDK(appKey: appKey)
}
```

시뮬레이터 실행 후 Xcode 콘솔에 `Pretendard Variable` 또는 `PretendardVariable`로 시작하는 폰트 family가 출력되는지 확인.

확인되면 다시 원래 init()으로 되돌림 (디버그 블록만 제거):

```swift
init() {
    let appKey = Bundle.main.object(forInfoDictionaryKey: "KAKAO_NATIVE_APP_KEY") as? String ?? ""
    KakaoSDK.initSDK(appKey: appKey)
}
```

- [ ] **Step 5: 커밋**

```bash
git add Bookiibookii/Resources/Fonts/PretendardVariable.ttf \
        Bookiibookii/Info.plist \
        Bookiibookii.xcodeproj/project.pbxproj
git commit -m "chore: Pretendard Variable 폰트 추가"
```

---

### Task 0.3: grey100 색상을 #F6F6F6으로 업데이트

**Files:**
- Modify: `Bookiibookii/Assets.xcassets/AccentColor/grey100.colorset/Contents.json`

- [ ] **Step 1: 현재 값 확인**

```bash
grep -A1 '"blue"\|"green"\|"red"' Bookiibookii/Assets.xcassets/AccentColor/grey100.colorset/Contents.json | head -10
```
예상: `red=0xF4, green=0xF3, blue=0xF1` (현재 값)

- [ ] **Step 2: 파일 전체 교체**

`Bookiibookii/Assets.xcassets/AccentColor/grey100.colorset/Contents.json`의 내용을 아래로 교체:

```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0xF6",
          "green" : "0xF6",
          "red" : "0xF6"
        }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0xFF",
          "green" : "0xFF",
          "red" : "0xFE"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 3: 변경 확인**

```bash
grep -A3 '"appearances"' Bookiibookii/Assets.xcassets/AccentColor/grey100.colorset/Contents.json | head -1
grep '"red" : "0xF6"' Bookiibookii/Assets.xcassets/AccentColor/grey100.colorset/Contents.json && echo OK
```
예상: `OK`

- [ ] **Step 4: 커밋**

```bash
git add Bookiibookii/Assets.xcassets/AccentColor/grey100.colorset/Contents.json
git commit -m "style: grey100을 피그마 UI/bg 토큰(#F6F6F6)에 일치시킴"
```

---

## Phase 1: 공용 컴포넌트

### Task 1.1: Font.pretendard 확장 헬퍼

**Files:**
- Create: `Bookiibookii/Common/Extensions/Font+Pretendard.swift`

- [ ] **Step 1: 디렉토리 확인**

```bash
ls Bookiibookii/Common/ 2>/dev/null
mkdir -p Bookiibookii/Common/Extensions
```

- [ ] **Step 2: 파일 생성**

`Bookiibookii/Common/Extensions/Font+Pretendard.swift`:

```swift
import SwiftUI

extension Font {
    /// Pretendard Variable 폰트. 가변 폰트이므로 weight 파라미터로 굵기 지정.
    /// 시스템 폰트 대체가 필요할 경우 registered name은 "Pretendard Variable"
    static func pretendard(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("Pretendard Variable", size: size).weight(weight)
    }
}
```

- [ ] **Step 3: 프리뷰로 시각 확인 (임시)**

동일 파일 하단에 `#Preview` 추가 후 Xcode 프리뷰로 실제 렌더 확인:

```swift
#Preview("Pretendard Sample") {
    VStack(alignment: .leading, spacing: 8) {
        Text("Regular 14").font(.pretendard(size: 14))
        Text("Medium 14").font(.pretendard(size: 14, weight: .medium))
        Text("Bold 24").font(.pretendard(size: 24, weight: .bold))
    }
    .padding()
}
```

프리뷰에서 글자체가 **시스템 폰트가 아닌 Pretendard**로 보이는지 확인. 보이지 않으면 Task 0.2의 Step 4 폰트 등록 로그를 다시 확인.

- [ ] **Step 4: 커밋**

```bash
git add Bookiibookii/Common/Extensions/Font+Pretendard.swift
git commit -m "feat: Font.pretendard(size:weight:) 확장 헬퍼 추가"
```

---

### Task 1.2: ToastView 컴포넌트

**Files:**
- Create: `Bookiibookii/Common/Components/ToastView.swift`

- [ ] **Step 1: 디렉토리 생성**

```bash
mkdir -p Bookiibookii/Common/Components
```

- [ ] **Step 2: 파일 생성**

`Bookiibookii/Common/Components/ToastView.swift`:

```swift
import SwiftUI

/// 하단 중앙 토스트.
/// @Binding message가 nil이 아닐 때 표시, 2초 후 자동으로 nil로 되돌림.
struct ToastView: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content

            if let message {
                Text(message)
                    .font(.pretendard(size: 14, weight: .medium))
                    .foregroundColor(Color("white"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color("grey900").opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 80)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .task(id: message) {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        withAnimation(.easeOut(duration: 0.3)) { self.message = nil }
                    }
            }
        }
        .animation(.easeOut(duration: 0.2), value: message)
    }
}

extension View {
    func toast(_ message: Binding<String?>) -> some View {
        modifier(ToastView(message: message))
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var msg: String? = nil
        var body: some View {
            VStack {
                Button("토스트 표시") { msg = "준비 중입니다" }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toast($msg)
        }
    }
    return PreviewHost()
}
```

- [ ] **Step 3: 프리뷰 동작 확인**

Xcode 프리뷰에서 버튼 탭 → 하단에 토스트 표시, 2초 후 사라짐 확인.

- [ ] **Step 4: 커밋**

```bash
git add Bookiibookii/Common/Components/ToastView.swift
git commit -m "feat: 하단 토스트 ViewModifier 추가"
```

---

## Phase 2: 데이터 레이어

### Task 2.1: GroupModels.swift

**Files:**
- Create: `Bookiibookii/Data/Models/GroupModels.swift`

- [ ] **Step 1: 파일 생성**

`Bookiibookii/Data/Models/GroupModels.swift`:

```swift
import Foundation

// MARK: - API 응답

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

// MARK: - 표시용 파생 프로퍼티

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
    var displayGenre: String? {
        guard let g = genre, !g.isEmpty else { return nil }
        return "(\(g))"
    }
    var badgeText: String { pictureBadge ?? "모집" }
    var isTogether: Bool { groupType == "TOGETHER" }
}

// MARK: - 필터/정렬 enum

enum GroupSort: String { case recommend = "RECOMMEND", latest = "LATEST", popular = "POPULAR"

    var displayName: String {
        switch self {
        case .recommend: return "추천순"
        case .latest:    return "최신순"
        case .popular:   return "인기순"
        }
    }
}

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

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .econBiz:      return "경제/경영"
        case .sciIt:        return "과학/IT"
        case .novelGenre:   return "소설/장르"
        case .poemEssay:    return "시/에세이"
        case .homeHobby:    return "가정/취미"
        case .artCulture:   return "예술/문화"
        case .humanHistory: return "인문/역사"
        case .selfDev:      return "자기계발"
        case .polSoc:       return "정치/사회"
        }
    }
}

// MARK: - 지역 선택 상태

struct RegionSelection: Equatable {
    let city: String            // "" == 전체
    let districts: [String]     // [] && !city.isEmpty == "시도 전체"

    static let all = RegionSelection(city: "", districts: [])

    var isAll: Bool { city.isEmpty }
    var isCityAll: Bool { !city.isEmpty && districts.isEmpty }

    /// 메인 필터 칩에 표시할 라벨
    var chipLabel: String {
        if isAll { return "지역별" }
        if isCityAll { return city }
        return districts.joined(separator: " · ")
    }

    /// 바텀시트 상단 요약에 표시할 라벨
    var summaryLabel: String {
        if isAll { return "전체" }
        if isCityAll { return city }
        return districts.joined(separator: " · ")
    }

    /// 서버 `meetPlace` 파라미터
    var serverMeetPlace: [String]? {
        if isAll { return nil }
        if isCityAll { return [city] }
        return districts
    }
}

// MARK: - 태그 매퍼 (안드로이드 GroupTagMapper 포팅)

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
        default:
            return raw.hasPrefix("#") ? raw : "#\(raw)"
        }
    }
}
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -scheme Bookiibookii -destination 'platform=iOS Simulator,name=iPhone 15' -quiet build 2>&1 | tail -5
```
예상: `BUILD SUCCEEDED`

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Data/Models/GroupModels.swift
git commit -m "feat: 그룹 모델/enum 추가"
```

---

### Task 2.2: GroupService.swift

**Files:**
- Create: `Bookiibookii/Data/API/GroupService.swift`

- [ ] **Step 1: 파일 생성**

`Bookiibookii/Data/API/GroupService.swift`:

```swift
import Foundation

// 안드로이드 GroupFragment.loadGroupData 대응. GET /api/groups 한 엔드포인트.
final class GroupService {
    private let baseURL = URL(string: "https://bookii.gyeonseo.com/")!
    private let interceptor: AuthInterceptor

    init(interceptor: AuthInterceptor) { self.interceptor = interceptor }

    /// GET /api/groups
    /// - Parameters는 nil이면 해당 필터 미적용(전체).
    func fetchGroups(
        groupTypes: [String]?,
        tradeTypes: [String]?,
        meetPlace: [String]?,
        categories: [String]?,
        sort: GroupSort,
        page: Int,
        size: Int = 20
    ) async throws -> GroupPageResult {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("api/groups"),
            resolvingAgainstBaseURL: false
        )!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "sort", value: sort.rawValue),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size))
        ]
        groupTypes?.forEach { items.append(URLQueryItem(name: "groupTypes", value: $0)) }
        tradeTypes?.forEach { items.append(URLQueryItem(name: "tradeTypes", value: $0)) }
        meetPlace?.forEach  { items.append(URLQueryItem(name: "meetPlace",  value: $0)) }
        categories?.forEach { items.append(URLQueryItem(name: "categories", value: $0)) }
        components.queryItems = items

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"

        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw GroupServiceError.http(http.statusCode)
        }

        let response = try JSONDecoder().decode(GroupListResponse.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw GroupServiceError.server(response.message)
        }
        return result
    }
}

enum GroupServiceError: LocalizedError {
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
xcodebuild -scheme Bookiibookii -destination 'platform=iOS Simulator,name=iPhone 15' -quiet build 2>&1 | tail -5
```
예상: `BUILD SUCCEEDED`

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Data/API/GroupService.swift
git commit -m "feat: GroupService — GET /api/groups 구현"
```

---

### Task 2.3: APIContainer에 GroupService 주입

**Files:**
- Modify: `Bookiibookii/Common/DIContainer/API/APIContainer.swift`

- [ ] **Step 1: 파일 수정**

`Bookiibookii/Common/DIContainer/API/APIContainer.swift` 내용 전체 교체:

```swift
import Foundation

final class APIContainer: Sendable {
    let auth: AuthService
    let interceptor: AuthInterceptor
    let user: UserService
    let group: GroupService

    init(auth: AuthService = AuthService()) {
        self.auth = auth
        let interceptor = AuthInterceptor(authService: auth)
        self.interceptor = interceptor
        self.user = UserService(interceptor: interceptor)
        self.group = GroupService(interceptor: interceptor)
    }
}
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -scheme Bookiibookii -destination 'platform=iOS Simulator,name=iPhone 15' -quiet build 2>&1 | tail -5
```
예상: `BUILD SUCCEEDED`

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Common/DIContainer/API/APIContainer.swift
git commit -m "feat: APIContainer에 GroupService 주입"
```

---

### Task 2.4: RegionData.swift — 17개 시·도 하드코딩

**Files:**
- Create: `Bookiibookii/Features/Group/RegionData.swift`

- [ ] **Step 1: 디렉토리 확인**

```bash
ls Bookiibookii/Features/Group/
```

- [ ] **Step 2: 파일 생성**

`Bookiibookii/Features/Group/RegionData.swift` (안드로이드 `GrpRegionBottomSheetFragment.getMockCityData()` 그대로 포팅):

```swift
import Foundation

/// 안드로이드 `GrpRegionBottomSheetFragment.getMockCityData()` 포팅
struct KoreaRegion: Identifiable, Equatable {
    let name: String
    let districts: [String]   // 첫 요소는 항상 "전체"
    var id: String { name }
}

enum RegionData {
    static let cities: [KoreaRegion] = [
        KoreaRegion(name: "서울", districts: ["전체", "강남구", "강동구", "강북구", "강서구", "관악구", "광진구", "구로구", "금천구", "노원구", "도봉구", "동대문구", "동작구", "마포구", "서대문구", "서초구", "성동구", "성북구", "송파구", "양천구", "영등포구", "용산구", "은평구", "종로구", "중구", "중랑구"]),
        KoreaRegion(name: "경기", districts: ["전체", "수원시", "성남시", "의정부시", "안양시", "부천시", "광명시", "평택시", "동두천시", "안산시", "고양시", "과천시", "구리시", "남양주시", "오산시", "시흥시", "군포시", "의왕시", "하남시", "용인시", "파주시", "이천시", "안성시", "김포시", "화성시", "광주시", "양주시", "포천시", "여주시", "연천군", "가평군", "양평군"]),
        KoreaRegion(name: "인천", districts: ["전체", "계양구", "미추홀구", "남동구", "동구", "부평구", "서구", "연수구", "중구", "강화군·옹진군"]),
        KoreaRegion(name: "대전", districts: ["전체", "대덕구", "동구", "서구", "유성구", "중구"]),
        KoreaRegion(name: "대구", districts: ["전체", "남구", "달서구", "동구", "북구", "서구", "수성구", "중구", "달성군", "군위군"]),
        KoreaRegion(name: "광주", districts: ["전체", "광산구", "남구", "동구", "북구", "서구"]),
        KoreaRegion(name: "울산", districts: ["전체", "남구", "동구", "북구", "중구", "울주군"]),
        KoreaRegion(name: "부산", districts: ["전체", "강서구", "금정구", "남구", "동구", "동래구", "부산진구", "북구", "사상구", "사하구", "서구", "수영구", "연제구", "영도구", "중구", "해운대구", "기장군"]),
        KoreaRegion(name: "세종", districts: ["전체", "세종특별자치시"]),
        KoreaRegion(name: "강원", districts: ["전체", "춘천시", "원주시", "강릉시", "동해시", "태백시", "속초시", "삼척시", "홍천군", "횡성군", "영월군", "평창군", "정선군", "철원군", "화천군", "양구군", "인제군", "고성군", "양양군"]),
        KoreaRegion(name: "충북", districts: ["전체", "청주시", "충주시", "제천시", "보은군", "옥천군", "영동군", "증평군", "진천군", "괴산군", "음성군", "단양군"]),
        KoreaRegion(name: "충남", districts: ["전체", "천안시", "공주시", "보령시", "아산시", "서산시", "논산시", "계룡시", "당진시", "금산군", "부여군", "서천군", "청양군", "홍성군", "예산군", "태안군"]),
        KoreaRegion(name: "전북", districts: ["전체", "전주시", "군산시", "익산시", "정읍시", "남원시", "김제시", "완주군", "진안군", "무주군", "장수군", "임실군", "순창군", "고창군", "부안군"]),
        KoreaRegion(name: "전남", districts: ["전체", "목포시", "여수시", "순천시", "나주시", "광양시", "담양군", "곡성군", "구례군", "고흥군", "보성군", "화순군", "장흥군", "강진군", "해남군", "영암군", "무안군", "함평군", "영광군", "장성군", "완도군", "진도군", "신안군"]),
        KoreaRegion(name: "경북", districts: ["전체", "포항시", "경주시", "김천시", "안동시", "구미시", "영주시", "영천시", "상주시", "문경시", "경산시", "의성군", "청송군", "영양군", "영덕군", "청도군", "고령군", "성주군", "칠곡군", "예천군", "봉화군", "울진군", "울릉군"]),
        KoreaRegion(name: "경남", districts: ["전체", "창원시", "진주시", "통영시", "사천시", "김해시", "밀양시", "거제시", "양산시", "의령군", "함안군", "창녕군", "고성군", "남해군", "하동군", "산청군", "함양군", "거창군", "합천군"]),
        KoreaRegion(name: "제주", districts: ["전체", "제주시", "서귀포시"])
    ]

    static func districts(of cityName: String) -> [String] {
        cities.first(where: { $0.name == cityName })?.districts ?? ["전체"]
    }
}
```

- [ ] **Step 3: 빌드 확인**

```bash
xcodebuild -scheme Bookiibookii -destination 'platform=iOS Simulator,name=iPhone 15' -quiet build 2>&1 | tail -5
```

- [ ] **Step 4: 커밋**

```bash
git add Bookiibookii/Features/Group/RegionData.swift
git commit -m "feat: 17개 시·도 지역 데이터 추가"
```

---

## Phase 3: ViewModel

### Task 3.1: GroupViewModel 기본 구조

**Files:**
- Create: `Bookiibookii/Features/Group/GroupViewModel.swift`

- [ ] **Step 1: 파일 생성**

`Bookiibookii/Features/Group/GroupViewModel.swift`:

```swift
import Foundation
import SwiftUI

@MainActor
final class GroupViewModel: ObservableObject {
    // MARK: - 필터 상태 (빈 컬렉션 == 전체)
    @Published var groupTypes: Set<GroupTypeFilter> = []
    @Published var categories: Set<CategoryFilter> = []
    @Published var region: RegionSelection = .all
    @Published var sort: GroupSort = .recommend

    // MARK: - 리스트 상태
    @Published private(set) var items: [GroupItemDto] = []
    @Published private(set) var page: Int = 0
    @Published private(set) var hasNext: Bool = false
    @Published private(set) var phase: Phase = .idle

    @Published var toast: String? = nil

    enum Phase { case idle, loading, loadingMore, refreshing, failed }

    private let service: GroupService
    private let pageSize: Int = 20

    init(service: GroupService) {
        self.service = service
    }

    // MARK: - 엔트리 포인트

    /// 화면 최초 등장 시 호출. 이미 로드된 상태면 무시.
    func onAppear() async {
        guard items.isEmpty && phase == .idle else { return }
        await loadFirstPage(phase: .loading)
    }

    /// Pull-to-refresh
    func refresh() async {
        await loadFirstPage(phase: .refreshing)
    }

    /// 필터/정렬 변경 시 내부 호출
    private func reload() async {
        await loadFirstPage(phase: .loading)
    }

    /// 무한 스크롤 (마지막 셀 `.onAppear`에서 호출)
    func loadNextPage() async {
        guard hasNext, phase == .idle else { return }
        phase = .loadingMore
        do {
            let result = try await fetch(page: page + 1)
            items.append(contentsOf: result.groupList ?? [])
            page = result.currentPage
            hasNext = result.hasNext
            phase = .idle
        } catch {
            phase = .failed
            toast = "추가 로드 실패"
        }
    }

    // MARK: - 필터/정렬 적용

    func applyGroupTypes(_ next: Set<GroupTypeFilter>) async {
        guard next != groupTypes else { return }
        groupTypes = next
        await reload()
    }

    func applyCategories(_ next: Set<CategoryFilter>) async {
        guard next != categories else { return }
        categories = next
        await reload()
    }

    func applyRegion(_ next: RegionSelection) async {
        guard next != region else { return }
        region = next
        await reload()
    }

    func changeSort(_ next: GroupSort) async {
        guard next != sort else { return }
        sort = next
        await reload()
    }

    // MARK: - placeholder

    func showComingSoon(_ label: String = "준비 중입니다") {
        toast = label
    }

    // MARK: - 내부 로드 로직

    private func loadFirstPage(phase startPhase: Phase) async {
        phase = startPhase
        do {
            let result = try await fetch(page: 0)
            items = result.groupList ?? []
            page = result.currentPage
            hasNext = result.hasNext
            phase = .idle
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet {
            phase = .failed
            toast = "네트워크 연결을 확인해주세요"
        } catch {
            phase = .failed
            toast = "불러오기 실패"
        }
    }

    private func fetch(page: Int) async throws -> GroupPageResult {
        try await service.fetchGroups(
            groupTypes: queryGroupTypes(),
            tradeTypes: queryTradeTypes(),
            meetPlace: region.serverMeetPlace,
            categories: queryCategories(),
            sort: sort,
            page: page,
            size: pageSize
        )
    }

    // MARK: - 쿼리 빌드 (안드로이드 loadGroupData 그대로)

    private func queryGroupTypes() -> [String]? {
        if groupTypes.isEmpty { return nil }
        var types = Set<String>()
        if groupTypes.contains(.together) { types.insert("TOGETHER") }
        if groupTypes.contains(.delivery) || groupTypes.contains(.direct) { types.insert("RELAY") }
        return types.isEmpty ? nil : Array(types)
    }

    private func queryTradeTypes() -> [String]? {
        var types: [String] = []
        if groupTypes.contains(.delivery) { types.append("DELIVERY") }
        if groupTypes.contains(.direct)   { types.append("DIRECT") }
        return types.isEmpty ? nil : types
    }

    private func queryCategories() -> [String]? {
        categories.isEmpty ? nil : categories.map(\.rawValue)
    }
}
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -scheme Bookiibookii -destination 'platform=iOS Simulator,name=iPhone 15' -quiet build 2>&1 | tail -5
```
예상: `BUILD SUCCEEDED`

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Features/Group/GroupViewModel.swift
git commit -m "feat: GroupViewModel — 필터/정렬/페이징 상태 기계"
```

---

## Phase 4: 뷰 컴포넌트

### Task 4.1: GroupCard

**Files:**
- Create: `Bookiibookii/Features/Group/GroupCard.swift`

- [ ] **Step 1: 파일 생성**

`Bookiibookii/Features/Group/GroupCard.swift`:

```swift
import SwiftUI
import Kingfisher

struct GroupCard: View {
    let item: GroupItemDto
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topRow
            profileRow
                .padding(.top, 12)
            if !displayTags.isEmpty {
                tagRow
                    .padding(.top, 12)
            }
        }
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    // MARK: - 상단 (표지 + 정보)

    private var topRow: some View {
        HStack(alignment: .top, spacing: 12) {
            cover
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    titleAndAuthor
                    Spacer(minLength: 8)
                    statusBadge
                }
                metaRow
                    .padding(.top, 12)
            }
        }
    }

    private var cover: some View {
        KFImage(item.bookImage.flatMap(URL.init(string:)))
            .placeholder { Color("grey300") }
            .retry(maxCount: 2)
            .cancelOnDisappear(true)
            .resizable()
            .scaledToFill()
            .frame(width: 74, height: 94)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var titleAndAuthor: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.pretendard(size: 14, weight: .regular))
                .foregroundColor(Color("black"))
                .lineLimit(1)
                .truncationMode(.tail)

            HStack(spacing: 4) {
                Text(item.displayAuthor)
                    .font(.pretendard(size: 11))
                    .foregroundColor(Color("grey500"))
                    .lineLimit(1)
                if let genre = item.displayGenre {
                    Text(genre)
                        .font(.pretendard(size: 11))
                        .foregroundColor(Color("grey500"))
                        .lineLimit(1)
                }
            }
        }
    }

    private var statusBadge: some View {
        let (bg, text): (Color, String) = item.isTogether
            ? (Color("grey900"), "함께읽기(\(item.maxCapacity))")
            : (Color("main200"), item.badgeText)
        return Text(text)
            .font(.pretendard(size: 11, weight: .medium))
            .foregroundColor(Color("white"))
            .padding(.horizontal, 8)
            .frame(height: 23)
            .background(Capsule().fill(bg))
    }

    private var metaRow: some View {
        HStack(spacing: 4) {
            Image("ic_cal")
                .renderingMode(.template)
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundColor(Color("grey500"))
            Text("\(item.readingPeriod)일")
                .font(.pretendard(size: 11))
                .foregroundColor(Color("grey500"))

            Rectangle()
                .fill(Color("grey400"))
                .frame(width: 1, height: 10)
                .padding(.horizontal, 2)

            Image("ic_group")
                .renderingMode(.template)
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundColor(Color("grey500"))
            Text("\(item.currentCount)명 대기")
                .font(.pretendard(size: 11))
                .foregroundColor(Color("grey500"))

            if item.isHot { hotBadge }
        }
    }

    private var hotBadge: some View {
        Text("HOT")
            .font(.pretendard(size: 11, weight: .medium))
            .foregroundColor(Color("main200"))
            .padding(.horizontal, 6)
            .frame(height: 16)
            .background(Capsule().fill(Color("main100")))
    }

    // MARK: - 프로필 + 날짜

    private var profileRow: some View {
        HStack(spacing: 4) {
            KFImage(item.hostProfileImageUrl.flatMap(URL.init(string:)))
                .placeholder { Image("img_profile_default").resizable() }
                .retry(maxCount: 2)
                .cancelOnDisappear(true)
                .resizable()
                .scaledToFill()
                .frame(width: 20, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(item.displayNickname)
                .font(.pretendard(size: 12))
                .foregroundColor(Color("grey700"))
                .padding(.leading, 4)

            Text(item.displayDate)
                .font(.pretendard(size: 11))
                .foregroundColor(Color("grey400"))
                .padding(.leading, 4)

            Spacer()
        }
    }

    // MARK: - 태그

    private var displayTags: [String] {
        var all: [String] = []
        if let c = item.customTag, !c.isEmpty { all.append("#\(c)") }
        (item.tags ?? []).forEach { all.append(GroupTagMapper.koreanTag($0)) }
        return all
    }

    private var tagRow: some View {
        let all = displayTags
        let visible = Array(all.prefix(3))
        let extra = all.count - visible.count
        return HStack(spacing: 8) {
            ForEach(visible.indices, id: \.self) { idx in
                tagChip(visible[idx])
            }
            if extra > 0 {
                tagChip("+\(extra)")
            }
            Spacer()
        }
    }

    private func tagChip(_ text: String) -> some View {
        Text(text)
            .font(.pretendard(size: 11, weight: .medium))
            .foregroundColor(Color("sub200"))
            .padding(.horizontal, 10)
            .frame(height: 23)
            .background(Capsule().fill(Color("sub100")))
    }
}

#Preview("모집 중 + RELAY") {
    GroupCard(
        item: GroupItemDto(
            groupId: 1, title: "괴테는 모든 것을 말했다",
            author: "한강", genre: "소설", bookImage: nil,
            hostProfileImageUrl: nil, hostNickname: "noshel",
            tags: ["MEMO", "INSIGHT", "CLEAN", "SLOW", "SCI_IT"],
            groupStatus: "RECRUITING", currentCount: 2, maxCapacity: 4,
            readingPeriod: 7, customTag: nil,
            groupType: "RELAY", tradeType: "DELIVERY",
            startDate: "2025-12-16", isHot: true, pictureBadge: "마포구"
        ),
        onTap: {}
    )
    .padding()
    .background(Color("grey100"))
}

#Preview("함께읽기 TOGETHER") {
    GroupCard(
        item: GroupItemDto(
            groupId: 2, title: "소년이 온다",
            author: "한강", genre: "소설", bookImage: nil,
            hostProfileImageUrl: nil, hostNickname: "noshel",
            tags: ["MEMO"],
            groupStatus: "RECRUITING", currentCount: 2, maxCapacity: 3,
            readingPeriod: 7, customTag: "커스텀",
            groupType: "TOGETHER", tradeType: nil,
            startDate: "2025-12-16", isHot: false, pictureBadge: nil
        ),
        onTap: {}
    )
    .padding()
    .background(Color("grey100"))
}
```

- [ ] **Step 2: 프리뷰 확인**

Xcode에서 프리뷰 띄워 두 variant 모두 디자인과 일치하는지 확인. 디자인 스펙:
- 모집 중 + RELAY: 오른쪽 상단 orange `"마포구"` 뱃지, 메타 row 끝에 pale peach `HOT` 뱃지
- TOGETHER: 오른쪽 상단 dark `"함께읽기(3)"` 뱃지, 태그 첫 칩 `"#커스텀"`

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Features/Group/GroupCard.swift
git commit -m "feat: GroupCard — 표지/뱃지/메타/태그 셀"
```

---

### Task 4.2: GroupFabMenu

**Files:**
- Create: `Bookiibookii/Features/Group/GroupFabMenu.swift`

- [ ] **Step 1: 파일 생성**

`Bookiibookii/Features/Group/GroupFabMenu.swift`:

```swift
import SwiftUI

struct GroupFabMenu: View {
    @Binding var isOpen: Bool
    let onTapTogether: () -> Void
    let onTapRelay: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            if isOpen {
                optionPill(icon: "ic_fab_together", title: "함께읽기") {
                    onTapTogether()
                    isOpen = false
                }
                optionPill(icon: "ic_fab_relay", title: "이어읽기") {
                    onTapRelay()
                    isOpen = false
                }
            }
            fabButton
        }
    }

    private func optionPill(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundColor(Color("grey900"))
                Text(title)
                    .font(.pretendard(size: 14, weight: .medium))
                    .foregroundColor(Color("grey900"))
            }
            .frame(width: 108, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("white"))
                    .shadow(color: Color("black").opacity(0.08), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom)),
            removal: .opacity
        ))
    }

    private var fabButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.25)) { isOpen.toggle() }
        } label: {
            Image(isOpen ? "ic_fab_close" : "ic_fab_plus")
                .renderingMode(.template)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(Color("white"))
                .frame(width: 70, height: 70)
                .background(Circle().fill(Color("grey900")))
        }
        .buttonStyle(.plain)
    }
}

#Preview("닫힘") {
    struct Host: View {
        @State private var open = false
        var body: some View {
            ZStack(alignment: .bottomTrailing) {
                Color("grey100").ignoresSafeArea()
                GroupFabMenu(isOpen: $open, onTapTogether: {}, onTapRelay: {})
                    .padding(.trailing, 24).padding(.bottom, 16)
            }
        }
    }
    return Host()
}

#Preview("열림") {
    struct Host: View {
        @State private var open = true
        var body: some View {
            ZStack(alignment: .bottomTrailing) {
                Color("grey100").ignoresSafeArea()
                GroupFabMenu(isOpen: $open, onTapTogether: {}, onTapRelay: {})
                    .padding(.trailing, 24).padding(.bottom, 16)
            }
        }
    }
    return Host()
}
```

- [ ] **Step 2: 프리뷰 확인**

Xcode 프리뷰에서 두 상태 확인. FAB 탭 시 + → × 전환, 위쪽에 "함께읽기"/"이어읽기" pill 등장.

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Features/Group/GroupFabMenu.swift
git commit -m "feat: GroupFabMenu — FAB + 확장 메뉴"
```

---

### Task 4.3: GroupFilterSheet (그룹유형·분야별 공용)

**Files:**
- Create: `Bookiibookii/Features/Group/GroupFilterSheet.swift`

- [ ] **Step 1: 파일 생성**

`Bookiibookii/Features/Group/GroupFilterSheet.swift`:

```swift
import SwiftUI

/// 그룹유형·분야별 공용 바텀시트.
/// 안드로이드 `FilterBottomSheetFragment` 포팅.
struct GroupFilterSheet<Item: CaseIterable & Hashable & Identifiable>: View
where Item.AllCases == [Item] {
    enum Kind {
        case groupType   // 함께읽기 / 직접교환 / 택배교환 (전체 후 구분선)
        case category    // 9개 장르 flow layout
    }

    let kind: Kind
    let title: String
    let items: [Item]
    let itemDisplay: (Item) -> String
    let preSelected: Set<Item>
    let onConfirm: (Set<Item>) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selection: Set<Item>

    init(
        kind: Kind,
        title: String,
        items: [Item],
        itemDisplay: @escaping (Item) -> String,
        preSelected: Set<Item>,
        onConfirm: @escaping (Set<Item>) -> Void
    ) {
        self.kind = kind
        self.title = title
        self.items = items
        self.itemDisplay = itemDisplay
        self.preSelected = preSelected
        self.onConfirm = onConfirm
        _selection = State(initialValue: preSelected)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 24)
                .padding(.top, 20)

            chipArea
                .padding(.horizontal, 24)
                .padding(.top, 24)

            Spacer(minLength: 0)

            actionRow
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .background(Color("white"))
    }

    // MARK: - 헤더

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.pretendard(size: 20, weight: .medium))
                .foregroundColor(Color("grey900"))
            summaryText
            Spacer()
        }
    }

    private var summaryText: some View {
        let list = items.filter { selection.contains($0) }.map(itemDisplay)
        return Group {
            if list.isEmpty {
                Text("전체")
                    .font(.pretendard(size: 14, weight: .medium))
                    .foregroundColor(Color("main200"))
            } else if list.count <= 3 {
                Text(list.joined(separator: " · "))
                    .font(.pretendard(size: 14, weight: .medium))
                    .foregroundColor(Color("main200"))
            } else {
                let first3 = list.prefix(3).joined(separator: " · ")
                (Text(first3).foregroundColor(Color("main200"))
                 + Text(" 외 \(list.count - 3)개").foregroundColor(Color("grey500")))
                    .font(.pretendard(size: 14, weight: .medium))
            }
        }
    }

    // MARK: - 칩 영역

    @ViewBuilder
    private var chipArea: some View {
        switch kind {
        case .groupType: groupTypeChips
        case .category:  categoryChips
        }
    }

    /// 가로 배열: [전체] | 세로 divider | [옵션들...]
    private var groupTypeChips: some View {
        HStack(spacing: 8) {
            chip(text: "전체", isSelected: selection.isEmpty) {
                selection.removeAll()
            }
            Rectangle()
                .fill(Color("grey300"))
                .frame(width: 1, height: 28)
            ForEach(items) { item in
                chip(text: itemDisplay(item), isSelected: selection.contains(item)) {
                    toggle(item)
                }
            }
            Spacer()
        }
    }

    /// 분야별: [전체] + 9개 장르를 FlowLayout으로 자동 줄바꿈
    private var categoryChips: some View {
        GroupFilterFlowLayout(spacing: 8, lineSpacing: 8) {
            chip(text: "전체", isSelected: selection.isEmpty) {
                selection.removeAll()
            }
            ForEach(items) { item in
                chip(text: itemDisplay(item), isSelected: selection.contains(item)) {
                    toggle(item)
                }
            }
        }
    }

    private func toggle(_ item: Item) {
        if selection.contains(item) {
            selection.remove(item)
        } else {
            selection.insert(item)
        }
    }

    // MARK: - 칩 공통

    private func chip(text: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.pretendard(size: 13, weight: .medium))
                .foregroundColor(isSelected ? Color("main200") : Color("grey700"))
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(
                    Capsule().fill(isSelected ? Color("main100") : Color("white"))
                )
                .overlay(
                    Capsule().stroke(
                        isSelected ? Color("main200") : Color("grey200"),
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 하단 버튼

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button {
                dismiss()
            } label: {
                Text("취소")
                    .font(.pretendard(size: 16, weight: .medium))
                    .foregroundColor(Color("grey700"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color("grey200"), lineWidth: 1)
                    )
            }

            Button {
                onConfirm(selection)
                dismiss()
            } label: {
                Text("확인")
                    .font(.pretendard(size: 16, weight: .medium))
                    .foregroundColor(Color("white"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color("grey900")))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FlowLayout (iOS 16+)

struct GroupFilterFlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalHeight = y + rowHeight
        }
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview("그룹 유형 - 2개 선택") {
    GroupFilterSheet<GroupTypeFilter>(
        kind: .groupType,
        title: "그룹 유형",
        items: GroupTypeFilter.allCases,
        itemDisplay: { $0.displayName },
        preSelected: [.together, .direct],
        onConfirm: { _ in }
    )
    .frame(height: 240)
}

#Preview("분야별 - 2개 선택") {
    GroupFilterSheet<CategoryFilter>(
        kind: .category,
        title: "분야별",
        items: CategoryFilter.allCases,
        itemDisplay: { $0.displayName },
        preSelected: [.sciIt, .selfDev],
        onConfirm: { _ in }
    )
    .frame(height: 344)
}
```

- [ ] **Step 2: 프리뷰 확인**

두 프리뷰 모두 확인:
- 그룹 유형: `"전체 | 함께 읽기 · 직접 교환"` 요약, 함께/직접 칩 orange 선택 스타일
- 분야별: `"과학/IT · 자기계발"` 요약, flow 레이아웃으로 2~3줄 자동 줄바꿈

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Features/Group/GroupFilterSheet.swift
git commit -m "feat: GroupFilterSheet — 그룹유형/분야별 공용 바텀시트"
```

---

### Task 4.4: GroupRegionSheet

**Files:**
- Create: `Bookiibookii/Features/Group/GroupRegionSheet.swift`

- [ ] **Step 1: 파일 생성**

`Bookiibookii/Features/Group/GroupRegionSheet.swift`:

```swift
import SwiftUI

/// 지역별 바텀시트 — 좌측 시·도 리스트 + 우측 구·군 칩.
/// 안드로이드 `GrpRegionBottomSheetFragment` 포팅.
struct GroupRegionSheet: View {
    let preSelected: RegionSelection
    let onConfirm: (RegionSelection) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentCity: String
    @State private var selectedDistricts: [String]
    @State private var toast: String? = nil

    init(preSelected: RegionSelection, onConfirm: @escaping (RegionSelection) -> Void) {
        self.preSelected = preSelected
        self.onConfirm = onConfirm
        let initialCity = preSelected.isAll ? "서울" : preSelected.city
        _currentCity = State(initialValue: initialCity)
        _selectedDistricts = State(initialValue: preSelected.districts)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 24)
                .padding(.top, 20)

            twoColumnBody
                .padding(.top, 20)

            actionRow
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .background(Color("white"))
        .toast($toast)
    }

    // MARK: - 헤더

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("지역")
                .font(.pretendard(size: 20, weight: .medium))
                .foregroundColor(Color("grey900"))
            summaryText
            Spacer()
        }
    }

    private var summaryText: some View {
        Group {
            if selectedDistricts.isEmpty {
                Text("전체")
                    .foregroundColor(Color("main200"))
            } else {
                Text(selectedDistricts.joined(separator: " · "))
                    .foregroundColor(Color("main200"))
            }
        }
        .font(.pretendard(size: 14, weight: .medium))
    }

    // MARK: - 본문 (좌: 시·도 / 우: 구·군)

    private var twoColumnBody: some View {
        HStack(alignment: .top, spacing: 0) {
            cityList
                .frame(width: 72)
            districtGrid
                .padding(.leading, 16)
                .padding(.trailing, 24)
        }
        .frame(height: 220)
    }

    private var cityList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(RegionData.cities) { city in
                    cityRow(city)
                }
            }
        }
    }

    private func cityRow(_ city: KoreaRegion) -> some View {
        let isSelected = city.name == currentCity
        return Button {
            guard currentCity != city.name else { return }
            currentCity = city.name
            selectedDistricts.removeAll()
        } label: {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(isSelected ? Color("main200") : Color.clear)
                    .frame(width: 3, height: 24)
                Text(city.name)
                    .font(.pretendard(size: 14, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? Color("grey900") : Color("grey500"))
                Spacer()
            }
            .frame(height: 36)
        }
        .buttonStyle(.plain)
    }

    private var districtGrid: some View {
        ScrollView(showsIndicators: false) {
            GroupFilterFlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(RegionData.districts(of: currentCity), id: \.self) { district in
                    districtChip(district)
                }
            }
        }
    }

    private func districtChip(_ district: String) -> some View {
        let isAll = district == "전체"
        let isSelected: Bool = isAll ? selectedDistricts.isEmpty : selectedDistricts.contains(district)
        return Button {
            handleTap(district)
        } label: {
            Text(district)
                .font(.pretendard(size: 13, weight: .medium))
                .foregroundColor(isSelected ? Color("main200") : Color("grey700"))
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(
                    Capsule().fill(isSelected ? Color("main100") : Color("white"))
                )
                .overlay(
                    Capsule().stroke(
                        isSelected ? Color("main200") : Color("grey200"),
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
    }

    private func handleTap(_ district: String) {
        if district == "전체" {
            selectedDistricts.removeAll()
            return
        }
        if selectedDistricts.contains(district) {
            selectedDistricts.removeAll { $0 == district }
        } else {
            if selectedDistricts.count >= 3 {
                toast = "최대 3개까지 선택 가능합니다."
                return
            }
            selectedDistricts.append(district)
        }
    }

    // MARK: - 하단 버튼

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button {
                dismiss()
            } label: {
                Text("취소")
                    .font(.pretendard(size: 16, weight: .medium))
                    .foregroundColor(Color("grey700"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color("grey200"), lineWidth: 1)
                    )
            }

            Button {
                onConfirm(RegionSelection(city: currentCity, districts: selectedDistricts))
                dismiss()
            } label: {
                Text("확인")
                    .font(.pretendard(size: 16, weight: .medium))
                    .foregroundColor(Color("white"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color("grey900")))
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview("초기 — 서울") {
    GroupRegionSheet(preSelected: .all, onConfirm: { _ in })
        .frame(height: 346)
}

#Preview("서울 강남·서초 선택") {
    GroupRegionSheet(
        preSelected: RegionSelection(city: "서울", districts: ["강남구", "서초구"]),
        onConfirm: { _ in }
    )
    .frame(height: 346)
}
```

- [ ] **Step 2: 프리뷰 확인**

- 기본 프리뷰: 왼쪽 "서울" 선택됨(orange bar), 오른쪽 "전체" 칩 orange
- 프리뷰 2: "강남구", "서초구" 칩 orange, 요약 `"강남구 · 서초구"`

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Features/Group/GroupRegionSheet.swift
git commit -m "feat: GroupRegionSheet — 지역별 2열 바텀시트"
```

---

## Phase 5: 메인 뷰 + 통합

### Task 5.1: GroupView (메인 조립)

**Files:**
- Modify: `Bookiibookii/Features/Group/GroupView.swift` (placeholder → 전체 구현)

- [ ] **Step 1: 파일 교체**

`Bookiibookii/Features/Group/GroupView.swift` 전체 교체:

```swift
import SwiftUI

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
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                filterChipsRow
                    .padding(.top, 16)

                sortRow
                    .padding(.horizontal, 24)
                    .padding(.top, 32)

                listSection
                    .padding(.top, 12)
            }

            if isFabOpen {
                Color("black").opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.25)) { isFabOpen = false }
                    }
                    .transition(.opacity)
            }

            GroupFabMenu(
                isOpen: $isFabOpen,
                onTapTogether: { viewModel.showComingSoon("그룹 만들기는 준비 중입니다") },
                onTapRelay:    { viewModel.showComingSoon("그룹 만들기는 준비 중입니다") }
            )
            .padding(.trailing, 24)
            .padding(.bottom, 16)
        }
        .sheet(item: $activeSheet) { sheet in
            sheetContent(for: sheet)
        }
        .task { await viewModel.onAppear() }
        .toast($viewModel.toast)
    }

    // MARK: - 헤더

    private var header: some View {
        HStack {
            Text("그룹")
                .font(.pretendard(size: 24, weight: .bold))
                .foregroundColor(Color("grey700"))
            Spacer()
            Button {
                viewModel.showComingSoon("검색은 준비 중입니다")
            } label: {
                Image("ic_search")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color("grey900"))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle().stroke(Color("grey200"), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 필터 칩 Row

    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(
                    label: groupTypeChipLabel,
                    isActive: !viewModel.groupTypes.isEmpty,
                    action: { activeSheet = .groupType }
                )
                filterChip(
                    label: viewModel.region.chipLabel,
                    isActive: !viewModel.region.isAll,
                    action: { activeSheet = .region }
                )
                filterChip(
                    label: categoryChipLabel,
                    isActive: !viewModel.categories.isEmpty,
                    action: { activeSheet = .category }
                )
            }
            .padding(.horizontal, 24)
        }
    }

    private var groupTypeChipLabel: String {
        if viewModel.groupTypes.isEmpty { return "그룹 유형" }
        return chipSummary(viewModel.groupTypes.map(\.displayName))
    }

    private var categoryChipLabel: String {
        if viewModel.categories.isEmpty { return "분야별" }
        return chipSummary(viewModel.categories.map(\.displayName))
    }

    /// 최대 3개까지 · 구분, 그 이상은 "외 N개"
    private func chipSummary(_ items: [String]) -> String {
        let sorted = items   // 순서는 호출자 책임
        if sorted.count <= 3 { return sorted.joined(separator: " · ") }
        let head = sorted.prefix(3).joined(separator: " · ")
        return "\(head) 외 \(sorted.count - 3)개"
    }

    private func filterChip(label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.pretendard(size: 13, weight: isActive ? .medium : .regular))
                .foregroundColor(isActive ? Color("white") : Color("grey500"))
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(
                    Capsule().fill(isActive ? Color("grey900") : Color("white"))
                )
                .overlay(
                    Capsule().stroke(
                        isActive ? Color.clear : Color("grey200"),
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 정렬 Row

    private var sortRow: some View {
        HStack(spacing: 4) {
            Spacer()
            sortItem(.recommend)
            sortDivider
            sortItem(.latest)
            sortDivider
            sortItem(.popular)
        }
    }

    private func sortItem(_ sort: GroupSort) -> some View {
        let isActive = viewModel.sort == sort
        return Button {
            Task { await viewModel.changeSort(sort) }
        } label: {
            Text(sort.displayName)
                .font(.pretendard(size: 14, weight: isActive ? .medium : .regular))
                .foregroundColor(isActive ? Color("main200") : Color("grey500"))
        }
        .buttonStyle(.plain)
    }

    private var sortDivider: some View {
        Text("|")
            .font(.pretendard(size: 14))
            .foregroundColor(Color("grey400"))
            .padding(.horizontal, 4)
    }

    // MARK: - 리스트

    @ViewBuilder
    private var listSection: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                if viewModel.items.isEmpty {
                    emptyOrLoadingState
                        .padding(.top, 80)
                } else {
                    ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { idx, item in
                        GroupCard(item: item) {
                            viewModel.showComingSoon("그룹 상세는 준비 중입니다")
                        }
                        .onAppear {
                            if idx == viewModel.items.count - 1 {
                                Task { await viewModel.loadNextPage() }
                            }
                        }
                    }
                    if viewModel.phase == .loadingMore {
                        ProgressView().padding(.vertical, 16)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 80)
        }
        .refreshable { await viewModel.refresh() }
    }

    @ViewBuilder
    private var emptyOrLoadingState: some View {
        switch viewModel.phase {
        case .loading, .refreshing:
            ProgressView()
        case .failed:
            VStack(spacing: 16) {
                Text("불러오기 실패")
                    .font(.pretendard(size: 14))
                    .foregroundColor(Color("grey500"))
                Button("다시 시도") {
                    Task { await viewModel.refresh() }
                }
                .font(.pretendard(size: 14, weight: .medium))
                .foregroundColor(Color("main200"))
            }
        default:
            Text("조건에 맞는 그룹이 없어요")
                .font(.pretendard(size: 14))
                .foregroundColor(Color("grey500"))
        }
    }

    // MARK: - 바텀시트 분기

    @ViewBuilder
    private func sheetContent(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .groupType:
            GroupFilterSheet<GroupTypeFilter>(
                kind: .groupType,
                title: "그룹 유형",
                items: GroupTypeFilter.allCases,
                itemDisplay: { $0.displayName },
                preSelected: viewModel.groupTypes,
                onConfirm: { next in
                    Task { await viewModel.applyGroupTypes(next) }
                }
            )
            .presentationDetents([.height(260)])
            .presentationDragIndicator(.visible)

        case .category:
            GroupFilterSheet<CategoryFilter>(
                kind: .category,
                title: "분야별",
                items: CategoryFilter.allCases,
                itemDisplay: { $0.displayName },
                preSelected: viewModel.categories,
                onConfirm: { next in
                    Task { await viewModel.applyCategories(next) }
                }
            )
            .presentationDetents([.height(360)])
            .presentationDragIndicator(.visible)

        case .region:
            GroupRegionSheet(
                preSelected: viewModel.region,
                onConfirm: { next in
                    Task { await viewModel.applyRegion(next) }
                }
            )
            .presentationDetents([.height(380)])
            .presentationDragIndicator(.visible)
        }
    }
}
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -scheme Bookiibookii -destination 'platform=iOS Simulator,name=iPhone 15' -quiet build 2>&1 | tail -5
```
예상: `BUILD SUCCEEDED`

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Features/Group/GroupView.swift
git commit -m "feat: GroupView — 메인 화면 조립 (헤더/칩/정렬/리스트/FAB)"
```

---

### Task 5.2: BookiiTabCase 수정

**Files:**
- Modify: `Bookiibookii/Common/Tabbar/BookiiTabCase.swift:36`

- [ ] **Step 1: contentView 수정**

`Bookiibookii/Common/Tabbar/BookiiTabCase.swift`의 `contentView(container:)` 함수에서 `.group` 케이스만 수정:

변경 전:
```swift
case .group: GroupView()
```

변경 후:
```swift
case .group: GroupView(groupService: container.api.group)
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -scheme Bookiibookii -destination 'platform=iOS Simulator,name=iPhone 15' -quiet build 2>&1 | tail -5
```
예상: `BUILD SUCCEEDED`

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Common/Tabbar/BookiiTabCase.swift
git commit -m "feat: BookiiTabCase — GroupView에 GroupService 주입"
```

---

## Phase 6: 수동 검증

### Task 6.1: 시뮬레이터 빌드 + 설치

**Files:** (없음)

- [ ] **Step 1: 전체 빌드**

```bash
xcodebuild -scheme Bookiibookii -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | tail -20
```
예상: `BUILD SUCCEEDED`

- [ ] **Step 2: 시뮬레이터 실행**

Xcode의 iPhone 15 시뮬레이터에서 앱 실행 (Cmd+R). 로그인 완료 후 하단 탭바에서 `그룹` 탭으로 이동.

---

### Task 6.2: 수동 체크리스트 (스펙 §12)

각 항목 확인 후 체크. 기대 동작과 다르면 이슈 기록 후 Task 5.x 또는 해당 작업으로 돌아가 수정.

- [ ] **1. 앱 시작 → 홈 → 그룹 탭**: 상단에 "그룹" 헤더, 필터 칩 3개(그룹 유형/지역별/분야별), 정렬 row(추천순 | 최신순 | 인기순), 첫 페이지 20개 카드 표시, 우하단 FAB 표시
- [ ] **2. 그룹 탭 → 다른 탭 → 돌아옴**: 재페칭 없이 이전 리스트 유지
- [ ] **3. 맨 아래 스크롤**: 자동 추가 로드 (spinner 표시 후 카드 추가). 마지막 페이지(`hasNext=false`)면 추가 로드 없이 정지
- [ ] **4. Pull-to-refresh**: 상단 당기면 첫 페이지부터 다시 로드
- [ ] **5. 그룹유형 바텀시트에서 `함께 읽기`만 선택 → 확인**: 리스트가 TOGETHER 카드만으로 필터됨. 필터 칩이 "함께 읽기" 텍스트로 grey900 bg 활성화
- [ ] **6. 그룹유형 바텀시트에서 `택배 교환` + `직접 교환` → 확인**: RELAY 카드만 표시, 네트워크 요청 쿼리에 `tradeTypes=DELIVERY&tradeTypes=DIRECT` 포함 (Xcode 네트워크 로그 확인)
- [ ] **7. 지역 바텀시트에서 `서울` 선택 후 4개째 구 선택**: `"최대 3개까지 선택 가능합니다."` 토스트, 체크 상태 되돌림
- [ ] **8. 지역 바텀시트 `서울` 선택 + 구 선택 안 함 → 확인**: 필터 칩 "서울", 요청 `meetPlace=서울`
- [ ] **9. 분야별에서 `과학/IT` + `자기계발` → 확인**: 요약 `"과학/IT · 자기계발"`, 필터 칩에도 동일 텍스트
- [ ] **10. 정렬 `최신순` 탭**: 리스트 재로드, 활성 색 `main200`
- [ ] **11. 카드 탭**: 토스트 `"그룹 상세는 준비 중입니다"`
- [ ] **12. FAB 탭**: 확장 메뉴 등장 + 딤 배경. 함께읽기 탭 → 토스트 "그룹 만들기는 준비 중...". 딤 탭 → 닫힘
- [ ] **13. 돋보기 탭**: 토스트 "검색은 준비 중입니다"
- [ ] **14. (옵션) 비행기 모드 on 후 Pull-to-refresh**: 토스트 "네트워크 연결을 확인해주세요", 기존 리스트 유지

---

### Task 6.3: 최종 PR 준비

**Files:** (없음)

- [ ] **Step 1: 커밋 내역 확인**

```bash
git log --oneline main..HEAD
```
예상: 0.x, 1.x, 2.x, 3.x, 4.x, 5.x 태스크별 커밋 시퀀스가 보임

- [ ] **Step 2: 원격 브랜치 푸시**

```bash
git push -u origin feat/#12/group-main
```

- [ ] **Step 3: PR 생성**

```bash
gh pr create --title "그룹 메인 화면 구현 (#12)" --body "$(cat <<'EOF'
## Summary
- 그룹 탭 메인 화면 (목록 + 필터 3종 + 정렬 + 무한스크롤 + FAB)
- Kingfisher SPM 도입, Pretendard Variable 폰트 도입
- 필터 바텀시트 3종 (그룹유형·지역별·분야별)
- API 연동: `GET /api/groups` (쿼리는 안드로이드 `GroupFragment` 로직 포팅)
- 제외: 검색/생성/상세 화면은 토스트로 placeholder

## Test plan
- [ ] 그룹 탭 진입 시 첫 20개 로드
- [ ] 그룹유형 / 지역별 / 분야별 필터 조합 동작
- [ ] 지역: 서울 전체, 서울 강남·서초, 서울 4개 선택 차단
- [ ] 정렬 전환 3종
- [ ] 무한스크롤 + Pull-to-refresh
- [ ] FAB 확장 + 딤 탭 닫기
- [ ] 카드/검색/FAB 옵션 탭 → 토스트 "준비 중"

설계 문서: `docs/superpowers/specs/2026-04-22-group-main-design.md`
구현 계획: `docs/superpowers/plans/2026-04-22-group-main.md`

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```
