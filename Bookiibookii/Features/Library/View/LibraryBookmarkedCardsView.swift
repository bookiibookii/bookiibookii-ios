import SwiftUI

struct LibraryBookmarkedCardsView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: LibraryBookmarkedCardsViewModel

    init(libraryService: LibraryService) {
        _viewModel = StateObject(
            wrappedValue: LibraryBookmarkedCardsViewModel(libraryService: libraryService)
        )
    }

    var body: some View {
        ZStack {
            Color("uiBg").ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if viewModel.isLoading && viewModel.cards.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.cards.isEmpty {
                    emptyState
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .frame(maxHeight: .infinity, alignment: .top)
                } else {
                    bookmarkedCards
                }
            }
        }
        .task { await viewModel.load() }
        .onReceive(NotificationCenter.default.publisher(for: .libraryCardEngagementChanged)) { _ in
            Task { await viewModel.load() }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var header: some View {
        HStack(spacing: 0) {
            HStack {
                Button {
                    container.navigationRouter.pop()
                } label: {
                    Image("ic_back")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
            }
            .frame(width: 88)

            Spacer(minLength: 0)

            Text("북마크")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))

            Spacer(minLength: 0)

            Color.clear
                .frame(width: 88, height: 40)
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color("grey200"))
                .frame(height: 1)
        }
    }

    private var bookmarkedCards: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                listHeader
                cardsGrid
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
        .refreshable {
            await viewModel.load()
        }
    }

    private var listHeader: some View {
        HStack {
            HStack(spacing: 2) {
                Text("\(viewModel.cards.count)")
                    .fontWeight(.medium)
                Text("개")
            }
            .pretendardText(size: 16)
            .foregroundColor(Color("grey900"))

            Spacer()

            HStack(spacing: 4) {
                sortButton(
                    title: "최신순",
                    selected: viewModel.sortType == .latest
                ) {
                    viewModel.sortType = .latest
                }

                Text("|")
                    .foregroundColor(Color("grey500"))

                sortButton(
                    title: "과거순",
                    selected: viewModel.sortType == .oldest
                ) {
                    viewModel.sortType = .oldest
                }
            }
            .pretendardText(size: 14)
        }
        .frame(height: 22)
    }

    private var cardsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ],
            spacing: 16
        ) {
            ForEach(viewModel.sortedCards) { card in
                LibraryReadingCardItem(
                    card: card,
                    onToggleBookmark: {
                        Task { await viewModel.toggleBookmark(cardId: card.id) }
                    },
                    onTap: {
                        container.navigationRouter.push(
                            to: .libraryBookmarkedCardDetail(
                                cardId: card.id,
                                userBookId: card.isMine ? card.memberBookId : nil
                            )
                        )
                    }
                )
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Text("아직 저장된 독서카드가 없어요.\n공감되는 독서카드를 저장해보세요.")
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey900"))
                .multilineTextAlignment(.center)

            Button {
                container.navigationRouter.pop()
            } label: {
                Text("서재로 이동하기")
                    .pretendardText(size: 15)
                    .foregroundColor(Color("white"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color("main200"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func sortButton(
        title: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .fontWeight(selected ? .semibold : .regular)
                .foregroundColor(selected ? Color("grey800") : Color("grey500"))
        }
        .buttonStyle(.plain)
    }
}
