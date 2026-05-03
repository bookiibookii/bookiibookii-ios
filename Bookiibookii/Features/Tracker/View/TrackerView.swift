import SwiftUI

// 안드로이드 TrkMainFragment 대응.
struct TrackerView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: TrackerViewModel
    private let onNavigateToGroup: () -> Void

    init(
        trackerService: TrackerService,
        onNavigateToGroup: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: TrackerViewModel(service: trackerService))
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
    }

    /// 카드 탭 시 outer NavigationStack(`BookiibookiiApp`)에 push.
    /// 직거래 / 함께읽기는 이번 사이클 미지원 → 토스트로 안내.
    private func navigate(to item: TrackerItem) {
        switch (item.role, item.exchangeType) {
        case (.host, .delivery):
            container.navigationRouter.push(to: .hostDelivery(groupId: item.groupId))
        case (.guest, .delivery):
            container.navigationRouter.push(to: .guestDelivery(groupId: item.groupId))
        default:
            viewModel.toast = "이번 사이클에서 미지원"
        }
    }

    // MARK: - 헤더

    private var header: some View {
        HStack {
            Text("북 트래커")
                .font(.pretendard(size: 24, weight: .medium))
                .foregroundColor(Color("grey800"))
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 17)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color("grey200"))
                .frame(height: 1)
        }
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
                .font(.pretendard(size: 14, weight: .medium))
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
                            .font(.pretendard(size: 14))
                            .foregroundColor(Color("grey500"))
                        Button("다시 시도") {
                            Task { await viewModel.refresh() }
                        }
                        .font(.pretendard(size: 14, weight: .medium))
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
