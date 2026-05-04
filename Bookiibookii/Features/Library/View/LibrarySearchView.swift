import SwiftUI

struct LibrarySearchView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: LibrarySearchViewModel

    init(libraryService: LibraryService) {
        _viewModel = StateObject(wrappedValue: LibrarySearchViewModel(libraryService: libraryService))
    }

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                searchHeader

                if viewModel.isShowingRecentKeywords {
                    recentKeywordSection
                } else {
                    resultSection
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var searchHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 24) {
                Button {
                    container.navigationRouter.pop()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color("grey900"))
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color("grey400"))

                    TextField("도서명, 저자명, 한 줄 평 검색", text: $viewModel.searchText)
                        .font(.pretendard(size: 14, weight: .regular))
                        .foregroundColor(Color("grey900"))
                        .submitLabel(.search)
                        .onSubmit {
                            Task { await viewModel.submitSearch() }
                        }
                }
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color("white"))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(viewModel.isShowingRecentKeywords ? Color("grey200") : Color("grey300"), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal, 16)
            .frame(height: 68)
            .background(Color("white"))
            .overlay(alignment: .bottom) {
                Divider().overlay(Color("grey200"))
            }
        }
    }

    private var recentKeywordSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("최근 검색어")
                .font(.pretendard(size: 14, weight: .regular))
                .foregroundColor(Color("grey700"))

            FlowLayout(spacing: 4) {
                ForEach(viewModel.recentKeywords, id: \.self) { keyword in
                    RecentKeywordChip(
                        text: keyword,
                        onTap: {
                            Task { await viewModel.selectRecentKeyword(keyword) }
                        },
                        onRemove: {
                            viewModel.removeRecentKeyword(keyword)
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var resultSection: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                HStack {
                    Text(viewModel.resultCountText)
                        .font(.pretendard(size: 14, weight: .regular))
                        .foregroundColor(Color("grey900"))
                    Spacer()
                }

                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 60)
                        .frame(maxWidth: .infinity)
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 24
                    ) {
                        ForEach(viewModel.resultBooks) { book in
                            LibraryBookCard(book: book) {
                                container.navigationRouter.push(to: .libraryCards(book: book))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
}

private struct RecentKeywordChip: View {
    let text: String
    let onTap: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Button(action: onTap) {
                Text(text)
                    .font(.pretendard(size: 14, weight: .regular))
                    .foregroundColor(Color("grey500"))
            }
            .buttonStyle(.plain)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Color("grey300"))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .background(Color("white"))
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color("grey200"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                height += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}

#Preview {
    LibrarySearchView(
        libraryService: LibraryService(
            interceptor: AuthInterceptor(authService: AuthService())
        )
    )
    .environmentObject(DIContainer())
}
