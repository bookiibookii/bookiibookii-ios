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

    @Published private(set) var hasUnreadNotification: Bool = false

    private let recommendationService: RecommendationService
    private let notificationService: NotificationService
    private var didLoadInitial = false

    init(
        recommendationService: RecommendationService,
        notificationService: NotificationService
    ) {
        self.recommendationService = recommendationService
        self.notificationService = notificationService
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
