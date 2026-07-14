import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: LibraryViewModel

    init(libraryService: LibraryService) {
        _viewModel = StateObject(wrappedValue: LibraryViewModel(libraryService: libraryService))
    }

    var body: some View {
        ZStack {
            Color("uiBg").ignoresSafeArea()

            VStack(spacing: 0) {
                header

                SearchInputField(
                    text: $viewModel.searchText,
                    hint: "그룹명, 도서명, 저자명으로 검색"
                ) {
                    Task { await viewModel.submitSearch() }
                }
                .frame(height: 56)
                .padding(.horizontal, 16)
                .padding(.top, 16)

                if !viewModel.isShowingSearchResults {
                    filterBar
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                }

                content
            }
        }
        .task {
            await viewModel.loadBooks()
        }
    }

    private var header: some View {
        BookiiTopBar(title: "서재", onProfileTap: {
            container.navigationRouter.push(to: .myPage)
        }) {
            Button {
                container.navigationRouter.push(to: .libraryBookmarkedCards)
            } label: {
                Image("ic_bookmark_empty")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.toggleLayout()
            } label: {
                HStack(spacing: 4) {
                    Image(viewModel.layoutStyle == .album ? "ic_album" : "ic_line")
                        .resizable()
                        .frame(width: 24, height: 24)

                    Text(viewModel.bookCountText)
                        .pretendardText(size: 16, weight: .medium)
                        .foregroundColor(Color("grey900"))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.layoutStyle == .album ? "목록형으로 보기" : "앨범형으로 보기")

            Spacer(minLength: 4)

            HStack(spacing: 4) {
                ForEach(Array(LibraryViewModel.SortOption.allCases.enumerated()), id: \.offset) { index, option in
                    if index > 0 {
                        Text("|")
                            .foregroundColor(Color("grey500"))
                    }

                    Button {
                        viewModel.sortOption = option
                    } label: {
                        Text(option.title)
                            .foregroundColor(viewModel.sortOption == option ? Color("main200") : Color("grey500"))
                            .fontWeight(viewModel.sortOption == option ? .semibold : .regular)
                    }
                    .buttonStyle(.plain)
                }
            }
            .pretendardText(size: 14)
            .fixedSize()
        }
        .frame(minHeight: 24)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.books.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.errorMessage, viewModel.books.isEmpty {
            LibraryMessageCard(
                message: errorMessage,
                buttonTitle: "다시 시도"
            ) {
                Task {
                    if viewModel.isShowingSearchResults {
                        await viewModel.submitSearch()
                    } else {
                        await viewModel.loadBooks()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 28)
            .frame(maxHeight: .infinity, alignment: .top)
        } else if viewModel.isShowingSearchResults {
            searchResultsContent
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 24) {
                    librarySection(
                        title: "읽는 중",
                        books: viewModel.inProgressBooks,
                        emptyMessage: "아직 진행 중인 그룹이 없어요.\n독서 메이트 매칭 현황을 확인해보세요.",
                        emptyButtonTitle: "매칭 현황 확인하기",
                        emptyAction: {
                            container.navigationRouter.push(to: .group)
                        }
                    )

                    librarySection(
                        title: "다 읽었어요",
                        books: viewModel.completedBooks,
                        emptyMessage: "아직 종료된 그룹이 없어요."
                    )

                    if !viewModel.visibleBooks.isEmpty {
                        Text("도서 DB 제공: 알라딘 인터넷서점 (www.aladin.co.kr)")
                            .pretendardText(size: 14)
                            .foregroundColor(Color("grey700"))
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 120)
            }
            .refreshable {
                await viewModel.loadBooks()
            }
        }
    }

    @ViewBuilder
    private var searchResultsContent: some View {
        if viewModel.searchResultBooks.isEmpty {
            SearchEmptyResultCard()
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .frame(maxHeight: .infinity, alignment: .top)
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 16) {
                    Text(viewModel.searchResultCountText)
                        .pretendardText(size: 15)
                        .foregroundColor(Color("grey900"))

                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.flexible(), spacing: 12, alignment: .top),
                            count: 3
                        ),
                        alignment: .leading,
                        spacing: 24
                    ) {
                        ForEach(viewModel.searchResultBooks) { book in
                            LibraryAlbumBookItem(book: book) {
                                open(book)
                            }
                        }
                    }

                    Text("도서 DB 제공: 알라딘 인터넷서점 (www.aladin.co.kr)")
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey700"))
                        .padding(.top, 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 120)
            }
            .refreshable {
                await viewModel.submitSearch()
            }
        }
    }

    private func librarySection(
        title: String,
        books: [LibraryBook],
        emptyMessage: String,
        emptyButtonTitle: String? = nil,
        emptyAction: (() -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .pretendardText(size: 20, weight: .semibold)
                .foregroundColor(Color("grey900"))

            if books.isEmpty {
                LibraryMessageCard(
                    message: emptyMessage,
                    buttonTitle: emptyButtonTitle,
                    action: emptyAction
                )
            } else {
                bookCollection(books)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func bookCollection(_ books: [LibraryBook]) -> some View {
        if viewModel.layoutStyle == .album {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8, alignment: .top), count: 3),
                alignment: .leading,
                spacing: 24
            ) {
                ForEach(books) { book in
                    LibraryAlbumBookItem(book: book) {
                        open(book)
                    }
                }
            }
        } else {
            LazyVStack(spacing: 8) {
                ForEach(books) { book in
                    LibraryListBookItem(book: book) {
                        open(book)
                    }
                }
            }
        }
    }

    private func open(_ book: LibraryBook) {
        container.navigationRouter.push(to: .libraryCards(book: book))
    }
}

