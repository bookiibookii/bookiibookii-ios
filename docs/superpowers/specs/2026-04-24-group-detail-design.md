# 그룹 세부 화면 설계

브랜치: `feat/#18/group-detail`  
날짜: 2026-04-24  
범위: 1차 PR — 그룹 상세 조회, 신청/취소, 호스트 신청자 관리, 그룹 삭제 (댓글 제외)

---

## 1. 목표

GroupView / GroupSearchView에서 GroupCard를 탭하면 그룹 세부 화면으로 진입한다.  
현재는 "준비 중" 토스트로 막혀 있는 진입점 두 곳을 실제 화면으로 연결한다.

---

## 2. API / 데이터 레이어

### 2-1. GroupModels.swift 추가

```
GroupDetailResponse        // isSuccess, code, message, result: GroupDetailDto
GroupDetailDto
  groupId, title, bookTitle, bookImage, author, category
  groupStatus              // RECRUITING | MATCHED | COMPLETED
  buttonStatus             // APPLY | CANCEL | MANAGE | FULL | TRACKER
  isHost: Bool
  readingPeriod, matchedCount, maxCapacity, waitingCount, isHot
  startDate, hostNickname, hostProfileImageUrl
  preferRegion, meetPlace  // meetPlace != nil → 직거래 지역 표시
  groupTags: [String], customTag, groupComment
  participantSlots: [ParticipantSlot]

ParticipantSlot            // nickname?, profileImageUrl?, role (HOST|GUEST|EMPTY), isMe

GroupApplyRequest          // applyMsg: String
GroupApplyResponse         // applicationId, status, createdAt (래퍼 포함)
GroupCancelResponse        // groupId, canceledAt (래퍼 포함)

GroupApplicantDto          // applicationId, userId, name, tags: [String]?, applyMsg, profileImageUrl?, createdAt
GroupApplicantListResponse // applicationList: [GroupApplicantDto], totalCount (래퍼 포함)

GroupAppStatusRequest      // status: "ACCEPTED" | "REJECTED"
GroupAppStatusResponse     // isSuccess, code, message (래퍼)

GroupDeleteResponse        // isSuccess, code, message, result: (groupId, deletedAt)?
```

### 2-2. GroupService.swift 추가

| 메서드 | HTTP | 경로 |
|--------|------|------|
| `fetchGroupDetail(groupId:)` | GET | `/api/groups/{groupId}` |
| `applyGroup(groupId:applyMsg:)` | POST | `/api/groups/{groupId}/apply` |
| `cancelApply(groupId:)` | DELETE | `/api/groups/{groupId}/apply` |
| `fetchApplicants(groupId:)` | GET | `/api/groups/{groupId}/applications` |
| `updateApplicant(applicationId:status:)` | PUT | `/api/applications/{applicationId}` |
| `deleteGroup(groupId:)` | DELETE | `/api/groups/{groupId}` |

---

## 3. GroupDetailViewModel

```swift
@MainActor
final class GroupDetailViewModel: ObservableObject {
    let groupId: Int
    private let service: GroupService

    @Published var detail: GroupDetailDto?
    @Published var phase: LoadPhase = .idle
    @Published var toast: ToastState?
    @Published var showApplyDialog = false
    @Published var showDeleteConfirm = false
    @Published var showApplicants = false
    @Published var shouldDismiss = false

    func onAppear() async
    func fetchDetail() async

    // 버튼 액션
    func applyGroup(msg: String) async  // 성공 → fetchDetail 재호출
    func cancelApply() async            // 성공 → shouldDismiss = true
    func deleteGroup() async            // 성공 → shouldDismiss = true

    // 더보기
    var isHost: Bool   { detail?.isHost ?? false }
    var canEdit: Bool  { isHost && detail?.groupStatus == "RECRUITING" }
}
```

**buttonStatus → 버튼 동작 분기:**

| buttonStatus | 버튼 텍스트 | 동작 |
|---|---|---|
| APPLY | 참여 신청하기 | showApplyDialog = true |
| CANCEL | 신청 취소하기 | cancelApply() |
| MANAGE | 참여 요청 관리 (N) | showApplicants = true |
| FULL | 모집 완료 | 비활성 |
| TRACKER | 서재/트래커 보기 | groupStatus==RECRUITING → 토스트, 아니면 shouldDismiss = true |

---

## 4. GroupDetailView

### 진입
- `GroupView.swift` / `GroupSearchView.swift` 카드 탭 → `.fullScreenCover(item: $selectedGroupId)` → `GroupDetailView`
- `selectedGroupId`는 `Int?` 타입

### 레이아웃

