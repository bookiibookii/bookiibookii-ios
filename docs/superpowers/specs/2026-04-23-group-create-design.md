# 그룹 생성 기능 설계

## 개요

그룹 탭 FAB 메뉴에서 이어읽기(RELAY) / 함께읽기(TOGETHER) 타입을 선택하면 각각 전용 생성 폼으로 진입하는 기능. 생성 모드만 구현 (수정/삭제는 별도 작업).

## 아키텍처

### 레이아웃 방식

타입별 완전 분리 화면. 공통 ViewModel + 타입별 View 구조.

- `GroupCreateViewModel(groupType:)` — 책 검색, 태그, API 호출, 유효성 검사 등 공통 로직
- `GroupRelayCreateView` — 이어읽기 전용 폼
- `GroupTogetherCreateView` — 함께읽기 전용 폼

### 파일 구성

```
Features/Group/
├── GroupCreateViewModel.swift    (신규)
├── GroupRelayCreateView.swift    (신규)
└── GroupTogetherCreateView.swift (신규)

Data/API/
└── GroupService.swift            (확장) searchBooks + createGroup 추가

Data/Models/
└── GroupModels.swift             (확장) GroupCreateRequest, GroupTagRequest, BookItem 추가
```

### 네비게이션

`GroupView`의 FAB 콜백에서 `fullScreenCover`로 전환.

```
GroupFabMenu
  onTapRelay    → fullScreenCover → GroupRelayCreateView
  onTapTogether → fullScreenCover → GroupTogetherCreateView
```

## GroupCreateViewModel

### 상태 프로퍼티

| 프로퍼티 | 타입 | 설명 |
|---|---|---|
| `groupType` | `GroupType` (.relay / .together) | 생성 시 고정 |
| `searchQuery` | `String` | 도서 검색어 |
| `searchResults` | `[BookItem]` | 검색 결과 (드롭다운) |
| `selectedBook` | `BookItem?` | 선택된 도서 |
| `bookHave` | `Bool?` | 책 소유 여부 (RELAY 전용) |
| `tradeType` | `TradeType?` (.delivery / .direct) | 교환 방법 (RELAY 전용) |
| `preferRegion` | `String` | 지역 (RELAY + 직접교환 시) |
| `meetPlace` | `String` | 장소 (RELAY + 직접교환 시) |
| `maxCapacity` | `String` | 최대 인원 (TOGETHER 전용) |
| `startDate` | `Date?` | 시작 날짜 |
| `readingPeriod` | `String` | 독서 기간 (3~30) |
| `selectedTags` | `Set<ReadingTag>` | 선택된 태그 |
| `customTag` | `String` | 직접 입력 태그 |
| `groupComment` | `String` | 그룹 소개 |
| `isFormValid` | `Bool` (computed) | 제출 버튼 활성화 여부 |
| `phase` | `Phase` | idle / submitting / done / failed |
| `toast` | `String?` | 토스트 메시지 |

### enum 정의

```swift
enum GroupType { case relay, together }
enum TradeType { case delivery, direct }
enum ReadingTag: String, CaseIterable {
    case memo = "MEMO", postit = "POSTIT", clean = "CLEAN"
    case serious = "SERIOUS", lightFun = "LIGHT_FUN", insight = "INSIGHT"
    // displayName: #메모환영 / #포스트잇 / #깔끔 / #진지함 / #재미있게 / #인사이트
    // tagType: memo·postit·clean → "METHOD" / serious·lightFun·insight → "VIBE"
}
```

### 유효성 검사 (`isFormValid`)

**공통 조건:**
- `selectedBook != nil`
- `startDate != nil`
- `readingPeriod` → 정수 변환 가능, 3 이상 30 이하
- `selectedTags.isEmpty == false`
- `groupComment.trimmingCharacters(in: .whitespaces).isEmpty == false`

**RELAY 추가 조건:**
- `bookHave != nil`
- `tradeType != nil`
- `tradeType == .direct` 이면 `preferRegion`, `meetPlace` 모두 비어있지 않아야 함

