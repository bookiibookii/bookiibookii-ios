import Foundation

enum TrackerStepLabelStyle {
    case main
    case sub
}

struct TrackerMainUiState {
    var cards: [TrackerCardModel] = []
    var nickname: String = ""
    var notifications: [TrackerNotificationItem] = []
    var totalCount: Int = 0
    var readingCount: Int = 0
    var exchangingCount: Int = 0
    var reviewCount: Int = 0
    var hasNewNotification: Bool = false
    var loading: Bool = false
    // 첫 조회가 한 번이라도 끝났는지. EmptyCard는 이게 true일 때만 노출
    var hasLoadedOnce: Bool = false
    var error: String? = nil
}

private let emptyTrackerProfile = TrackerProfileItem(
    nickname: "",
    bookTitle: "",
    bookCoverUrl: nil,
    profileImageUrl: nil,
    progressPercent: 0,
    isOwnerBook: false
)

struct TrackerDetailUiState {
    var groupName: String = ""
    var dDay: String = ""
    // 독서 기간 수정 다이얼로그용 원본 dDay(일 수). 종료일 = 오늘 + dDayCount
    var dDayCount: Int? = nil
    var statusLabel: String = ""
    var currentStepLabel: String = ""
    var currentStepLabelStyle: TrackerStepLabelStyle = .main
    var currentStepPosition: Int = 1  // 1..4 — StatusProgressBar 칩 위치
    var myProfile: TrackerProfileItem = emptyTrackerProfile
    var partnerProfile: TrackerProfileItem = emptyTrackerProfile
    var exchangeLabel: String = ""
    var primaryAction: TrackerAction = .none
    var secondaryAction: TrackerAction = .none
    var primaryEnabled: Bool = true
    var secondaryEnabled: Bool = true
    var showReadingProgress: Bool = true
    // 더보기 드롭다운의 "독서 기간 수정" 호스트 전용 노출 분기에 사용
    var isHost: Bool = false
    var steps: [TrackerStep] = []
    var loading: Bool = false
    var error: String? = nil
    // 삭제된/존재하지 않는 그룹(404) → 삭제된 페이지 화면
    var notFound: Bool = false
}
