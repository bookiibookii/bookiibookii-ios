import SwiftUI
import Kingfisher

struct MyBookShelfView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: MyBookShelfViewModel

    init(userService: UserService, groupService: GroupService) {
        _viewModel = StateObject(
            wrappedValue: MyBookShelfViewModel(userService: userService, groupService: groupService)
        )
    }

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if viewModel.isLoading && viewModel.representativeBooks.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            representativeSection
                            Color.clear.frame(height: 8)
                            favoriteSection

                            if viewModel.completedBooks.isEmpty {
                                completedEmptySection
                            } else {
                                completedFilterSection
                                completedContentSection
                            }
                        }
                        .padding(.bottom, 32)
                    }
                }
            }

            if viewModel.isFavoriteSearchPresented {
                LifeBookSearchDialog(
                    searchQuery: $viewModel.favoriteSearchQuery,
                    searchResults: viewModel.favoriteSearchResults,
                    isSearching: viewModel.isFavoriteSearching,
                    isSubmitting: viewModel.isFavoriteMutating,
                    onSearch: { viewModel.onFavoriteSearchQueryChanged() },
                    onSelect: { book in
                        Task { await viewModel.selectFavoriteBook(book) }
                    },
                    onDismiss: { viewModel.closeFavoriteSearch() }
                )
                .transition(.opacity)
            }
        }
        .task { await viewModel.load() }
        .alert("안내", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $viewModel.isRepresentativeEditSheetPresented) {
            RepresentativeBooksEditSheet(viewModel: viewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(20)
        }
        .onChange(of: viewModel.isRepresentativeEditSheetPresented) { _, isPresented in
            if !isPresented {
                Task { await viewModel.load() }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { container.navigationRouter.pop() } label: {
                Image("ic_back")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("나의 책장")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))

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

    // MARK: - Representative

    private var representativeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Text("나를 대표하는 책")
                        .pretendardText(size: 16, weight: .semibold)
                        .foregroundColor(Color("grey900"))

                    countBadge(viewModel.representativeCountText)
                }

                Spacer()

                Button {
                    viewModel.openRepresentativeEdit()
                } label: {
                    Text("수정")
                        .pretendardText(size: 11, weight: .medium)
                        .foregroundColor(Color("grey700"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("grey200"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.representativeBooks.isEmpty)
                .opacity(viewModel.representativeBooks.isEmpty ? 0.4 : 1)
            }

            if viewModel.representativeBooks.isEmpty {
                Text("대표 책을 등록해 보세요.")
                    .pretendardText(size: 14, weight: .regular)
                    .foregroundColor(Color("grey500"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(Array(viewModel.representativeBooks.enumerated()), id: \.element.id) { index, book in
                            BookshelfRepresentativeSpine(
                                title: book.title.stripBookSubtitle(),
                                colorIndex: index
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
    }

    // MARK: - Favorite

    private var favoriteSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("나의 인생 책")
                        .pretendardText(size: 16, weight: .semibold)
                        .foregroundColor(Color("grey900"))

                    countBadge(viewModel.favoriteCountText)
                }

                Text("부키부키에서 읽지 않은 책도 등록할 수 있어요.")
                    .pretendardText(size: 14, weight: .regular)
                    .foregroundColor(Color("grey500"))
            }

            HStack(alignment: .top, spacing: 12) {
                ForEach(0..<MyBookShelfViewModel.maxFavoriteCount, id: \.self) { index in
                    if index < viewModel.favoriteBooks.count {
                        favoriteBookCard(viewModel.favoriteBooks[index])
                    } else {
                        favoriteAddSlot
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
    }

    private func favoriteBookCard(_ book: BookshelfFavoriteBook) -> some View {
        let showDelete = viewModel.favoriteBooks.count >= 2

        return VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                bookCover(imageURL: book.image, height: 170)

                Button {
                    if showDelete {
                        Task { await viewModel.deleteFavoriteBook(userBookId: book.userBookId) }
                    } else {
                        viewModel.openFavoriteReplaceSearch(userBookId: book.userBookId)
                    }
                } label: {
                    favoriteActionIcon(showDelete: showDelete)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isFavoriteMutating)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title.stripBookSubtitle())
                    .pretendardText(size: 14, weight: .semibold)
                    .foregroundColor(Color("grey900"))
                    .lineLimit(1)

                Text(book.authorWithCategory)
                    .pretendardText(size: 14, weight: .regular)
                    .foregroundColor(Color("grey700"))
                    .lineLimit(1)
            }
        }
        .frame(width: 119, alignment: .leading)
    }

    private var favoriteAddSlot: some View {
        Button {
            viewModel.openFavoriteAddSearch()
        } label: {
            ZStack {
                Color("grey200")
                Image("ic_plus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color("grey400"))
            }
            .frame(width: 119, height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(
            viewModel.favoriteBooks.count >= MyBookShelfViewModel.maxFavoriteCount ||
            viewModel.isFavoriteMutating
        )
        .opacity(viewModel.favoriteBooks.count >= MyBookShelfViewModel.maxFavoriteCount ? 0.4 : 1)
    }

    @ViewBuilder
    private func favoriteActionIcon(showDelete: Bool) -> some View {
        ZStack {
            Circle()
                .fill(Color("grey100"))
                .frame(width: 24, height: 24)

            Image(showDelete ? "ic_x" : "ic_edit")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
        }
        .padding(8)
    }

    // MARK: - Completed Empty

    private var completedEmptySection: some View {
        Text("아직 완독한 도서가 없어요.")
            .pretendardText(size: 16, weight: .regular)
            .foregroundColor(Color("grey600"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 24)
            .background(Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 16)
            .padding(.top, 24)
    }

    // MARK: - Completed Filter

    private var completedFilterSection: some View {
        HStack(alignment: .center) {
            Button {
                viewModel.isGridView.toggle()
            } label: {
                HStack(spacing: 4) {
                    Image(viewModel.isGridView ? "ic_album" : "ic_line")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)

                    HStack(spacing: 2) {
                        Text("\(viewModel.completedBooks.count)")
                            .pretendardText(size: 16, weight: .medium)
                            .foregroundColor(Color("grey900"))
                        Text("권")
                            .pretendardText(size: 16, weight: .regular)
                            .foregroundColor(Color("grey900"))
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer(minLength: 8)

            sortOptions
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    private var sortOptions: some View {
        HStack(spacing: 4) {
            ForEach(Array(CompletedBookSort.allCases.enumerated()), id: \.element) { index, option in
                if index > 0 {
                    Text("|")
                        .pretendardText(size: 14, weight: .regular)
                        .foregroundColor(Color("grey500"))
                }

                Button {
                    viewModel.sort = option
                } label: {
                    Text(option.label)
                        .pretendardText(size: 14, weight: viewModel.sort == option ? .semibold : .regular)
                        .foregroundColor(viewModel.sort == option ? Color("main200") : Color("grey500"))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Completed Content

    @ViewBuilder
    private var completedContentSection: some View {
        if viewModel.isGridView {
            completedGridView
        } else {
            completedListView
        }
    }

    private var completedGridView: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]

        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.sortedCompletedBooks) { book in
                completedGridCard(book)
            }
        }
        .padding(.horizontal, 16)
    }

    private func completedGridCard(_ book: BookshelfCompletedBook) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                bookCover(imageURL: book.image, height: 170)

                if viewModel.isRepresentative(book) {
                    representativeBadge
                        .padding(8)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                if let date = book.formattedCompletedDate {
                    Text(date)
                        .pretendardText(size: 12, weight: .regular)
                        .foregroundColor(Color("grey700"))
                        .lineLimit(1)
                }

                Text(book.title.stripBookSubtitle())
                    .pretendardText(size: 14, weight: .semibold)
                    .foregroundColor(Color("grey900"))
                    .lineLimit(1)

                Text(book.authorWithCategory)
                    .pretendardText(size: 14, weight: .regular)
                    .foregroundColor(Color("grey700"))
                    .lineLimit(1)

                if let rating = book.rating {
                    BookshelfStarRating(rating: rating)
                }
            }
        }
    }

    private var completedListView: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.sortedCompletedBooks) { book in
                completedListCard(book)
            }
        }
        .padding(.horizontal, 16)
    }

    private func completedListCard(_ book: BookshelfCompletedBook) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                HStack(spacing: 4) {
                    if viewModel.isRepresentative(book) {
                        representativeBadge
                    }

                    Text(book.title.stripBookSubtitle())
                        .pretendardText(size: 14, weight: .semibold)
                        .foregroundColor(Color("grey900"))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                if let rating = book.rating {
                    BookshelfStarRating(rating: rating)
                }
            }

            HStack {
                HStack(spacing: 2) {
                    Text(book.author)
                        .pretendardText(size: 14, weight: .regular)
                        .foregroundColor(Color("grey900"))
                        .lineLimit(1)

                    if let category = book.category, !category.isEmpty {
                        Text("(\(category))")
                            .pretendardText(size: 14, weight: .regular)
                            .foregroundColor(Color("grey900"))
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                if let date = book.formattedCompletedDate {
                    Text(date)
                        .pretendardText(size: 14, weight: .regular)
                        .foregroundColor(Color("grey700"))
                        .lineLimit(1)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color("grey100"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Shared

    private func countBadge(_ text: String) -> some View {
        Text(text)
            .pretendardText(size: 11, weight: .medium)
            .foregroundColor(Color("grey900"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color("white"))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color("grey200"), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var representativeBadge: some View {
        Text("대표")
            .pretendardText(size: 11, weight: .medium)
            .foregroundColor(Color("main200"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color("main100"))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func bookCover(imageURL: String, height: CGFloat) -> some View {
        KFImage(URL(string: imageURL))
            .placeholder {
                Color("grey200")
            }
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Representative Spine

private struct BookshelfRepresentativeSpine: View {
    let title: String
    let colorIndex: Int

    @State private var titleNaturalSize: CGSize = .zero

    private var textColor: Color {
        colorIndex.isMultiple(of: 2) ? Color("main200") : Color("sub200")
    }

    private var backgroundColor: Color {
        colorIndex.isMultiple(of: 2) ? Color("main105") : Color("sub100")
    }

    /// (화면 너비 - 좌우 패딩 32 - 책 간격 합 48) / 최대 7권
    private var spineWidth: CGFloat {
        (UIScreen.main.bounds.width - 32 - 48) / 7
    }

    private var spineHeight: CGFloat {
        max(titleNaturalSize.width + 32, 96)
    }

    var body: some View {
        ZStack(alignment: .top) {
            ZStack {
                Text(title)
                    .pretendardText(size: 15, weight: .medium)
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .fixedSize()
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(key: BookshelfSpineTextSizeKey.self, value: geo.size)
                        }
                    )
                    .rotationEffect(.degrees(90))
            }
            .frame(width: spineWidth, height: spineHeight)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            BookshelfSpineTopCap(color: backgroundColor, width: spineWidth)
                .offset(y: -BookshelfSpineTopCap.capHeight / 2 + 5)
        }
        .padding(.top, BookshelfSpineTopCap.capHeight / 2)
        .onPreferenceChange(BookshelfSpineTextSizeKey.self) { titleNaturalSize = $0 }
    }
}

private struct BookshelfSpineTopCap: View {
    static let capHeight: CGFloat = 13

    let color: Color
    let width: CGFloat

    var body: some View {
        Ellipse()
            .fill(color)
            .frame(width: width, height: Self.capHeight)
    }
}

private struct BookshelfSpineTextSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - Star Rating

private struct BookshelfStarRating: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { index in
                starImage(for: index)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(starColor(for: index))
            }
        }
    }

    private func starImage(for index: Int) -> Image {
        let threshold = Double(index)
        if rating >= threshold + 1 {
            return Image("ic_star_fill")
        } else if rating >= threshold + 0.5 {
            return Image("ic_star_fill")
        } else {
            return Image("ic_star")
        }
    }

    private func starColor(for index: Int) -> Color {
        let threshold = Double(index)
        if rating >= threshold + 1 {
            return Color("sub200")
        } else if rating >= threshold + 0.5 {
            return Color("sub200").opacity(0.5)
        } else {
            return Color("sub100")
        }
    }
}

#Preview {
    MyBookShelfView(
        userService: UserService(
            interceptor: AuthInterceptor(authService: AuthService())
        ),
        groupService: GroupService(
            interceptor: AuthInterceptor(authService: AuthService())
        )
    )
    .environmentObject(DIContainer())
}
