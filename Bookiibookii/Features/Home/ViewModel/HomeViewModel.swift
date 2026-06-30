import Foundation
import Combine

// 안드로이드 HomeViewModel(HomeTab/HomeUiState) 대응 — 탐색 탭.
enum HomeTab: Int, CaseIterable, Identifiable {
    case recommend
    case myGroups
    case applied

    var id: Int { rawValue }
    var title: String {
        switch self {
        case .recommend: return "추천"
        case .myGroups:  return "내 그룹"
        case .applied:   return "신청한 그룹"
        }
    }
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var selectedTab: HomeTab = .recommend
    @Published private(set) var nickname: String = ""
    @Published private(set) var recommendSections: [HomeSection] = []
    @Published private(set) var myGroups: [GroupItemDto] = []
    @Published private(set) var appliedGroups: [AppliedGroupItem] = []
    @Published private(set) var hasUnreadNotification: Bool = false

    private let groupService: GroupService
    private let notificationService: NotificationService
    private let userService: UserService
    private var didLoadInitial = false

    init(
        groupService: GroupService,
        notificationService: NotificationService,
        userService: UserService
    ) {
        self.groupService = groupService
        self.notificationService = notificationService
        self.userService = userService
    }

    /// 홈 진입 최초 1회 로드 + 알림 뱃지.
    func onAppear() async {
        await refreshNotificationBadge()
        guard !didLoadInitial else { return }
        didLoadInitial = true
        async let nick: Void = loadNickname()
        async let recommend: Void = loadRecommendSections()
        _ = await (nick, recommend)
    }

    /// 알림 화면에서 돌아왔을 때 뱃지 갱신.
    func refreshNotificationBadge() async {
        async let sys = try? notificationService.fetchNotifications(category: .system, cursor: nil, size: 20)
        async let kw = try? notificationService.fetchNotifications(category: .keyword, cursor: nil, size: 20)
        let (systemResult, keywordResult) = await (sys, kw)
        let systemItems = systemResult?.items ?? []
        let keywordItems = keywordResult?.items ?? []
        hasUnreadNotification = systemItems.contains { !$0.isRead } || keywordItems.contains { !$0.isRead }
    }

    func selectTab(_ tab: HomeTab) {
        guard selectedTab != tab else { return }
        selectedTab = tab
        switch tab {
        case .myGroups: Task { await loadMyGroups() }
        case .applied:  Task { await loadAppliedGroups() }
        case .recommend: break
        }
    }

    /// 화면 복귀 시 현재 탭만 다시 로드 (수락 후 상태 변경 반영).
    func refreshCurrentTab() async {
        switch selectedTab {
        case .recommend: await loadRecommendSections()
        case .myGroups:  await loadMyGroups()
        case .applied:   await loadAppliedGroups()
        }
    }

    // MARK: - 로드

    private func loadNickname() async {
        // 서버 mypage 응답에서 nickname만 사용 (공통 필드).
        if let result = try? await userService.getMypage() {
            nickname = result.nickname
        }
    }

    private func loadRecommendSections() async {
        if let response = try? await groupService.fetchHomeGroups() {
            recommendSections = response.sections
        }
    }

    private func loadMyGroups() async {
        if let groups = try? await groupService.fetchMyHostedGroups() {
            // 안드: 매칭 전(BEFORE_MATCHING) 그룹만 노출.
            myGroups = groups.filter { $0.displayStatus == "BEFORE_MATCHING" }
        }
    }

    private func loadAppliedGroups() async {
        if let response = try? await groupService.fetchAppliedGroups() {
            // 안드: 대기(PENDING) 신청만 노출.
            appliedGroups = response.applicationList.filter { $0.applicationStatus == "PENDING" }
        }
    }
}
