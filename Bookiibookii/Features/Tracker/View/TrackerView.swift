import SwiftUI

// 안드로이드 TrkMainFragment 대응.
struct TrackerView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: TrackerViewModel
    private let onNavigateToGroup: () -> Void

    init(
        trackerService: TrackerService,
        libraryService: LibraryService,
        onNavigateToGroup: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: TrackerViewModel(
            service: trackerService,
            libraryService: libraryService
        ))
        self.onNavigateToGroup = onNavigateToGroup
    }

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                header
                tabSegment
                content
            }
        }
        .task { await viewModel.onAppear() }
        .toast($viewModel.toast)
        .onChange(of: viewModel.libraryBookToOpen) { _, book in
            guard let book else { return }
            container.navigationRouter.push(to: .libraryCards(book: book))
            viewModel.libraryBookToOpen = nil
        }
    }

    /// 카드 탭 시 outer NavigationStack(`BookiibookiiApp`)에 push.
    /// 함께읽기 그룹은 별도 트래커 상세 화면이 없어 `LibraryCardListView`(함께읽기 모드)로 직접 이동한다.
    private func navigate(to item: TrackerItem) {
        switch (item.role, item.exchangeType) {
        case (.host, .delivery):
            container.navigationRouter.push(to: .hostDelivery(groupId: item.groupId))
        case (.guest, .delivery):
            container.navigationRouter.push(to: .guestDelivery(groupId: item.groupId))
        case (.host, .direct):
            container.navigationRouter.push(to: .hostDirect(groupId: item.groupId))
        case (.guest, .direct):
            container.navigationRouter.push(to: .guestDirect(groupId: item.groupId))
        case (_, .none):
            // 함께읽기: groupId로 LibraryBook 매칭 후 푸시. 진행 중이면 추가 클릭은 무시.
            guard !viewModel.isOpeningLibraryCards else { return }
            Task { await viewModel.openLibraryCards(groupId: item.groupId) }
        }
    }

    // MARK: - 헤더

    private var header: some View {
        BookiiTopBar(
            title: "트래커",
            hasNotificationBadge: false,
            onProfileTap: { container.navigationRouter.push(to: .myPage) },
            onNotificationTap: { container.navigationRouter.push(to: .notification) }
        )
    }

    // MARK: - 탭 세그먼트

    private var tabSegment: some View {
        HStack(spacing: 12) {
            tabButton(.myGroup)
            tabButton(.joined)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color("grey100"))
    }

    private func tabButton(_ tab: TrackerTab) -> some View {
        let isSelected = viewModel.selectedTab == tab
        return Button {
            Task { await viewModel.selectTab(tab) }
        } label: {
            Text(tab.title)
                .pretendardText(size: 14, weight: .medium)
                .foregroundColor(isSelected ? Color("white") : Color("grey900"))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color("grey900") : Color("white"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.clear : Color("grey200"), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 본문

    @ViewBuilder
    private var content: some View {
        let items = viewModel.currentItems
        let phase = viewModel.currentPhase

        if items.isEmpty {
            emptyState(phase: phase)
        } else {
            list(items: items)
        }
    }

    @ViewBuilder
    private func emptyState(phase: TrackerViewModel.Phase) -> some View {
        ScrollView(showsIndicators: false) {
            VStack {
                switch phase {
                case .idle, .loading:
                    ProgressView()
                        .padding(.top, 80)
                case .failed(let message):
                    VStack(spacing: 16) {
                        Text(message)
                            .pretendardText(size: 14)
                            .foregroundColor(Color("grey500"))
                        Button("다시 시도") {
                            Task { await viewModel.refresh() }
                        }
                        .pretendardText(size: 14, weight: .medium)
                        .foregroundColor(Color("main200"))
                    }
                    .padding(.top, 80)
                case .refreshing, .loaded:
                    TrackerEmptyCard(
                        tab: viewModel.selectedTab,
                        onNavigateToGroup: onNavigateToGroup
                    )
                    .padding(.horizontal, 24)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .refreshable { await viewModel.refresh() }
    }

    private func list(items: [TrackerItem]) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(items) { item in
                    TrackerCard(item: item, onTap: { navigate(to: item) })
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
            .padding(.bottom, 80)
        }
        .refreshable { await viewModel.refresh() }
    }
}
