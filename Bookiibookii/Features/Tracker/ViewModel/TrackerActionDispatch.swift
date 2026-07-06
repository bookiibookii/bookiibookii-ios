import Foundation

// 카드 액션이 화면 밖으로 이동하는 콜백 묶음. PR-A에서는 전부 플레이스홀더(실제 화면은 #5~#8).
struct TrackerNavActions {
    var onNavigateBookReview: (_ groupId: Int, _ edit: Bool) -> Void = { _, _ in }
    var onNavigatePartnerReview: (_ groupId: Int) -> Void = { _ in }
    var onNavigateComment: (_ groupId: Int, _ title: String) -> Void = { _, _ in }
    var onWriteReadingCard: (_ groupId: Int) -> Void = { _ in }
}

// 안드 TrackerMainScreen.dispatchAction 이식. primary/secondary 액션을 다이얼로그 열기 또는 네비로 분기.
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
    // 화면 이동 액션 (PR-A 플레이스홀더)
    case .writeBookReview:       nav.onNavigateBookReview(groupId, false)
    case .editBookReview:        nav.onNavigateBookReview(groupId, true)
    case .writePartnerReview:    nav.onNavigatePartnerReview(groupId)
    case .goToComments:          nav.onNavigateComment(groupId, "")
    case .writeReadingCard:      nav.onWriteReadingCard(groupId)
    // 비활성/없음
    case .completeExchange, .none:
        break
    }
}
