import Foundation
import Combine

// 다이얼로그 상태머신 + 서비스 호출을 소유. 메인 VM·상세 VM이 각자 인스턴스 소유.
@MainActor
final class TrackerDialogCoordinator: ObservableObject {
    @Published var route: TrackerDialogRoute?
    @Published var deliveryAddress: DeliveryAddressResDTO?
    @Published var savedDeliveries: [DeliveryAddress] = []
    @Published var partnerDelivery: PartnerDeliveryResponseDTO?
    @Published var meetingDraft = TrackerMeetingDraft()
    @Published var meetingInfo: MeetingResDTO?

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
    // 약속 등록 시작
    func openMeeting(groupId: Int) {
        meetingDraft = TrackerMeetingDraft()
        route = .meeting(groupId: groupId, step: 1, editMode: false)
    }

    // 스텝 이동(현재 route의 groupId/editMode 유지)
    func goMeetingStep(_ step: Int) {
        guard case let .meeting(groupId, _, editMode) = route else { return }
        route = .meeting(groupId: groupId, step: step, editMode: editMode)
    }

    func setMeetingScheduledAt(_ iso: String) { meetingDraft.scheduledAt = iso }
    func setMeetingPlace(_ place: TrackerMeetingPlace) { meetingDraft.place = place }
    func updateMeetingAddressDetail(_ text: String) { meetingDraft.addressDetail = text }

    // 내 희망교환장소 자동 채움(isDefault 우선, 없으면 첫 항목)
    func loadMyExchangePlace() {
        Task {
            let list = (try? await locationService.fetchExchanges()) ?? []
            if let picked = list.first(where: { $0.isDefault }) ?? list.first {
                meetingDraft.place = picked.toMeetingPlace()
            }
        }
    }

    // 약속 조회(로드 후 route)
    func openMeetingInfo(groupId: Int) {
        Task {
            do {
                meetingInfo = try await trackerService.fetchMeeting(groupId: groupId)
                route = .meetingInfo(groupId: groupId)
            } catch {}
        }
    }

    // 수정 진입: meetingInfo → draft 프리필 후 3스텝 재사용(editMode)
    func openMeetingEdit(groupId: Int) {
        guard let m = meetingInfo else { return }
        var draft = TrackerMeetingDraft()
        draft.scheduledAt = m.meetingAt
        draft.addressDetail = m.addressDetail ?? ""
        if let loc = m.location, let x = loc.x, let y = loc.y {
            draft.place = TrackerMeetingPlace(placeName: loc.placeName ?? "", address: loc.address ?? "", zipCode: loc.zipCode, x: x, y: y)
        }
        meetingDraft = draft
        meetingInfo = nil
        route = .meeting(groupId: groupId, step: 1, editMode: true)
    }
    func openExchangeConfirm(groupId: Int) { route = .exchangeConfirm(groupId: groupId) }
    func openExchangeFail(groupId: Int) { route = .exchangeFail(groupId: groupId) }
    func openReadingPeriod(groupId: Int, originalEndDate: Date?) {
        route = .readingPeriod(groupId: groupId, originalEndDate: originalEndDate)
    }

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
    func changeDeliveryAddressDirect(groupId: Int, zipCode: String, address: String, addressDetail: String) {
        Task { do { _ = try await trackerService.updateDeliveryAddressDirect(groupId: groupId, body: .init(zipCode: zipCode, address: address, addressDetail: addressDetail)); dismiss(); await onChanged() } catch {} }
    }
    func confirmReceive(groupId: Int) {
        Task { do { try await trackerService.confirmPartnerReceive(groupId: groupId); dismiss(); await onChanged() } catch {} }
    }
    func registerDelivery(groupId: Int, deliveryCompany: String, trackingNumber: String) {
        Task { do { try await trackerService.registerDelivery(groupId: groupId, deliveryCompany: deliveryCompany, trackingNumber: trackingNumber); dismiss(); await onChanged() } catch {} }
    }

    func submitMeeting(groupId: Int, editMode: Bool) {
        guard let body = meetingDraft.toRegisterReqDTO() else { return }
        Task {
            do {
                _ = editMode
                    ? try await trackerService.updateMeeting(groupId: groupId, body: body)
                    : try await trackerService.registerMeeting(groupId: groupId, body: body)
                dismiss()
                await onChanged()
            } catch {}
        }
    }

    func completeMeeting(groupId: Int) {
        Task {
            do { _ = try await trackerService.completeMeeting(groupId: groupId); dismiss(); await onChanged() } catch {}
        }
    }

    func updateReadingPeriod(groupId: Int, newEndDate: String) {
        Task { do { _ = try await trackerService.updateReadingPeriod(groupId: groupId, newEndDate: newEndDate); dismiss(); await onChanged() } catch {} }
    }

    func dismiss() {
        route = nil
        deliveryAddress = nil
        savedDeliveries = []
        partnerDelivery = nil
        meetingDraft = TrackerMeetingDraft()
        meetingInfo = nil
    }
}
