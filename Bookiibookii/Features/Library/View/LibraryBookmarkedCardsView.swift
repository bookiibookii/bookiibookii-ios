import SwiftUI

struct LibraryBookmarkedCardsView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: LibraryBookmarkedCardsViewModel

    init(libraryService: LibraryService) {
        _viewModel = StateObject(wrappedValue: LibraryBookmarkedCardsViewModel(libraryService: libraryService))
    }

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.top, 48)
                                .frame(maxWidth: .infinity)
                        } else if viewModel.cards.isEmpty {
                            emptyState
                        } else {
                            listHeader
                            cardsGrid
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
                .refreshable { await viewModel.load() }
            }
        }
        .task { await viewModel.load() }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var header: some View {
        HStack {
            Button {
                container.navigationRouter.pop()
            } label: {
                Image("ic_back")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("grey900"))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            Spacer()
            Text("북마크한 독서카드")
                .font(.pretendard(size: 20, weight: .medium))
                .foregroundColor(Color("grey900"))
                .lineLimit(1)
            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Divider().overlay(Color("grey200"))
        }
    }

    private var listHeader: some View {
        HStack {
            Text(viewModel.cardCountText)
                .font(.pretendard(size: 14, weight: .regular))
                .foregroundColor(Color("grey700"))
            Spacer()
            HStack(spacing: 4) {
                sortButton(title: "최신순", selected: viewModel.sortType == .latest) {
                    viewModel.sortType = .latest
                }
                Text("|")
                    .font(.pretendard(size: 14, weight: .regular))
                    .foregroundColor(Color("grey500"))
                sortButton(title: "페이지순", selected: viewModel.sortType == .page) {
                    viewModel.sortType = .page
                }
            }
        }
    }

    private var cardsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            ForEach(viewModel.sortedCards) { card in
                LibraryReadingCardItem(
                    card: card,
                    onToggleBookmark: {
                        Task { await viewModel.toggleBookmark(cardId: card.id) }
                    }
                )
                .id("\(card.id)-\(card.isBookmarked)")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image("ic_bookmark")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color("grey300"))
                .frame(width: 36, height: 36)
            Text("북마크한 독서카드가 없어요")
                .font(.pretendard(size: 16, weight: .medium))
                .foregroundColor(Color("grey900"))
            Text("서재에서 카드 옆 북마크를 눌러 모아보세요.")
                .font(.pretendard(size: 14, weight: .regular))
                .foregroundColor(Color("grey600"))
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func sortButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.pretendard(size: 14, weight: selected ? .medium : .regular))
                .foregroundColor(selected ? Color("grey700") : Color("grey500"))
        }
        .buttonStyle(.plain)
    }
}