```
ZStack(alignment: .bottom)
├── ScrollView
│   ├── 헤더바
│   │   ├── 뒤로가기 버튼 (←)
│   │   ├── 책 제목 (중앙, 1줄 말줄임)
│   │   └── 케밥 아이콘 (·•·)
│   ├── 카드 섹션 (GroupCard와 동일 구성)
│   │   ├── 책 표지(KFImage 74×94) + 제목/저자/장르
│   │   ├── 상태 배지 (TOGETHER → "함께읽기(N)", RELAY → pictureBadge or "모집")
│   │   ├── 메타 Row (독서기간 | 현재인원 명 대기 | HOT 배지)
│   │   ├── 프로필 Row (호스트 이미지 + 닉네임 + 시작일)
│   │   └── 태그 chips (전체 표시, 줄바꿈 허용)
│   ├── 그룹 소개 박스 (흰 배경, cornerRadius 20)
│   │   ├── "그룹 소개" 제목 + 구분선
│   │   ├── groupComment 텍스트
│   │   └── (meetPlace 있을 때만) "교환 희망 장소" + meetPlace 텍스트
│   └── 참여 멤버 박스 (흰 배경, cornerRadius 20)
│       ├── "참여 멤버 matchedCount/maxCapacity" 제목 + 구분선
│       └── ForEach participantSlots
│           └── 프로필(36pt, cornerRadius 12) + 닉네임 + role/isMe 보조 텍스트
│               role == EMPTY → 회색 원 + "대기 중"
│               role == HOST  → 닉네임 뒤 "(호스트)"
│               isMe == true  → 닉네임 뒤 "(나)"
└── 하단 고정 버튼 (흰 배경)
    └── buttonStatus 분기 버튼 (height 56, cornerRadius 16, main200 배경)
        └── FULL일 때 grey300 배경 + 비활성
```

### 오버레이

- **신청 다이얼로그** (`showApplyDialog = true`)
  - 제목 "그룹 참여 신청" + X 버튼
  - 호스트 닉네임 + 책 제목 (1줄 말줄임)
  - "신청 한마디" 레이블 + 글자수 카운터
  - TextEditor 120pt, maxLength 200, 배경 grey100 rounded
  - 취소 / 확인 버튼 (안드로이드 동일 구조)

- **삭제 확인 다이얼로그** (`showDeleteConfirm = true`)
  - 제목 "그룹 삭제" + 책 제목 + "그룹을 정말 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다."
  - 취소 / 삭제(red) 버튼

- **더보기 바텀시트** (케밥 탭)
  - 호스트 + RECRUITING: 수정(활성) / 삭제
  - 호스트 + 기타: 수정(회색, 비활성) / 삭제
  - 게스트: 신고 (준비 중 토스트)
  - 수정 탭 시 → "그룹 수정은 준비 중입니다" 토스트 (feat/#18 제외)

---

## 5. GroupApplicantView

`.fullScreenCover(isPresented: $viewModel.showApplicants)` 로 진입.  
ViewModel을 그대로 공유(`@ObservedObject`).

```
NavigationBar 대신 커스텀 헤더
├── 뒤로가기 버튼
└── "참여 요청 관리 (N)" 제목

ScrollView
└── LazyVStack(spacing: 16)
    └── GroupApplicantCard (per applicant)
        ├── 프로필 이미지(48pt, cornerRadius 20) + 닉네임 + 날짜
        ├── 태그 chips (HStack, wrap)
        ├── 신청 메시지 (grey100 rounded box)
        └── [거절] [수락] 버튼 (spread_inside, 동일 너비)
```

신청자 목록은 `fetchApplicants()` — GroupApplicantView `.onAppear` 시 호출.  
수락/거절 성공 시 해당 항목 즉시 로컬 리스트에서 제거 (재호출 없이 낙관적 업데이트).

---

## 6. 진입점 연결

**GroupView.swift:**
```swift
@State private var selectedGroupId: Int? = nil
// ...
GroupCard(item: item) {
    selectedGroupId = item.groupId
}
// ...
.fullScreenCover(item: $selectedGroupId) { groupId in
    GroupDetailView(groupId: groupId, groupService: container.api.group)
}
```

**GroupSearchView.swift:** 동일 패턴.

---

## 7. 제외 범위 (이번 PR)

- 댓글/대댓글/비밀댓글 → feat/#19
- 그룹 수정 폼 → 별도 사이클 (현재 탭 시 "준비 중" 토스트)
- 신고 → 별도 사이클 (현재 탭 시 "준비 중" 토스트)
- TRACKER 상태에서 실제 서재/트래커 이동 → 해당 화면 구현 후 연결
