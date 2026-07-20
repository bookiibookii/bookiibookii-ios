import Foundation

// 신고/문의 — 앱 공통 카카오 채널 링크 (마이페이지 신고/문의와 동일 채널)
enum TrackerExternalLink {
    static let reportChannel = URL(string: "http://pf.kakao.com/_cIxlxjX/chat")!
}

// "독서카드 작성" — 트래커에는 userBookId가 없어 서재 목록에서 groupId+제목으로 해석한다.
@MainActor
func resolveTrackerLibraryBook(libraryService: LibraryService, groupId: Int, bookTitle: String) async -> LibraryBook? {
    guard let books = try? await libraryService.fetchLibraryBooks() else { return nil }
    return books.first { $0.groupId == groupId && $0.title == bookTitle }
}

// 카드 액션이 화면 밖으로 이동하는 콜백 묶음.
// 기본값을 두지 않아 배선 누락이 컴파일에서 잡히게 한다(no-op 기본값은 먹통 버튼을 조용히 숨긴다).
struct TrackerNavActions {
    var onNavigateBookReview: (_ groupId: Int, _ edit: Bool) -> Void
    var onNavigatePartnerReview: (_ groupId: Int) -> Void
    // 헤더 타이틀(트래커명)은 각 화면이 자기 상태에서 가져오므로 groupId만 넘긴다.
    var onNavigateComment: (_ groupId: Int) -> Void
    var onWriteReadingCard: (_ groupId: Int) -> Void
}

// primary/secondary 액션을 다이얼로그 열기 또는 네비로 분기.
@MainActor
func dispatchTrackerAction(
    _ action: TrackerAction,
    groupId: Int,
    coordinator: TrackerDialogCoordinator,
    nav: TrackerNavActions
) {
    switch action {
    case .recordProgress:        coordinator.openProgress(groupId: groupId)
    case .registerTrackingNumber: coordinator.openTracking(groupId: groupId)
    case .checkDeliveryInfo:     coordinator.openDeliveryInfo(groupId: groupId)
    case .registerMeeting:       coordinator.openMeeting(groupId: groupId)
    case .checkMeeting:          coordinator.openMeetingInfo(groupId: groupId)
    case .confirmExchange:       coordinator.openExchangeConfirm(groupId: groupId)
    case .checkShippingInfo:     coordinator.openShippingConfirm(groupId: groupId)
    case .confirmReceive:        coordinator.openReceiveConfirm(groupId: groupId)
    // 화면 이동 액션
    case .writeBookReview:       nav.onNavigateBookReview(groupId, false)
    case .editBookReview:        nav.onNavigateBookReview(groupId, true)
    case .writePartnerReview:    nav.onNavigatePartnerReview(groupId)
    case .goToComments:          nav.onNavigateComment(groupId)
    case .writeReadingCard:      nav.onWriteReadingCard(groupId)
    // 비활성/없음
    case .completeExchange, .none:
        break
    }
}
