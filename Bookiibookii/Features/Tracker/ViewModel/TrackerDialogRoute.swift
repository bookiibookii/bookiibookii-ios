import Foundation

// 트래커 다이얼로그 라우트. 안드 TrackerMainRoute의 rememberSaveable groupId 상태들을 하나의 enum으로 통합.
// 메인(PR-A~C)·상세(#5)가 공유하는 TrackerDialogCoordinator.route 값.
enum TrackerDialogRoute: Equatable {
    case progress(groupId: Int)
    case tracking(groupId: Int)
    case deliveryInfo(groupId: Int)
    case deliveryEdit(groupId: Int)
    case shippingConfirm(groupId: Int)
    case receiveConfirm(groupId: Int)
    // 약속 잡기: step 1=일시 / 2=장소 / 3=확인. editMode면 3/3에서 PATCH.
    case meeting(groupId: Int, step: Int, editMode: Bool)
    case meetingInfo(groupId: Int)
    case exchangeConfirm(groupId: Int)
    case exchangeFail(groupId: Int)
}
