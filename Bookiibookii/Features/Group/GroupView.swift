import SwiftUI

struct GroupView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: GroupViewModel
    @State private var activeSheet: ActiveSheet? = nil
    @State private var isFabOpen: Bool = false
    @State private var isSearchPresented: Bool = false
    @State private var activeCreate: CreateType? = nil

    enum ActiveSheet: String, Identifiable {
        case groupType, region, category
        var id: String { rawValue }
    }

    enum CreateType: String, Identifiable {
        case relay, together
        var id: String { rawValue }
    }

    init(groupService: GroupService) {
        _viewModel = StateObject(wrappedValue: GroupViewModel(service: groupService))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                filterChipsRow
                    .padding(.top, 16)

                sortRow
                    .padding(.horizontal, 24)
                    .padding(.top, 32)

                listSection
                    .padding(.top, 12)
            }

            GroupFabMenu(
                isOpen: $isFabOpen,
                onTapTogether: {
                    withAnimation(.easeOut(duration: 0.25)) { isFabOpen = false }
                    activeCreate = .together
                },
                onTapRelay: {
                    withAnimation(.easeOut(duration: 0.25)) { isFabOpen = false }
                    activeCreate = .relay
                }
            )
            .padding(.trailing, 24)
            .padding(.bottom, 16)
        }
        .sheet(item: $activeSheet) { sheet in
            sheetContent(for: sheet)
        }
        .fullScreenCover(isPresented: $isSearchPresented) {
            GroupSearchView(groupService: container.api.group)
        }
        .fullScreenCover(item: $activeCreate) { type in
            switch type {
            case .relay:
                GroupRelayCreateView(groupService: container.api.group)
            case .together:
                GroupTogetherCreateView(groupService: container.api.group)
            }
        }
        .task { await viewModel.onAppear() }
        .toast($viewModel.toast)
    }

    // MARK: - 헤더

    private var header: some View {
        HStack {
            Text("그룹")
                .font(.pretendard(size: 24, weight: .bold))
                .foregroundColor(Color("grey700"))
            Spacer()
            Button {
                isSearchPresented = true
            } label: {
                Image("ic_search")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color("grey900"))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle().stroke(Color("grey200"), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 필터 칩 Row

    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(
                    label: groupTypeChipLabel,
                    isActive: !viewModel.groupTypes.isEmpty,
                    action: { activeSheet = .groupType }
                )
                filterChip(
                    label: viewModel.region.chipLabel,
                    isActive: !viewModel.region.isAll,
                    action: { activeSheet = .region }
                )
                filterChip(
                    label: categoryChipLabel,
                    isActive: !viewModel.categories.isEmpty,
                    action: { activeSheet = .category }
                )
            }
            .padding(.horizontal, 24)
        }
    }

    private var groupTypeChipLabel: String {
        if viewModel.groupTypes.isEmpty { return "그룹 유형" }
        return chipSummary(viewModel.groupTypes.map(\.displayName))
    }

    private var categoryChipLabel: String {
        if viewModel.categories.isEmpty { return "분야별" }
        return chipSummary(viewModel.categories.map(\.displayName))
    }

    /// 최대 3개까지 · 구분, 그 이상은 "외 N개"
    private func chipSummary(_ items: [String]) -> String {
        let sorted = items
        if sorted.count <= 3 { return sorted.joined(separator: " · ") }
        let head = sorted.prefix(3).joined(separator: " · ")
        return "\(head) 외 \(sorted.count - 3)개"
    }

    private func filterChip(label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.pretendard(size: 13, weight: isActive ? .medium : .regular))
                .foregroundColor(isActive ? Color("white") : Color("grey500"))
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(
                    Capsule().fill(isActive ? Color("grey900") : Color("white"))
                )
                .overlay(
                    Capsule().stroke(
                        isActive ? Color.clear : Color("grey200"),
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 정렬 Row

    private var sortRow: some View {
        HStack(spacing: 4) {
            Spacer()
            sortItem(.recommend)
            sortDivider
            sortItem(.latest)
            sortDivider
            sortItem(.popular)
        }
    }

    private func sortItem(_ sort: GroupSort) -> some View {
        let isActive = viewModel.sort == sort
        return Button {
            Task { await viewModel.changeSort(sort) }
        } label: {
            Text(sort.displayName)
                .font(.pretendard(size: 14, weight: isActive ? .medium : .regular))
                .foregroundColor(isActive ? Color("main200") : Color("grey500"))
        }
        .buttonStyle(.plain)
    }

    private var sortDivider: some View {
        Text("|")
            .font(.pretendard(size: 14))
            .foregroundColor(Color("grey400"))
            .padding(.horizontal, 4)
    }

    // MARK: - 리스트

    @ViewBuilder
    private var listSection: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                if viewModel.items.isEmpty {
                    emptyOrLoadingState
                        .padding(.top, 80)
                } else {
                    ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { idx, item in
                        GroupCard(item: item) {
                            viewModel.showComingSoon("그룹 상세는 준비 중입니다")
                        }
                        .onAppear {
                            if idx == viewModel.items.count - 1 {
                                Task { await viewModel.loadNextPage() }
                            }
                        }
                    }
                    if viewModel.phase == .loadingMore {
                        ProgressView().padding(.vertical, 16)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 80)
        }
        .refreshable { await viewModel.refresh() }
    }

    @ViewBuilder
    private var emptyOrLoadingState: some View {
        switch viewModel.phase {
        case .loading, .refreshing:
            ProgressView()
        case .failed:
            VStack(spacing: 16) {
                Text("불러오기 실패")
                    .font(.pretendard(size: 14))
                    .foregroundColor(Color("grey500"))
                Button("다시 시도") {
                    Task { await viewModel.refresh() }
                }
                .font(.pretendard(size: 14, weight: .medium))
                .foregroundColor(Color("main200"))
            }
        default:
            Text("조건에 맞는 그룹이 없어요")
                .font(.pretendard(size: 14))
                .foregroundColor(Color("grey500"))
        }
    }

    // MARK: - 바텀시트 분기

    @ViewBuilder
    private func sheetContent(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .groupType:
            GroupFilterSheet<GroupTypeFilter>(
                kind: .groupType,
                title: "그룹 유형",
                items: GroupTypeFilter.allCases,
                itemDisplay: { $0.displayName },
                preSelected: viewModel.groupTypes,
                onConfirm: { next in
                    Task { await viewModel.applyGroupTypes(next) }
                }
            )
            .presentationDetents([.height(220)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(Color("white"))

        case .category:
            GroupFilterSheet<CategoryFilter>(
                kind: .category,
                title: "분야별",
                items: CategoryFilter.allCases,
                itemDisplay: { $0.displayName },
                preSelected: viewModel.categories,
                onConfirm: { next in
                    Task { await viewModel.applyCategories(next) }
                }
            )
            .presentationDetents([.height(370)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(Color("white"))

        case .region:
            GroupRegionSheet(
                preSelected: viewModel.region,
                onConfirm: { next in
                    Task { await viewModel.applyRegion(next) }
                }
            )
            .presentationDetents([.height(420)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(Color("white"))
        }
    }
}
