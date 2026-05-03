import Foundation
import Combine
import UIKit

@MainActor
final class GuestDeliveryViewModel: ObservableObject {
    @Published private(set) var detail: TrackerDetailResponse?
    @Published private(set) var phase: DeliveryPhase = .initState
    @Published var activeSheet: DeliverySheet?
    @Published private(set) var isLoading: Bool = false
    @Published var toastMessage: String?

    let groupId: Int
    let service: TrackerService
    private var presentedPhases: Set<DeliveryPhase> = []

    init(groupId: Int, service: TrackerService) {
        self.groupId = groupId
        self.service = service
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

    /// row 탭 진입점 — 서버에서 최신 detail을 받아 phase 갱신 후 현재 phase 시트 노출.
    /// presentedPhases를 우회해 명시 탭은 항상 시트가 열린다.
    func refreshAndShowSheet() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await service.fetchDetail(groupId: groupId)
            detail = response
            phase = DeliveryPhase.from(response.trackerStatus)
            if let sheet = defaultSheet(for: phase) {
                activeSheet = sheet
            }
        } catch {
            toastMessage = (error as? LocalizedError)?.errorDescription
                ?? "네트워크 오류, 다시 시도해주세요"
        }
    }

    // MARK: - 액션 (게스트용 — startReading / verifyReception 없음)

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

    // MARK: - 첫 진입 / phase advance 시 자동 시트 표시

    func defaultSheet(for phase: DeliveryPhase) -> DeliverySheet? {
        switch phase {
        case .initState, .hostReading:           return .readingStatus
        case .hostShippingReady, .hostShipped:   return .shippingStatus
        case .guestReading:                       return .reading
        case .guestShippingReady:                 return .shipping
        case .guestShipped:                       return .shipped
        case .finished:                           return .tradeFinish
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
        let newPhase = DeliveryPhase.from(response.trackerStatus)
        let phaseChanged = newPhase != phase
        phase = newPhase
        if autoPresent && phaseChanged {
            autoPresentIfNeeded()
        } else if autoPresent && presentedPhases.isEmpty {
            autoPresentIfNeeded()
        }
    }

    private func autoPresentIfNeeded() {
        guard !presentedPhases.contains(phase),
              let sheet = defaultSheet(for: phase) else { return }
        presentedPhases.insert(phase)
        activeSheet = sheet
    }
}
