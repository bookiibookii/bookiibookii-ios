import Foundation
import Combine
import UIKit

/// 안드 trkDirectGuest.DirectGuestViewModel + DirectGuestActivity.createBottomSheetByStatus 대응.
/// 본 사이클에서는 view 스캐폴드용 뼈대만 — 액션 메서드는 다음 세션부터 채움.
@MainActor
final class GuestDirectViewModel: ObservableObject {
    @Published private(set) var detail: TrackerDetailResponse?
    @Published private(set) var phase: DirectPhase = .initState
    @Published var activeSheet: DirectSheet?
    @Published private(set) var isLoading: Bool = false
    @Published var toastMessage: String?

    let groupId: Int
    let service: TrackerService
    private var presentedStatuses: Set<TrackerStatusDTO> = []

    init(groupId: Int, service: TrackerService) {
        self.groupId = groupId
        self.service = service
    }

    // MARK: - 진입 / 시트 조작

    func onAppear() async {
        await runDetailLoad(autoPresent: true)
    }

    func tapStep(_ sheet: DirectSheet) {
        activeSheet = sheet
    }

    func dismissSheet() {
        activeSheet = nil
    }

    func refreshAndShowSheet() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await service.fetchDetail(groupId: groupId)
            detail = response
            phase = DirectPhase.from(response.trackerStatus)
            if let sheet = defaultSheet(
                for: response.trackerStatus,
                meetingTime: response.meetingInfo?.meetingTime
            ) {
                activeSheet = sheet
            }
        } catch {
            toastMessage = (error as? LocalizedError)?.errorDescription
                ?? "네트워크 오류, 다시 시도해주세요"
        }
    }

    // MARK: - 자동 시트 매핑 (안드 DirectGuestActivity.createBottomSheetByStatus)

    /// status + 약속시간 경과 여부 → 노출 시트.
    /// SHIPPING_TO_GUEST/SHIPPING_TO_HOST 는 isMeetingPassed로 분기 (안드 동작).
    func defaultSheet(for status: TrackerStatusDTO, meetingTime: String?) -> DirectSheet? {
        switch status {
        case .ready, .hostReading:                      return .readingStatus
        case .hostExtension:                            return .extendRequest
        case .hostDone:                                 return .meetEmpty
        case .shippingToGuest:
            return DirectMeetingClock.isPassed(meetingTime) ? .receive : .appointmentStatus
        case .received:                                 return .start
        case .guestReading, .guestExtension:            return .reading
        case .guestDone:                                return .appointment
        case .shippingToHost:
            return DirectMeetingClock.isPassed(meetingTime) ? .exchange : .appointmentEdit
        case .returned:                                 return .tradeFinish
        case .completed, .unknown:                      return nil
        }
    }

    // MARK: - 액션 (다음 세션부터)
    // TODO: startReading, markDone, requestExtension, makeMeeting, completeMeeting, …

    // MARK: - 내부

    private func runDetailLoad(autoPresent: Bool) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await service.fetchDetail(groupId: groupId)
            detail = response
            phase = DirectPhase.from(response.trackerStatus)
            if autoPresent {
                autoPresentIfNeeded(
                    status: response.trackerStatus,
                    meetingTime: response.meetingInfo?.meetingTime
                )
            }
        } catch {
            toastMessage = (error as? LocalizedError)?.errorDescription
                ?? "네트워크 오류, 다시 시도해주세요"
        }
    }

    private func autoPresentIfNeeded(status: TrackerStatusDTO, meetingTime: String?) {
        guard !presentedStatuses.contains(status),
              let sheet = defaultSheet(for: status, meetingTime: meetingTime) else { return }
        presentedStatuses.insert(status)
        activeSheet = sheet
    }
}
