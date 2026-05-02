import SwiftUI

// 안드로이드 TrkMainFragment 대응.
struct TrackerView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: TrackerViewModel
    @State private var path = NavigationPath()
    private let trackerService: TrackerService
    private let onNavigateToGroup: () -> Void

    init(
        trackerService: TrackerService,
        onNavigateToGroup: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: TrackerViewModel(service: trackerService))
        self.trackerService = trackerService
        self.onNavigateToGroup = onNavigateToGroup
    }

    var body: some View {
        NavigationStack(path: $path) {
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
            .navigationDestination(for: TrackerItem.self) { item in
                deliveryDestination(for: item)
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
    }

    @ViewBuilder
    private func deliveryDestination(for item: TrackerItem) -> some View {
        switch (item.role, item.exchangeType) {
        case (.host, .delivery):
            HostDeliveryView(
                groupId: item.groupId,
                service: trackerService,
                onBack: { path.removeLast() }
            )
        case (.guest, .delivery):
            GuestDeliveryView(
                groupId: item.groupId,
                service: trackerService,
                onBack: { path.removeLast() }
            )
        default:
            VStack(spacing: 12) {
                Text("이번 사이클에서 미지원")
                    .font(.pretendard(size: 16, weight: .medium))
                    .foregroundColor(Color("grey700"))
                Text("직거래 / 함께읽기는 곧 지원될 예정입니다.")
                    .font(.pretendard(size: 13))
                    .foregroundColor(Color("grey500"))
                Button("뒤로") { path.removeLast() }
                    .font(.pretendard(size: 14, weight: .medium))
                    .foregroundColor(Color("main200"))
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("grey100"))
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
                    TrackerCard(item: item, onTap: { path.append(item) })
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
            .padding(.bottom, 80)
        }
        .refreshable { await viewModel.refresh() }
    }
}
