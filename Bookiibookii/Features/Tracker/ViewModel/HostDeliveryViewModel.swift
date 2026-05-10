import Foundation
import Combine
import UIKit

@MainActor
final class HostDeliveryViewModel: ObservableObject {
    @Published private(set) var detail: TrackerDetailResponse?
    @Published private(set) var phase: DeliveryPhase = .initState
    @Published var activeSheet: DeliverySheet?
    @Published private(set) var isLoading: Bool = false
    @Published var toastMessage: String?
    @Published private(set) var isOpeningLibraryCards: Bool = false
    @Published var libraryBookToOpen: LibraryBook?

    let groupId: Int
    let service: TrackerService
    private let libraryService: LibraryService
    /// 안드 GuestActivity/HostActivity의 showSheetOnceForStatus 트래킹 대응.
    /// 같은 status에서 자동으로 두 번 열리지 않도록 한 번 띄운 status를 기억.
    private var presentedStatuses: Set<TrackerStatusDTO> = []

    init(groupId: Int, service: TrackerService, libraryService: LibraryService) {
        self.groupId = groupId
        self.service = service
        self.libraryService = libraryService
    }

    // MARK: - 진입 / 시트 조작

    func onAppear() async {
        await runAction(autoPresent: true) {
            try await self.service.fetchDetail(groupId: self.groupId)
        }
    }

    func tapStep(_ sheet: DeliverySheet) {
        activeSheet = sheet
    }

    func dismissSheet() {
        activeSheet = nil
    }

    /// 시트의 "독서카드 확인하러 가기" → 안드 `getLibraryBooks()` + groupId 매칭 패턴.
    /// 매칭된 LibraryBook은 `libraryBookToOpen`에 세팅되고, View의 onChange가 시트 dismiss + push를 처리.
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

    /// row 탭 진입점 — 서버에서 최신 detail을 받아 phase 갱신 후 현재 status 시트 노출.
    /// presentedStatuses를 우회해 명시 탭은 항상 시트가 열린다.
    func refreshAndShowSheet() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await service.fetchDetail(groupId: groupId)
            detail = response
            phase = DeliveryPhase.from(response.trackerStatus)
            if let sheet = defaultSheet(
                for: response.trackerStatus,
                isVerified: response.deliveryInfo?.isVerified ?? false
            ) {
                activeSheet = sheet
            }
        } catch {
            toastMessage = (error as? LocalizedError)?.errorDescription
                ?? "네트워크 오류, 다시 시도해주세요"
        }
    }

    // MARK: - 액션

    func startReading() async {
        await runAction { try await self.service.startReading(groupId: self.groupId) }
    }

    func requestExtension(days: Int) async {
        await runAction { try await self.service.requestExtension(groupId: self.groupId, days: days) }
    }

    func markDone() async {
        await runAction { try await self.service.markDone(groupId: self.groupId) }
    }

    func startShipping(company: String, trackingNumber: String, image: UIImage) async {
        await runAction {
            try await self.service.startShipping(
                groupId: self.groupId,
                deliveryCompany: company,
                trackingNumber: trackingNumber,
                image: image
            )
        }
    }

    func registerReceipt(image: UIImage) async {
        await runAction {
            try await self.service.registerReceipt(groupId: self.groupId, image: image)
        }
    }

    func verifyReception() async {
        await runAction { try await self.service.verifyReception(groupId: self.groupId) }
    }

    // MARK: - 자동 시트 매핑 (안드 HostActivity.createSheetForStatus 대응)

    /// 서버 status + 수령확인 여부 → 노출 시트.
    /// 안드 HostActivity.createSheetForStatus와 1:1.
    func defaultSheet(for status: TrackerStatusDTO, isVerified: Bool) -> DeliverySheet? {
        switch status {
        case .ready:                                    return .start
        case .hostReading, .hostExtension:              return .reading
        case .hostDone:                                 return .shipping
        case .shippingToGuest, .received:               return .shippingStatus
        case .guestReading:
            return isVerified ? .readingStatus : .shippingStatus
        case .guestExtension:                           return .extendRequest
        case .guestDone:                                return .readingDone
        case .shippingToHost:                           return .shipped
        case .returned, .completed, .unknown:           return .tradeFinish
        }
    }

    // MARK: - 내부 헬퍼

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
        phase = DeliveryPhase.from(response.trackerStatus)
        if autoPresent {
            autoPresentIfNeeded(
                status: response.trackerStatus,
                isVerified: response.deliveryInfo?.isVerified ?? false
            )
        }
    }

    private func autoPresentIfNeeded(status: TrackerStatusDTO, isVerified: Bool) {
        guard !presentedStatuses.contains(status),
              let sheet = defaultSheet(for: status, isVerified: isVerified) else { return }
        presentedStatuses.insert(status)
        activeSheet = sheet
    }
}