**TOGETHER 추가 조건:**
- `maxCapacity` → 정수 변환 가능, 2 이상 8 이하

### 주요 메서드

- `searchBooks()` — 검색어 2자 이상 시 500ms 디바운스 후 `GET /api/books/search` 호출
- `selectBook(_ book: BookItem)` — 검색 결과에서 선택 시 호출, 드롭다운 닫기
- `submit()` — 유효성 통과 시 `POST /api/groups` 호출, 성공 시 dismiss
- `toggleTag(_ tag: ReadingTag)` — 태그 선택/해제

## GroupService 확장

### 책 검색

```
GET /api/books/search?keyword=&page=1&size=10
```

응답: `BookItem` 배열 (title, author, image, publisher, isbn13, category, categoryLabel, link)

### 그룹 생성

```
POST /api/groups
Body: GroupCreateRequest
```

```swift
struct GroupCreateRequest: Encodable {
    let isbn13: String
    let maxCapacity: Int
    let startDate: String          // "yyyy-MM-dd"
    let readingPeriod: Int
    let groupComment: String
    let customTag: String          // 없으면 ""
    let groupType: String          // "RELAY" | "TOGETHER"
    let tradeType: String          // "DELIVERY" | "DIRECT" | "NONE"
    let preferRegion: String       // 없으면 ""
    let meetPlace: String          // 없으면 ""
    let tags: [GroupTagRequest]
}

struct GroupTagRequest: Encodable {
    let type: String               // "METHOD" | "VIBE"
    let value: [String]
}
```

태그 타입 분류:
- METHOD: MEMO, POSTIT, CLEAN
- VIBE: SERIOUS, LIGHT_FUN, INSIGHT

## UI 상세

### 공통 섹션 (두 View 모두)

1. **네비게이션 바** — 뒤로가기 버튼 + 중앙 "그룹 만들기" 타이틀
2. **도서 검색** — 검색 필드 + 인라인 드롭다운 (안드로이드와 동일 패턴)
3. **시작 날짜** — 탭하면 DatePicker 시트, 내일 이후만 선택 가능
   - 안내 문구: "독서를 시작할 날짜를 선택해주세요 (익일부터 선택 가능)"
4. **독서 기간** — 숫자 입력 필드 (힌트: "3~30", 우측 단위: "일")
   - 안내 문구: "3일에서 30일 사이로 입력해주세요"
5. **독서 태그** — 6개 칩 (#메모환영 / #포스트잇 / #깔끔 / #진지함 / #재미있게 / #인사이트) + 직접 입력 필드
   - 선택 상태: 주황색 테두리 + 연주황 배경
   - 기본 태그 1개 이상 필수
6. **그룹 소개** — 멀티라인 텍스트 필드, 공백만 입력 시 무효
7. **그룹 만들기 버튼** — `isFormValid`에 따라 grey200(비활성) / grey900(활성) 전환

### RELAY 전용 섹션 (도서 검색 직후)

- **이 책의 실물을 가지고 계신가요?** — 네 / 아니오 버튼 (선택 시 주황색)
  - "아니오" 선택 시 구매 다이얼로그 표시 후 선택 초기화
  - 안내 문구: "그룹을 생성하려면 실물 책이 필요합니다"
- **교환 방법** — 택배 교환 / 직접 교환 버튼 (선택 시 주황색)
  - 직접 교환 선택 시: 내 지역(시/구) + 희망 교환 장소 입력 필드 노출

### TOGETHER 전용 섹션 (도서 검색 직후)

- **최대 인원** — 숫자 입력 필드 (힌트: "2~8", 우측 단위: "명")

## 에러 처리

- 네트워크 오류: toast "네트워크 오류가 발생했습니다"
- 서버 에러: 서버 메시지 toast 표시
- 생성 성공: toast "그룹 생성 완료되었습니다" 후 화면 dismiss

## 범위 외

- 그룹 수정 / 삭제 (별도 작업)
- 생성 후 상세 화면 이동 (그룹 상세 미구현)
