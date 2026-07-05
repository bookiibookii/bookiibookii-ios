import SwiftUI

extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

struct GroupView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: GroupViewModel
    @State private var activeSheet: ActiveSheet? = nil
    @State private var selectedGroupId: Int? = nil

    enum ActiveSheet: String, Identifiable {
        case exchange, region, genre
        var id: String { rawValue }
    }

    init(groupService: GroupService, initialKeyword: String? = nil) {
        _viewModel = StateObject(wrappedValue: GroupViewModel(service: groupService, initialKeyword: initialKeyword))
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .background(Color("white"))
            countHeader
            listSection
        }
        .background(Color("grey100").ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(item: $activeSheet) { sheet in
            sheetContent(for: sheet)
                .presentationDragIndicator(.hidden)
                .presentationBackground(Color("white"))
        }
        .fullScreenCover(item: $selectedGroupId) { groupId in
            GroupDetailView(groupId: groupId, groupService: container.api.group, onDeleted: {
                Task { await viewModel.retry() }
            })
        }
        .task { await viewModel.onAppear() }
        .toast($viewModel.toast)
        .dismissKeyboardOnTap()
    }

    // MARK: - 상단바
    private var topBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Button {
                    container.navigationRouter.pop()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color("grey900"))
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)

                SearchInputField(
                    text: Binding(get: { viewModel.searchText }, set: { viewModel.onQueryChange($0) }),
                    onSubmit: { Task { await viewModel.onSearch() } }
                )
            }
            HStack(spacing: 8) {
                filterChip(exchangeChipLabel, active: !viewModel.tradeTypes.isEmpty) { activeSheet = .exchange }
                filterChip(regionChipLabel(viewModel.regions).isEmpty ? "지역별" : regionChipLabel(viewModel.regions),
                           active: !viewModel.regions.isEmpty) { activeSheet = .region }
                filterChip(genreChipLabel(viewModel.categories).isEmpty ? "분야별" : genreChipLabel(viewModel.categories),
                           active: !viewModel.categories.isEmpty) { activeSheet = .genre }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var exchangeChipLabel: String {
        if viewModel.tradeTypes.contains("DIRECT") { return "직접 교환" }
        if viewModel.tradeTypes.contains("DELIVERY") { return "택배 교환" }
        return "교환 방식"
    }

    private func filterChip(_ label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .pretendardText(size: 14, weight: .regular)
                .foregroundColor(active ? Color("white") : Color("grey900"))
                .padding(.horizontal, 20)
                .frame(height: 40)
                .background(Capsule().fill(active ? Color("grey900") : Color("white")))
                .overlay(Capsule().stroke(active ? Color.clear : Color("grey200"), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - N권 헤더
    @ViewBuilder private var countHeader: some View {
        if let count = viewModel.totalCount {
            Text("\(count) 권")
                .pretendardText(size: 14)
                .foregroundColor(Color("grey900"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
        }
    }

    // MARK: - 리스트
    @ViewBuilder private var listSection: some View {
        switch viewModel.loadPhase {
        case .loading where viewModel.items.isEmpty:
            centered { ProgressView().tint(Color("main200")) }
        case .failed where viewModel.items.isEmpty:
            centered {
                VStack(spacing: 8) {
                    Text(viewModel.errorMessage ?? "불러오기 실패")
                        .pretendardText(size: 14).foregroundColor(Color("grey500"))
                    Button("다시 시도") { Task { await viewModel.retry() } }
                        .pretendardText(size: 14, weight: .medium)
                        .foregroundColor(Color("main200"))
                }
            }
        default:
            if viewModel.items.isEmpty {
                centered {
                    Text(viewModel.isSearchMode ? "검색 결과가 없어요" : "조건에 맞는 그룹이 없어요")
                        .pretendardText(size: 14).foregroundColor(Color("grey500"))
                }
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { idx, item in
                            ExploreGroupCard(item: item) { selectedGroupId = item.groupId }
                                .onAppear {
                                    if idx == viewModel.items.count - 1 {
                                        Task { await viewModel.loadMore() }
                                    }
                                }
                        }
                        if viewModel.loadingMore {
                            ProgressView().tint(Color("main200")).padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    private func centered<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack { Spacer(); content(); Spacer() }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 시트
    @ViewBuilder private func sheetContent(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .exchange:
            GroupExchangeSheet(initial: viewModel.tradeTypes,
                onApply: { next in activeSheet = nil; Task { await viewModel.applyTradeTypes(next) } },
                onCancel: { activeSheet = nil })
        case .region:
            GroupRegionSheet(initial: viewModel.regions,
                onApply: { next in activeSheet = nil; Task { await viewModel.applyRegions(next) } },
                onCancel: { activeSheet = nil })
        case .genre:
            GroupGenreSheet(initial: viewModel.categories,
                onApply: { next in activeSheet = nil; Task { await viewModel.applyCategories(next) } },
                onCancel: { activeSheet = nil })
        }
    }

}
