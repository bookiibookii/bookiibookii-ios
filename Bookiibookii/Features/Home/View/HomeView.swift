import SwiftUI

// 안드로이드 fragment_home.xml 대응
// HOM-001: 헤더 + 3섹션 (진행 중인 교환 / 이런 그룹은 어떠세요? / 부키메이트)
struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    private let groupService: GroupService
    private let notificationService: NotificationService
    private let keywordService: KeywordService

    var onNavigateToGroup: () -> Void
    @State private var selectedGroupId: Int? = nil
    @State private var showNotification = false
    @State private var exchangePage: Int = 0

    init(
        recommendationService: RecommendationService,
        groupService: GroupService,
        notificationService: NotificationService,
        keywordService: KeywordService,
        trackerService: TrackerService,
        onNavigateToGroup: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(
            wrappedValue: HomeViewModel(
                recommendationService: recommendationService,
                notificationService: notificationService,
                trackerService: trackerService
            )
        )
        self.groupService = groupService
        self.notificationService = notificationService
        self.keywordService = keywordService
        self.onNavigateToGroup = onNavigateToGroup
    }

    var body: some View {
        VStack(spacing: 0) {
            HomeHeaderView(
                hasNotificationBadge: viewModel.hasUnreadNotification,
                onTapNotification: { showNotification = true }
            )
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    exchangeSection
                    groupSection
                    mateSection
                }
                .padding(.bottom, 24)
            }
        }
        .background(Color("grey100"))
        .task { await viewModel.onAppear() }
        .fullScreenCover(item: $selectedGroupId) { groupId in
            GroupDetailView(groupId: groupId, groupService: groupService)
        }
        .fullScreenCover(isPresented: $showNotification, onDismiss: {
            Task { await viewModel.refreshNotificationBadge() }
        }) {
            NotificationView(
                notificationService: notificationService,
                keywordService: keywordService,
                groupService: groupService
            )
        }
    }

    // MARK: - 섹션 1: 진행 중인 교환
    // 안드 section_home_exchange_progress.xml + HomeFragment.loadExchangeProgress 대응.
    private var exchangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            exchangeHeader
            exchangeBody
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .task { await viewModel.loadActiveExchanges() }
        .onChange(of: viewModel.activeExchanges.count) { _, newValue in
            // 데이터 새로고침되면 첫 페이지로
            exchangePage = min(exchangePage, max(0, newValue - 1))
        }
    }

    private var exchangeHeader: some View {
        HStack(alignment: .center, spacing: 8) {
            sectionTitle("진행 중인 교환")
            Spacer()
            if viewModel.activeExchanges.count > 1 {
                exchangePageControl
            }
        }
    }

    private var exchangePageControl: some View {
        let total = viewModel.activeExchanges.count
        let hasPrev = exchangePage > 0
        let hasNext = exchangePage < total - 1
        return HStack(spacing: 8) {
            arrowButton(direction: .left, enabled: hasPrev) {
                if hasPrev { withAnimation { exchangePage -= 1 } }
            }
            (
                Text("\(exchangePage + 1)")
                    .font(.pretendard(size: 14, weight: .bold))
                    .tracking(14 * -0.01)
                    .foregroundColor(Color("grey900"))
                + Text("/\(total)")
                    .font(.pretendard(size: 14))
                    .tracking(14 * -0.01)
                    .foregroundColor(Color("grey600"))
            )
            arrowButton(direction: .right, enabled: hasNext) {
                if hasNext { withAnimation { exchangePage += 1 } }
            }
        }
    }

    private enum ArrowDirection { case left, right }

    private func arrowButton(direction: ArrowDirection, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image("ic_back")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 20, height: 20)
                .rotationEffect(direction == .right ? .degrees(180) : .zero)
                .foregroundColor(Color("grey900"))
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color("white")))
                .overlay(Circle().stroke(Color("grey200"), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1.0 : 0.5)
    }

    @ViewBuilder
    private var exchangeBody: some View {
        if viewModel.activeExchanges.isEmpty {
            HomeEmptyCard(
                title: "아직 진행 중인 교환이 없어요",
                description: "그룹에 참여하고 새로운 책을 만나보세요.",
                buttonTitle: "그룹 둘러보기",
                buttonStyle: .dark,
                onTap: onNavigateToGroup
            )
        } else {
            TabView(selection: $exchangePage) {
                ForEach(Array(viewModel.activeExchanges.enumerated()), id: \.offset) { index, item in
                    TrackerCard(item: item, onTap: {})
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 215)
        }
    }

    // MARK: - 섹션 2: 이런 그룹은 어떠세요?
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
