import Foundation
import Combine

// 다이얼로그 상태머신 + 서비스 호출을 소유. 메인 VM·상세 VM이 각자 인스턴스 소유.
@MainActor
final class TrackerDialogCoordinator: ObservableObject {
    @Published var route: TrackerDialogRoute?
    @Published var deliveryAddress: DeliveryAddressResDTO?
    @Published var savedDeliveries: [DeliveryAddress] = []
    @Published var partnerDelivery: PartnerDeliveryResponseDTO?

    // 다이얼로그 성공 후 부모 목록 새로고침(= TrackerMainViewModel.load).
    var onChanged: () async -> Void

    private let trackerService: TrackerService
    private let locationService: LocationService

    init(trackerService: TrackerService, locationService: LocationService, onChanged: @escaping () async -> Void = {}) {
        self.trackerService = trackerService
        self.locationService = locationService
        self.onChanged = onChanged
    }

    // MARK: - 열기 인텐트 (로드 불필요)
    func openProgress(groupId: Int) { route = .progress(groupId: groupId) }
    func openTracking(groupId: Int) { route = .tracking(groupId: groupId) }
    func openReceiveConfirm(groupId: Int) { route = .receiveConfirm(groupId: groupId) }
    func openMeeting(groupId: Int) { route = .meeting(groupId: groupId, step: 1, editMode: false) }
    func openMeetingInfo(groupId: Int) { route = .meetingInfo(groupId: groupId) }
    func openExchangeConfirm(groupId: Int) { route = .exchangeConfirm(groupId: groupId) }
    func openExchangeFail(groupId: Int) { route = .exchangeFail(groupId: groupId) }

    // MARK: - 열기 인텐트 (로드 후 route)
    func openDeliveryInfo(groupId: Int) {
        Task {
            do {
                deliveryAddress = try await trackerService.fetchDeliveryAddress(groupId: groupId)
                route = .deliveryInfo(groupId: groupId)
            } catch {}
        }
    }
    func openDeliveryEdit(groupId: Int) {
        Task {
            savedDeliveries = (try? await locationService.fetchDeliveries()) ?? []
            route = .deliveryEdit(groupId: groupId)
        }
    }
    func openShippingConfirm(groupId: Int) {
        Task {
            do {
                partnerDelivery = try await trackerService.fetchPartnerDelivery(groupId: groupId)
                route = .shippingConfirm(groupId: groupId)
            } catch {}
        }
    }

    // MARK: - 확정 액션 (다이얼로그 onConfirm) — 성공 시 목록 리로드
    func recordProgress(groupId: Int, currentPage: Int) {
        Task { do { _ = try await trackerService.updateReadingProgress(groupId: groupId, currentPage: currentPage); await onChanged() } catch {} }
    }
    func changeDeliveryAddressSaved(groupId: Int, userDeliveryId: Int) {
        Task { do { _ = try await trackerService.updateDeliveryAddressSaved(groupId: groupId, userDeliveryId: userDeliveryId); dismiss(); await onChanged() } catch {} }
    }
    func confirmReceive(groupId: Int) {
        Task { do { try await trackerService.confirmPartnerReceive(groupId: groupId); dismiss(); await onChanged() } catch {} }
    }
    func registerDelivery(groupId: Int, deliveryCompany: String, trackingNumber: String) {
        Task { do { try await trackerService.registerDelivery(groupId: groupId, deliveryCompany: deliveryCompany, trackingNumber: trackingNumber); dismiss(); await onChanged() } catch {} }
    }

    func dismiss() {
        route = nil
        deliveryAddress = nil
        savedDeliveries = []
        partnerDelivery = nil
    }
}
