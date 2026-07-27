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
        async let nick = loadNickname()
        async let recommend = loadRecommendSections()
        let (nickLoaded, recommendLoaded) = await (nick, recommend)
        // 실패한 채로 플래그를 세우면 재진입해도 영구히 다시 부르지 않으므로, 성공했을 때만 세운다.
        didLoadInitial = nickLoaded && recommendLoaded
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
        // 탭 전환 시 항상 해당 탭 데이터를 재조회한다.
        Task { await refreshCurrentTab() }
    }

    /// 화면 복귀 시 현재 탭만 강제 새로고침 (수락/신청 등 상태 변경 반영).
    func refreshCurrentTab() async {
        // refreshable 태스크 취소가 fetch까지 전파되면(-999) try?에 삼켜져 옛 목록이 유지됨.
        // VM 소유 독립 태스크로 실행해 취소 전파를 끊는다.
        await Task { [self] in
            switch selectedTab {
            case .recommend: _ = await loadRecommendSections()
            case .myGroups:  await loadMyGroups()
            case .applied:   await loadAppliedGroups()
            }
        }.value
    }

    // MARK: - 로드

    private func loadNickname() async -> Bool {
        // 서버 mypage 응답에서 nickname만 사용 (공통 필드).
        do {
            let result = try await userService.getMypage()
            let trimmed = result.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                nickname = trimmed
            }
            return true
        } catch {
            print("홈 닉네임 로드 실패: \(error)")
            return false
        }
    }

    private func loadRecommendSections() async -> Bool {
        guard let response = try? await groupService.fetchHomeGroups() else { return false }
        recommendSections = response.sections
        return true
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
