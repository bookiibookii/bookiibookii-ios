import SwiftUI

// 안드로이드 fragment_home.xml 대응
// HOM-001: 헤더 + 3섹션 (진행 중인 교환 / 이런 그룹은 어떠세요? / 부키메이트)
struct HomeView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: HomeViewModel
    private let groupService: GroupService

    var onNavigateToGroup: () -> Void
    @State private var selectedGroupId: Int? = nil

    init(
        recommendationService: RecommendationService,
        groupService: GroupService,
        notificationService: NotificationService,
        onNavigateToGroup: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(
            wrappedValue: HomeViewModel(
                recommendationService: recommendationService,
                notificationService: notificationService
            )
        )
        self.groupService = groupService
        self.onNavigateToGroup = onNavigateToGroup
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
                VStack(alignment: .leading, spacing: 0) {
                    groupSection
                    mateSection
                }
                .padding(.bottom, 24)
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

    // MARK: - 섹션: 이런 그룹은 어떠세요?
    private var groupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            groupSectionHeader
            groupSectionBody
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var groupSectionHeader: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("이런 그룹은 어떠세요?")
                .pretendardText(size: 18, weight: .medium)
                .foregroundColor(Color("grey900"))
            Spacer()
            if !viewModel.recommendedGroups.isEmpty {
                refreshButton
            }
        }
    }

    private var refreshButton: some View {
        Button {
            Task { await viewModel.refreshRecommendedGroups() }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color("grey500"))
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color("white")))
                .overlay(Circle().stroke(Color("grey200"), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("새로고침")
    }

    @ViewBuilder
    private var groupSectionBody: some View {
        if viewModel.recommendedGroups.isEmpty {
            HomeEmptyCard(
                title: "아직 추천할 그룹이 없어요",
                description: "읽고 싶은 책으로 그룹을 직접 만들어보세요.",
                buttonTitle: "그룹 만들기",
                buttonStyle: .pale,
                onTap: onNavigateToGroup
            )
        } else {
            recommendedGroupGrid
        }
    }

    private var recommendedGroupGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(viewModel.recommendedGroups) { item in
                HomeRecommendedGroupCard(item: item) {
                    selectedGroupId = item.groupId
                }
            }
        }
    }

    // MARK: - 섹션 3: 부키메이트가 되어보세요!
    private var mateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("부키메이트가 되어보세요!")
            mateSectionBody
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var mateSectionBody: some View {
        if viewModel.recommendedBookmates.isEmpty {
            HomeEmptyCard(
                title: "추천할 부키메이트가 없어요",
                description: "책을 더 많이 읽고 활동하면 취향이 비슷한 메이트를 추천해드려요.",
                buttonTitle: "서재 채우기",
                buttonStyle: .pale,
                onTap: onNavigateToGroup
            )
        } else {
            mateList
        }
    }

    private var mateList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.recommendedBookmates) { mate in
                HomeMateCard(item: mate) {
                    // TODO: 타 사용자 프로필 화면이 생기면 nickname으로 이동.
                }
            }
        }
    }

    // MARK: - 공통 섹션 제목 (pretendard medium 18)
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .pretendardText(size: 18, weight: .medium)
            .foregroundColor(Color("grey900"))
    }
}
