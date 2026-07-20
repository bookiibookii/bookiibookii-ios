import SwiftUI

// 안드 HomeScreen 대응 — 탐색 탭.
// 상단바 + 환영 섹션 + 검색·생성 행 + 고정 탭바(추천/내 그룹/신청한 그룹) + 탭별 콘텐츠.
struct HomeView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: HomeViewModel
    private let groupService: GroupService

    var onNavigateToGroup: () -> Void
    var onCreateGroupTap: () -> Void
    @State private var selectedGroupId: Int? = nil
    private static let scrollTopID = "homeScrollTop"

    init(
        groupService: GroupService,
        notificationService: NotificationService,
        userService: UserService,
        onNavigateToGroup: @escaping () -> Void = {},
        onCreateGroupTap: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(
            wrappedValue: HomeViewModel(
                groupService: groupService,
                notificationService: notificationService,
                userService: userService
            )
        )
        self.groupService = groupService
        self.onNavigateToGroup = onNavigateToGroup
        self.onCreateGroupTap = onCreateGroupTap
    }

    var body: some View {
        VStack(spacing: 0) {
            BookiiTopBar(
                title: "탐색",
                hasNotificationBadge: viewModel.hasUnreadNotification,
                onProfileTap: { container.navigationRouter.push(to: .myPage) },
                onNotificationTap: { container.navigationRouter.push(to: .notification) }
            )
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        HomeWelcomeSection(nickname: viewModel.nickname)
                            .id(Self.scrollTopID)
                        HomeSearchCreateRow(
                            onSearchTap: onNavigateToGroup,
                            onCreateGroupTap: onCreateGroupTap
                        )
                        Section(header: tabHeader) {
                            tabContent
                        }
                    }
                }
                // 콘텐츠가 짧아도 세로 바운스를 항상 허용해 pull-to-refresh가 쉽게 걸리도록 함
                .scrollBounceBehavior(.always, axes: .vertical)
                .refreshable { await viewModel.refreshCurrentTab() }
                // 탭 전환 시 이전 탭의 스크롤 오프셋이 남지 않도록 맨 위로 리셋.
                // 탭 선택/콘텐츠 교체가 커밋된 다음 틱에, 애니메이션 없이 이동해야
                // pinned 탭바가 재배치되며 튀는 현상을 막을 수 있음.
                .onChange(of: viewModel.selectedTab) { _, _ in
                    DispatchQueue.main.async {
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            proxy.scrollTo(Self.scrollTopID, anchor: .top)
                        }
                    }
                }
            }
        }
        .background(Color("grey100"))
        .task { await viewModel.onAppear() }
        .onChange(of: container.navigationRouter.destinations) { _, _ in
            Task { await viewModel.refreshNotificationBadge() }
        }
        .fullScreenCover(item: $selectedGroupId) { groupId in
            GroupDetailView(groupId: groupId, groupService: groupService)
        }
    }

    private var tabHeader: some View {
        HomeTabRow(selectedTab: viewModel.selectedTab, onSelect: viewModel.selectTab)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedTab {
        case .recommend:
            HomeRecommendContent(
                sections: viewModel.recommendSections,
                onGroupTap: { selectedGroupId = $0 },
                // 책 탭 → 그 책 제목(searchKeyword)으로 그룹 검색. 키워드가 없으면 일반 그룹 목록으로.
                onBookTap: { item in
                    let keyword = (item.searchKeyword ?? item.title ?? "")
                        .trimmingCharacters(in: .whitespaces)
                    if keyword.isEmpty {
                        onNavigateToGroup()
                    } else {
                        container.navigationRouter.push(to: .groupSearch(keyword: keyword))
                    }
                }
            )
        case .myGroups:
            HomeMyGroupsContent(
                myGroups: viewModel.myGroups,
                onGroupTap: { selectedGroupId = $0 },
                onCreateGroupTap: onCreateGroupTap
            )
        case .applied:
            HomeAppliedContent(
                appliedGroups: viewModel.appliedGroups,
                onGroupTap: { selectedGroupId = $0 },
                onExploreGroupTap: onNavigateToGroup
            )
        }
    }
}
