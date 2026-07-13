import SwiftUI

struct LibraryCardListView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: LibraryCardListViewModel
    @State private var isAddMenuExpanded = false

    let book: LibraryBook

    init(
        book: LibraryBook,
        libraryService: LibraryService,
        groupService: GroupService,
        trackerService: TrackerService
    ) {
        self.book = book
        _viewModel = StateObject(
            wrappedValue: LibraryCardListViewModel(
                book: book,
                libraryService: libraryService,
                groupService: groupService,
                trackerService: trackerService
            )
        )
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color("uiBg").ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        groupInfoCard

                        if viewModel.isLoading && viewModel.cards.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.top, 32)
                        } else if viewModel.cards.isEmpty {
                            emptyCard
                        } else {
                            filterBar

                            if viewModel.sortedCards.isEmpty {
                                filteredEmptyCard
                            } else {
                                cardsGrid
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 220)
                }
                .refreshable {
                    await viewModel.load()
                }
            }

            addCardMenu
                .padding(.trailing, 16)
                .padding(.bottom, 132)
        }
        .task { await viewModel.load() }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .alert("안내", isPresented: Binding(
            get: { viewModel.toastMessage != nil },
            set: { if !$0 { viewModel.toastMessage = nil } }
        )) {
            Button("확인", role: .cancel) { viewModel.toastMessage = nil }
        } message: {
            Text(viewModel.toastMessage ?? "")
        }
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
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(book.title)
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))
                .lineLimit(1)

            Spacer()

            Image("ic_meetball")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .frame(width: 40, height: 40)
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

    private var groupInfoCard: some View {
        HStack(spacing: 16) {
            BookCoverImage(imageUrl: book.coverImageURL)
                .frame(width: 102, height: 146)
                .background(Color("grey200"))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.groupName)
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey600"))
                        .lineLimit(1)

                    Text(book.title)
                        .pretendardText(size: 15, weight: .semibold)
                        .foregroundColor(Color("grey900"))
                        .lineLimit(1)

                    HStack(spacing: 2) {
                        Text(book.author ?? "-")
                        if let genre = book.genre, !genre.isEmpty {
                            Text("(\(genre))")
                        }
                    }
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey900"))
                    .lineLimit(1)

                    LibraryCardBookRating(rating: viewModel.refreshedBookRating ?? book.rating ?? 0)
                }

                Spacer()

                Text("\(formatDate(book.startDate))~ \(formatDate(book.endDate))")
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey500"))
                    .lineLimit(1)
            }
            .frame(height: 146)

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 178)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var filterBar: some View {
        HStack {
            Button {
                viewModel.showOnlyMine.toggle()
            } label: {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(viewModel.showOnlyMine ? Color("sub200") : Color("white"))
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(
                                viewModel.showOnlyMine ? Color("sub200") : Color("grey300"),
                                lineWidth: 1
                            )

                        if viewModel.showOnlyMine {
                            Image("ic_check")
                                .resizable()
                                .frame(width: 16, height: 16)
                        }
                    }
                    .frame(width: 20, height: 20)

                    Text("내 독서카드만 보기")
                        .pretendardText(size: 14, weight: .medium)
                        .foregroundColor(Color("grey500"))
                }
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 4) {
                sortButton(title: "최신순", type: .latest)
                Text("|")
                    .foregroundColor(Color("grey500"))
                sortButton(title: "페이지순", type: .page)
            }
            .pretendardText(size: 14)
        }
        .frame(height: 20)
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
                LibraryReadingCardItem(card: card) {
                    container.navigationRouter.push(
                        to: .libraryCardDetail(
                            cardId: card.id,
                            userBookId: card.isMine ? card.memberBookId : nil
                        )
                    )
                }
            }
        }
    }

    private var emptyCard: some View {
        LibraryCardEmptyMessage(
            text: "아직 독서카드가 없어요.\n기록하고 싶은 페이지를 남겨주세요."
        )
    }

    private var filteredEmptyCard: some View {
        LibraryCardEmptyMessage(text: "내 독서카드가 아직 없어요.")
    }

    private var addCardMenu: some View {
        VStack(alignment: .trailing, spacing: 12) {
            if isAddMenuExpanded {
                addMenuButton(title: "이미지 카드 추가", icon: "ic_image") {
                    isAddMenuExpanded = false
                    navigateToImageCardAdd()
                }

                addMenuButton(title: "인용구 카드 추가", icon: "ic_text") {
                    isAddMenuExpanded = false
                    viewModel.toastMessage = "인용구 카드 추가 화면은 준비 중입니다."
                }
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isAddMenuExpanded.toggle()
                }
            } label: {
                Image(isAddMenuExpanded ? "ic_x" : "ic_plus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .frame(width: 56, height: 56)
                    .background(Color("grey900"))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isAddMenuExpanded ? "독서카드 추가 메뉴 닫기" : "독서카드 추가")
        }
    }

    private func addMenuButton(
        title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Text(title)
                    .pretendardText(size: 14, weight: .medium)
            }
            .foregroundColor(Color("white"))
            .padding(.leading, 12)
            .padding(.trailing, 16)
            .frame(height: 48)
            .background(Color("grey900"))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func sortButton(
        title: String,
        type: LibraryCardListViewModel.SortType
    ) -> some View {
        Button {
            viewModel.sortType = type
        } label: {
            Text(title)
                .fontWeight(viewModel.sortType == type ? .semibold : .regular)
                .foregroundColor(
                    viewModel.sortType == type ? Color("grey800") : Color("grey500")
                )
        }
        .buttonStyle(.plain)
    }

    private func navigateToImageCardAdd() {
        guard let memberBookId = book.userBookId else {
            viewModel.toastMessage = "독서카드를 추가할 수 없습니다."
            return
        }
        container.navigationRouter.push(to: .libraryCardAdd(userBookId: memberBookId))
    }

    private func formatDate(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "-" }
        let dateOnly = String(value.prefix { $0 != "T" && $0 != " " })
        return dateOnly.replacingOccurrences(of: "-", with: ". ") + "."
    }
}

private struct LibraryCardEmptyMessage: View {
    let text: String

    var body: some View {
        Text(text)
            .pretendardText(size: 16)
            .foregroundColor(Color("grey600"))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

private struct LibraryCardBookRating: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...5, id: \.self) { index in
                Image(rating >= Double(index) - 0.5 ? "ic_star_fill" : "ic_star")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
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
            groupName: "[헤일리와 함께해요]",
            groupType: nil,
            title: "프로젝트 헤일메리",
            author: "앤디 위어",
            genre: "소설",
            coverImageURL: nil,
            hostNickname: "헤일리",
            startDate: "2025-12-18",
            endDate: "2026-01-12",
            status: .completed,
            rating: 4,
            isCreatedByMe: true,
            progressRate: 100,
            completedAtISO: "2026-01-12T00:00:00Z",
            togetherMyReadingRate: nil,
            togetherGroupReadingRate: nil,
            togetherReadingCompletedAtISO: nil
        ),
        libraryService: LibraryService(interceptor: AuthInterceptor(authService: AuthService())),
        groupService: GroupService(interceptor: AuthInterceptor(authService: AuthService())),
        trackerService: TrackerService(interceptor: AuthInterceptor(authService: AuthService()))
    )
    .environmentObject(DIContainer())
}
