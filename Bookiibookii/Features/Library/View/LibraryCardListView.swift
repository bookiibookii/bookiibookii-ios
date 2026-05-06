import SwiftUI

struct LibraryCardListView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: LibraryCardListViewModel

    let book: LibraryBook

    init(book: LibraryBook, libraryService: LibraryService) {
        self.book = book
        _viewModel = StateObject(
            wrappedValue: LibraryCardListViewModel(groupId: book.groupId, libraryService: libraryService)
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        groupInfoCard
                        if viewModel.isLoading {
                            ProgressView().padding(.top, 40)
                        } else if viewModel.cards.isEmpty {
                            emptyCard
                        } else {
                            listHeader
                            cardsGrid
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, viewModel.cards.isEmpty ? 24 : 112)
                }
            }

            if !viewModel.cards.isEmpty {
                addCardButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
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
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("grey900"))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            Spacer()
            Text(book.title)
                .font(.pretendard(size: 20, weight: .medium))
                .foregroundColor(Color("grey900"))
                .lineLimit(1)
            Spacer()

            HeaderCircleButton(systemName: "ellipsis")
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Divider().overlay(Color("grey200"))
        }
    }

    private var groupInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Color("grey300")
                    .frame(width: 92, height: 118)
                    .overlay(
                        AsyncImage(url: URL(string: book.coverImageURL ?? "")) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            case .empty, .failure:
                                EmptyView()
                            @unknown default:
                                EmptyView()
                            }
                        }
                    )
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle().fill(Color("grey300")).frame(width: 20, height: 20)
                        Text(book.hostNickname)
                            .font(.pretendard(size: 12, weight: .medium))
                            .foregroundColor(Color("grey700"))
                    }
                    Text(book.title)
                        .font(.pretendard(size: 14, weight: .regular))
                        .foregroundColor(Color("grey900"))
                    HStack(spacing: 4) {
                        Text(book.author ?? "-")
                            .font(.pretendard(size: 12, weight: .regular))
                            .foregroundColor(Color("grey500"))
                        Text("(소설)")
                            .font(.pretendard(size: 11, weight: .regular))
                            .foregroundColor(Color("grey500"))
                    }
                    StarRow(rating: book.rating ?? 0)
                    Text("\(formatDate(book.startDate)) ~ \(formatDate(book.endDate))")
                        .font(.pretendard(size: 11, weight: .regular))
                        .foregroundColor(Color("grey400"))
                }
            }

            Divider().overlay(Color("grey100"))

            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.topComments) { comment in
                    HStack(spacing: 8) {
                        Text(comment.nickname)
                            .font(.pretendard(size: 11, weight: .regular))
                            .foregroundColor(Color("grey600"))
                        Text("\"\(comment.comment)\"")
                            .font(.pretendard(size: 11, weight: .regular))
                            .foregroundColor(Color("grey800"))
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
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
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(viewModel.sortedCards) { card in
                LibraryReadingCardItem(
                    card: card,
                    onToggleBookmark: {
                        Task { await viewModel.toggleBookmark(cardId: card.id) }
                    },
                    onTap: {
                        guard card.isBookmarkable else { return }
                        container.navigationRouter.push(to: .libraryCardDetail(cardId: card.id, userBookId: book.userBookId))
                    }
                )
                .id("\(card.id)-\(card.isBookmarked)")
            }
        }
    }

    private var emptyCard: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("아직 독서카드가 없어요")
                    .font(.pretendard(size: 16, weight: .medium))
                    .foregroundColor(Color("grey900"))
                Text("마음에 드는 내용을 기록으로 남겨요.")
                    .font(.pretendard(size: 14, weight: .regular))
                    .foregroundColor(Color("grey600"))
            }

            Button("독서카드 추가하기") {
                navigateToCardAddIfPossible()
            }
                .font(.pretendard(size: 15, weight: .regular))
                .foregroundColor(Color("main200"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color("main100"))
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var addCardButton: some View {
        Button("독서카드 추가하기") {
            navigateToCardAddIfPossible()
        }
            .font(.pretendard(size: 18, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(Color("grey900"))
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func navigateToCardAddIfPossible() {
        guard let uid = book.userBookId else { return }
        container.navigationRouter.push(to: .libraryCardAdd(userBookId: uid))
    }

    private func sortButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.pretendard(size: 14, weight: selected ? .medium : .regular))
                .foregroundColor(selected ? Color("grey700") : Color("grey500"))
        }
        .buttonStyle(.plain)
    }

    private func formatDate(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "-" }
        return value.replacingOccurrences(of: "-", with: ". ") + "."
    }
}

private struct HeaderCircleButton: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(Color("grey700"))
            .frame(width: 40, height: 40)
    }
}

private struct StarRow: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { index in
                let filled = Double(index + 1) <= rating
                Image(systemName: filled ? "star.fill" : "star")
                    .font(.system(size: 10))
                    .foregroundColor(Color("main100"))
            }
        }
    }
}

#Preview {
    LibraryCardListView(
        book: LibraryBook(
            id: 1,
            userBookId: 1,
            groupId: 1,
            title: "괴테는 모든 것을 말했다",
            author: "스즈키 유이",
            coverImageURL: nil,
            hostNickname: "noshel",
            startDate: "2025-12-18",
            endDate: "2026-01-12",
            status: .completed,
            rating: 3.5,
            isCreatedByMe: true
        ),
        libraryService: LibraryService(interceptor: AuthInterceptor(authService: AuthService()))
    )
    .environmentObject(DIContainer())
}
