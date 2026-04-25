import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    enum GroupPhase: Equatable {
        case idle
        case loading
        case loaded
        case failed
    }

    @Published private(set) var recommendedGroups: [RecommendedGroupDto] = []
    @Published private(set) var groupPhase: GroupPhase = .idle

    @Published private(set) var recommendedBookmates: [RecommendedBookmateDto] = []
    @Published private(set) var matePhase: GroupPhase = .idle

    @Published private(set) var activeExchanges: [TrackerItem] = []
    @Published private(set) var exchangePhase: GroupPhase = .idle

    @Published private(set) var hasUnreadNotification: Bool = false

    private let recommendationService: RecommendationService
    private let notificationService: NotificationService
    private let trackerService: TrackerService
    private var didLoadInitial = false

    init(
        recommendationService: RecommendationService,
        notificationService: NotificationService,
        trackerService: TrackerService
    ) {
        self.recommendationService = recommendationService
        self.notificationService = notificationService
        self.trackerService = trackerService
    }

    /// 홈 진입 최초 1회 로드 (그룹 + 부키메이트 병렬) + 알림 뱃지.
    func onAppear() async {
        await refreshNotificationBadge()
        guard !didLoadInitial else { return }
        didLoadInitial = true
        async let groups: Void = loadRecommendedGroups(refresh: false)
        async let mates: Void = loadRecommendedBookmates()
        _ = await (groups, mates)
    }

    /// 알림 화면에서 돌아왔을 때 뱃지 갱신.
    /// 안드로이드 HomeFragment.refreshNotiBadge 대응.
    func refreshNotificationBadge() async {
        async let sys = try? notificationService.fetchNotifications(category: .system, cursor: nil, size: 20)
        async let kw = try? notificationService.fetchNotifications(category: .keyword, cursor: nil, size: 20)
        let (systemResult, keywordResult) = await (sys, kw)
        let systemItems = systemResult?.items ?? []
        let keywordItems = keywordResult?.items ?? []
        hasUnreadNotification = systemItems.contains { !$0.isRead } || keywordItems.contains { !$0.isRead }
    }

    /// 그룹 섹션 새로고침 버튼 탭.
    func refreshRecommendedGroups() async {
        await loadRecommendedGroups(refresh: true)
    }

    /// 진행 중인 교환 로드 — 안드 HomeFragment.loadExchangeProgress 대응.
    /// 홈 탭 진입할 때마다 매번 호출 (안드 onViewCreated와 동일 의도).
    func loadActiveExchanges() async {
        exchangePhase = .loading
        async let host = try? trackerService.fetchHostTrackers()
        async let guest = try? trackerService.fetchGuestTrackers()
        let (h, g) = await (host, guest)
        if h == nil && g == nil {
            activeExchanges = []
            exchangePhase = .failed
        } else {
            activeExchanges = (h ?? []) + (g ?? [])
            exchangePhase = .loaded
        }
    }

    private func loadRecommendedGroups(refresh: Bool) async {
        groupPhase = .loading
        do {
            let list = try await recommendationService.fetchRecommendedGroups(refresh: refresh)
            recommendedGroups = list
            groupPhase = .loaded
        } catch {
            recommendedGroups = []
            groupPhase = .failed
        }
    }

    private func loadRecommendedBookmates() async {
        matePhase = .loading
        do {
            let list = try await recommendationService.fetchRecommendedBookmates()
            recommendedBookmates = Array(list.prefix(5))
            matePhase = .loaded
        } catch {
            recommendedBookmates = []
            matePhase = .failed
        }
    }
}
