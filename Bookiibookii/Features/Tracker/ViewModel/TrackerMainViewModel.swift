import SwiftUI

// 안드 vm/TrackerMainViewModel.kt 대응 — load()(L367–396) / fetchNotificationDot()(L59–74).
@MainActor
final class TrackerMainViewModel: ObservableObject {
    @Published var state = TrackerMainUiState()
    let coordinator: TrackerDialogCoordinator

    private let trackerService: TrackerService
    private let notificationService: NotificationService
    private var didFirstAppear = false   // 안드 isFirstResume: 첫 진입 재조회 skip

    init(trackerService: TrackerService, notificationService: NotificationService) {
        self.trackerService = trackerService
        self.notificationService = notificationService
        self.coordinator = TrackerDialogCoordinator()
        self.coordinator.onChanged = { [weak self] in await self?.load() }
    }

    // 안드 load(): fetchMyTrackers → cards/nickname/notifications/counts 매핑
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

    // 안드 fetchNotificationDot(): SYSTEM+KEYWORD 미읽음 하나라도 있으면 배지
    func fetchNotificationDot() async {
        async let sys = try? notificationService.fetchNotifications(category: .system, cursor: nil, size: 20)
        async let kw = try? notificationService.fetchNotifications(category: .keyword, cursor: nil, size: 20)
        let sysItems = (await sys)?.items ?? []
        let kwItems = (await kw)?.items ?? []
        state.hasNewNotification = sysItems.contains { !$0.isRead } || kwItems.contains { !$0.isRead }
    }

    // 화면 진입: 첫 진입은 init 후 최초 load, 복귀는 재조회 (안드 ON_RESUME)
    func onAppear() async {
        if didFirstAppear {
            await load()
            await fetchNotificationDot()
        } else {
            didFirstAppear = true
            await load()
            await fetchNotificationDot()
        }
    }
}