private struct SearchEmptyResultCard: View {
    var body: some View {
        Text("그룹을 찾지 못했어요.\n검색어를 다시 확인해주세요.")
            .pretendardText(size: 16)
            .foregroundColor(Color("grey600"))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

private struct LibraryMessageCard: View {
    let message: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            Text(message)
                .pretendardText(size: 16, weight: buttonTitle == nil ? .regular : .medium)
                .foregroundColor(buttonTitle == nil ? Color("grey600") : Color("grey900"))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            if let buttonTitle, let action {
                Button(action: action) {
                    Text(buttonTitle)
                        .pretendardText(size: 15)
                        .foregroundColor(Color("white"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color("main200"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

private struct LibraryAlbumBookItem: View {
    let book: LibraryBook
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                BookCoverImage(imageUrl: book.coverImageURL)
                    .aspectRatio(119 / 160, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .background(Color("grey200"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(book.groupName)
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey600"))
                        .lineLimit(1)

                    Text(book.title)
                        .pretendardText(size: 15, weight: .semibold)
                        .foregroundColor(Color("grey900"))
                        .lineLimit(1)

                    if book.status == .completed {
                        LibraryRatingView(rating: book.rating ?? 0, starSize: 16)
                    } else {
                        LibraryProgressView(progress: book.progressRate, barHeight: 6)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

private struct LibraryListBookItem: View {
    let book: LibraryBook
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.groupName)
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey600"))
                        .lineLimit(1)

                    Text(book.title)
                        .pretendardText(size: 15, weight: .semibold)
                        .foregroundColor(Color("grey900"))
                        .lineLimit(1)
                }

                if book.status == .completed {
                    LibraryRatingView(rating: book.rating ?? 0, starSize: 28)
                } else {
                    LibraryProgressView(progress: book.progressRate, barHeight: 8)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("white"))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color("grey100"), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

private struct LibraryProgressView: View {
    let progress: Int
    let barHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color("grey200"))
                    Capsule()
                        .fill(Color("grey800"))
                        .frame(width: proxy.size.width * CGFloat(progress) / 100)
                }
            }
            .frame(height: barHeight)

            Text("\(progress)%")
                .pretendardText(size: 12, weight: .semibold)
                .foregroundColor(Color("grey800"))
        }
        .padding(.top, 4)
    }
}

private struct LibraryRatingView: View {
    let rating: Double
    let starSize: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...5, id: \.self) { index in
                Image(rating >= Double(index) - 0.5 ? "ic_star_fill" : "ic_star")
                    .resizable()
                    .scaledToFit()
                    .frame(width: starSize, height: starSize)
            }
        }
    }
}

#Preview {
    LibraryView(
        libraryService: LibraryService(
            interceptor: AuthInterceptor(authService: AuthService())
        )
    )
    .environmentObject(DIContainer())
}
