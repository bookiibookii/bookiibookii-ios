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
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    HomeWelcomeSection(nickname: viewModel.nickname)
                    HomeSearchCreateRow(
                        onSearchTap: onNavigateToGroup,
                        onCreateGroupTap: onCreateGroupTap
                    )
                    Section(header: tabHeader) {
                        tabContent
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
                onBookTap: { _ in onNavigateToGroup() }   // 책 → 그룹 검색(추후 키워드 검색 연결)
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
