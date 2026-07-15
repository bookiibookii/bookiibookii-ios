import SwiftUI
import Combine

@MainActor
final class TrackerMainViewModel: ObservableObject {
    @Published var state = TrackerMainUiState()
    let coordinator: TrackerDialogCoordinator

    private let trackerService: TrackerService
    private let notificationService: NotificationService

    init(trackerService: TrackerService, notificationService: NotificationService, locationService: LocationService) {
        self.trackerService = trackerService
        self.notificationService = notificationService
        self.coordinator = TrackerDialogCoordinator(trackerService: trackerService, locationService: locationService)
        self.coordinator.onChanged = { [weak self] in await self?.load() }
    }

    // fetchMyTrackers → cards/nickname/notifications/counts 매핑
    func load() async {
        state.loading = true
        state.error = nil
        do {
            let res = try await trackerService.fetchMyTrackers()
            state.cards = res.items.map { $0.toCardModel() }
            state.nickname = res.nickname ?? ""
            state.notifications = (res.topBanners ?? []).map { $0.toNotificationItem() }
            state.totalCount = res.summary.totalCount
            state.readingCount = res.summary.readingCount
            state.exchangingCount = res.summary.exchangingCount
            state.reviewCount = res.summary.reviewCount
            state.loading = false
            state.hasLoadedOnce = true
        } catch {
            state.error = "트래커를 불러오지 못했어요"
            state.loading = false
            state.hasLoadedOnce = true
        }
    }

    // SYSTEM+KEYWORD 미읽음 하나라도 있으면 배지
    func fetchNotificationDot() async {
        async let sys = try? notificationService.fetchNotifications(category: .system, cursor: nil, size: 20)
        async let kw = try? notificationService.fetchNotifications(category: .keyword, cursor: nil, size: 20)
        let sysItems = (await sys)?.items ?? []
        let kwItems = (await kw)?.items ?? []
        state.hasNewNotification = sysItems.contains { !$0.isRead } || kwItems.contains { !$0.isRead }
    }

    // 화면 진입: load + 알림 뱃지 조회
    func onAppear() async {
        // refreshable/.task 스코프가 리프레시 도중 취소되면 fetch까지 -999로 죽어 목록이 갱신 안 됨.
        // VM 소유 독립(unstructured) 태스크로 실행해 취소 전파를 끊고 요청을 끝까지 완료시킨다.
        await Task { await self.load() }.value
        await fetchNotificationDot()
    }
}
