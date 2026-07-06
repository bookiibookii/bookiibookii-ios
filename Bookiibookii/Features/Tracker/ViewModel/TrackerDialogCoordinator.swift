import Foundation
import Combine

// 다이얼로그 상태머신 + (PR-B/C에서 붙일) 서비스 호출을 소유. 메인 VM·상세 VM이 각자 인스턴스 소유.
// PR-A: route 상태 + 열기 setter만. 데이터 로드/서비스 호출은 PR-B/C에서 in-place 추가.
@MainActor
final class TrackerDialogCoordinator: ObservableObject {
    @Published var route: TrackerDialogRoute?

    // 다이얼로그 성공 후 부모 목록 새로고침(= TrackerMainViewModel.load).
    var onChanged: () async -> Void

    // PR-B/C에서 로드 데이터 홀더 추가 예정:
    // @Published var deliveryAddress / savedDeliveries / partnerDelivery / meetingInfo / meetingPlace

    init(onChanged: @escaping () async -> Void = {}) {
        self.onChanged = onChanged
    }

    // MARK: - 열기 인텐트 (PR-B/C에서 필요한 곳은 데이터 로드 후 route 세팅으로 확장)
    func openProgress(groupId: Int) { route = .progress(groupId: groupId) }
    func openTracking(groupId: Int) { route = .tracking(groupId: groupId) }
    func openDeliveryInfo(groupId: Int) { route = .deliveryInfo(groupId: groupId) }
    func openDeliveryEdit(groupId: Int) { route = .deliveryEdit(groupId: groupId) }
    func openShippingConfirm(groupId: Int) { route = .shippingConfirm(groupId: groupId) }
    func openReceiveConfirm(groupId: Int) { route = .receiveConfirm(groupId: groupId) }
    func openMeeting(groupId: Int) { route = .meeting(groupId: groupId, step: 1, editMode: false) }
    func openMeetingInfo(groupId: Int) { route = .meetingInfo(groupId: groupId) }
    func openExchangeConfirm(groupId: Int) { route = .exchangeConfirm(groupId: groupId) }
    func openExchangeFail(groupId: Int) { route = .exchangeFail(groupId: groupId) }

    func dismiss() { route = nil }
}
