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
    /// 안드 GuestActivity.showSheetOnceForStatus 트래킹 대응.
    private var presentedStatuses: Set<TrackerStatusDTO> = []

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

    /// row 탭 진입점 — 서버에서 최신 detail을 받아 phase/status 갱신 후 현재 status 시트 노출.
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

    // MARK: - 액션 (게스트용 — verifyReception 없음. startReading은 RECEIVED 단계에서 호출)

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

    /// 안드 GuestViewModel.patchConfirmReception 대응.
    /// 게스트가 호스트의 수령 인증 사진을 확인 후 서버에 isVerified=true로 갱신.
    /// 다음 진입 시 .returned + isVerified=true → .tradeFinish 시트로 라우팅된다.
    func confirmReception() async {
        await runAction { try await self.service.verifyReception(groupId: self.groupId) }
    }

    // MARK: - 자동 시트 매핑 (안드 GuestActivity.createSheetForStatus 대응)

    /// 서버 status + 회수확인 여부 → 노출 시트.
    /// 안드 GuestActivity.createSheetForStatus와 1:1.
    func defaultSheet(for status: TrackerStatusDTO, isVerified: Bool) -> DeliverySheet? {
        switch status {
        case .ready, .hostReading:                      return .readingStatus
        case .hostExtension:                            return .extendRequest
        case .hostDone:                                 return .readingDone
        case .shippingToGuest:                          return .shipped
        case .received:                                 return .start
        case .guestReading, .guestExtension:            return .reading
        case .guestDone:                                return .shipping
        case .shippingToHost:                           return .shippingStatus
        case .returned:
            return isVerified ? .tradeFinish : .shippingStatus
        case .completed, .unknown:                      return .tradeFinish
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
