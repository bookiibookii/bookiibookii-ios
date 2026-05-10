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
    @Published private(set) var isOpeningLibraryCards: Bool = false
    @Published var libraryBookToOpen: LibraryBook?

    let groupId: Int
    let service: TrackerService
    private let libraryService: LibraryService
    private var presentedStatuses: Set<TrackerStatusDTO> = []

    init(groupId: Int, service: TrackerService, libraryService: LibraryService) {
        self.groupId = groupId
        self.service = service
        self.libraryService = libraryService
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

    /// 시트의 "독서카드 확인하러 가기" → 안드 `getLibraryBooks()` + groupId 매칭 패턴.
    func openLibraryCards() async {
        guard !isOpeningLibraryCards else { return }
        isOpeningLibraryCards = true
        defer { isOpeningLibraryCards = false }
        do {
            let books = try await libraryService.fetchLibraryBooks()
            guard let match = books.first(where: { $0.groupId == groupId }) else {
                toastMessage = "독서카드 정보를 찾을 수 없습니다."
                return
            }
            libraryBookToOpen = match
        } catch {
            toastMessage = (error as? LocalizedError)?.errorDescription
                ?? "네트워크 오류, 다시 시도해주세요"
        }
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

    // MARK: - 액션 (안드 DirectGuestViewModel 미러)

    func startReading() async {
        await runAction { try await self.service.startReading(groupId: self.groupId) }
    }

    func markDone() async {
        await runAction { try await self.service.markDone(groupId: self.groupId) }
    }

    func requestExtension(days: Int) async {
        await runAction {
            try await self.service.requestExtension(groupId: self.groupId, days: days)
        }
    }

    /// 폼 입력값(`yyyy. MM. dd. HH:mm`) + 장소 → 약속 등록.
    /// 변환 실패 / 빈 장소면 토스트만 띄우고 종료.
    func makeMeeting(formInput: String, place: String) async {
        guard let apiTime = DirectMeetingFormatter.toApiUtcZ(formInput) else {
            toastMessage = "날짜 형식이 올바르지 않아요"
            return
        }
        let trimmedPlace = place.trimmingCharacters(in: .whitespaces)
        guard !trimmedPlace.isEmpty else {
            toastMessage = "장소를 입력해주세요"
            return
        }
        await runAction {
            try await self.service.makeMeeting(
                groupId: self.groupId,
                time: apiTime,
                place: trimmedPlace
            )
        }
    }

    func completeMeeting() async {
        await runAction { try await self.service.completeMeeting(groupId: self.groupId) }
    }

    // MARK: - 내부

    private func runDetailLoad(autoPresent: Bool) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await service.fetchDetail(groupId: groupId)
            handle(response, autoPresent: autoPresent)
        } catch {
            toastMessage = (error as? LocalizedError)?.errorDescription
                ?? "네트워크 오류, 다시 시도해주세요"
        }
    }

    private func runAction(
        autoPresent: Bool = true,
        _ block: @escaping () async throws -> TrackerDetailResponse
    ) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await block()
            handle(response, autoPresent: autoPresent)
        } catch {
            toastMessage = (error as? LocalizedError)?.errorDescription
                ?? "네트워크 오류, 다시 시도해주세요"
        }
    }

    private func handle(_ response: TrackerDetailResponse, autoPresent: Bool) {
        detail = response
        phase = DirectPhase.from(response.trackerStatus)
        if autoPresent {
            autoPresentIfNeeded(
                status: response.trackerStatus,
                meetingTime: response.meetingInfo?.meetingTime
            )
        }
    }

    private func autoPresentIfNeeded(status: TrackerStatusDTO, meetingTime: String?) {
        guard !presentedStatuses.contains(status),
              let sheet = defaultSheet(for: status, meetingTime: meetingTime) else { return }
        presentedStatuses.insert(status)
        activeSheet = sheet
    }
}
