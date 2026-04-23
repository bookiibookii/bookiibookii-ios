import SwiftUI

struct GroupSearchView: View {
    @StateObject private var viewModel: GroupSearchViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool

    init(groupService: GroupService) {
        _viewModel = StateObject(wrappedValue: GroupSearchViewModel(service: groupService))
    }

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()
            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                Divider().background(Color("grey200"))
                if viewModel.phase == .before {
                    beforeContent
                } else {
                    resultsContent
                }
            }
        }
        .task { await viewModel.onAppear() }
        .toast($viewModel.toast)
        .onAppear { isSearchFocused = true }
    }

    // MARK: - 검색바

    private var searchBar: some View {
        HStack(spacing: 8) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("grey900"))
                    .frame(width: 40, height: 40)
                    .background(Color("white"))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Image("ic_search")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color("grey500"))
                TextField("도서명, 저자명, 태그 검색", text: $viewModel.searchText)
                    .font(.pretendard(size: 14))
                    .foregroundColor(Color("grey900"))
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .onSubmit { Task { await viewModel.submitSearch(viewModel.searchText) } }
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.clearSearch()
                        isSearchFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color("grey400"))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("grey200"), lineWidth: 1))
        }
    }

    // MARK: - Before 상태

    private var beforeContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                if !viewModel.recentSearches.isEmpty { recentSearchSection }
                popularKeywordsSection
                createGroupCTA
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
    }

    private var recentSearchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("최근 검색어")
                .font(.pretendard(size: 14, weight: .medium))
                .foregroundColor(Color("grey700"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.recentSearches, id: \.self) { keyword in
                        recentChip(keyword)
                    }
                }
            }
        }
    }

    private func recentChip(_ keyword: String) -> some View {
        HStack(spacing: 6) {
            Button { Task { await viewModel.submitSearch(keyword) } } label: {
                Text(keyword)
                    .font(.pretendard(size: 13))
                    .foregroundColor(Color("grey700"))
            }
            .buttonStyle(.plain)
            Button { viewModel.removeRecentSearch(keyword) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color("grey400"))
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .frame(height: 34)
        .background(Color("white"))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color("grey200"), lineWidth: 1))
    }

    private var popularKeywordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button { viewModel.togglePopularExpanded() } label: {
                HStack {
                    Text("인기 검색어")
                        .font(.pretendard(size: 16, weight: .medium))
                        .foregroundColor(Color("grey900"))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("grey700"))
                        .rotationEffect(.degrees(viewModel.isPopularExpanded ? 180 : 0))
                        .animation(.easeOut(duration: 0.2), value: viewModel.isPopularExpanded)
                }
            }
            .buttonStyle(.plain)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.visiblePopularKeywords.enumerated()), id: \.offset) { idx, keyword in
                    popularRow(rank: idx + 1, keyword: keyword)
                    if idx < viewModel.visiblePopularKeywords.count - 1 {
                        Divider().background(Color("grey200"))
                    }
                }
            }
            .background(Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func popularRow(rank: Int, keyword: String) -> some View {
        let top3 = rank <= 3
        return Button { Task { await viewModel.submitSearch(keyword) } } label: {
            HStack(spacing: 8) {
                Text(String(format: "%02d", rank))
                    .font(.pretendard(size: 14, weight: .semibold))
                    .foregroundColor(top3 ? Color("main200") : Color("grey500"))
                    .frame(width: 20, alignment: .center)
                Text(keyword)
                    .font(.pretendard(size: 14))
                    .foregroundColor(top3 ? Color("grey900") : Color("grey500"))
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
        }
        .buttonStyle(.plain)
    }

    private var createGroupCTA: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("아직 그룹을 만들지 않았어요 😭")
                    .font(.pretendard(size: 16, weight: .medium))
                    .foregroundColor(Color("grey900"))
                    .multilineTextAlignment(.center)
                Text("읽고 싶은 책을 골라 그룹을 만들어볼까요?")
                    .font(.pretendard(size: 14))
                    .foregroundColor(Color("grey600"))
                    .multilineTextAlignment(.center)
            }
            Button { viewModel.toast = "그룹 만들기는 준비 중입니다" } label: {
                Text("그룹 만들기")
                    .font(.pretendard(size: 15))
                    .foregroundColor(Color("grey100"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color("grey900"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - Results 상태

    private var resultsContent: some View {
        VStack(spacing: 0) {
            resultsHeader
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            Divider().background(Color("grey200"))
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    if viewModel.loadPhase == .loading {
                        ProgressView().padding(.top, 80)
                    } else if viewModel.searchResults.isEmpty {
                        emptyState.padding(.top, 80)
                    } else {
                        ForEach(Array(viewModel.searchResults.enumerated()), id: \.element.id) { idx, item in
                            GroupCard(item: item) {
                                viewModel.toast = "그룹 상세는 준비 중입니다"
                            }
                            .onAppear {
                                if idx == viewModel.searchResults.count - 1 {
                                    Task { await viewModel.loadNextPage() }
                                }
                            }
                        }
                        if viewModel.loadPhase == .loadingMore {
                            ProgressView().padding(.vertical, 16)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
    }

    private var resultsHeader: some View {
        HStack {
            Text("그룹 \(viewModel.resultCount)개")
                .font(.pretendard(size: 13))
                .foregroundColor(Color("grey500"))
            Spacer()
            sortButton(.latest)
            Text("|")
                .font(.pretendard(size: 14))
                .foregroundColor(Color("grey400"))
                .padding(.horizontal, 6)
            sortButton(.popular)
        }
    }

    private func sortButton(_ sort: GroupSort) -> some View {
        let active = viewModel.resultSort == sort
        return Button { Task { await viewModel.changeResultSort(sort) } } label: {
            Text(sort.displayName)
                .font(.pretendard(size: 14, weight: active ? .medium : .regular))
                .foregroundColor(active ? Color("main200") : Color("grey500"))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var emptyState: some View {
        if viewModel.loadPhase == .failed {
            VStack(spacing: 16) {
                Text("검색 결과를 불러오지 못했어요")
                    .font(.pretendard(size: 14))
                    .foregroundColor(Color("grey500"))
                Button("다시 시도") { Task { await viewModel.submitSearch(viewModel.searchText) } }
                    .font(.pretendard(size: 14, weight: .medium))
                    .foregroundColor(Color("main200"))
            }
        } else {
            Text("검색 결과가 없어요")
                .font(.pretendard(size: 14))
                .foregroundColor(Color("grey500"))
        }
    }
}
