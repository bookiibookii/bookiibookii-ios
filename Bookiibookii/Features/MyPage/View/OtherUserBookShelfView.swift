import SwiftUI
import Kingfisher

struct OtherUserBookShelfView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: OtherUserBookShelfViewModel
    var onClose: (() -> Void)?

    init(nickname: String, userService: UserService, onClose: (() -> Void)? = nil) {
        _viewModel = StateObject(
            wrappedValue: OtherUserBookShelfViewModel(nickname: nickname, userService: userService)
        )
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if viewModel.isLoading && viewModel.representativeBooks.isEmpty && viewModel.favoriteBooks.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            representativeSection
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
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            container.navigationRouter.pop()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: close) {
                Image("ic_back")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("\(viewModel.nickname) 님의 책장")
                .pretendardText(size: 20, weight: .medium)
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

    // MARK: - Representative

    private var representativeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text("\(viewModel.nickname)님을 대표하는 책")
                    .pretendardText(size: 16, weight: .semibold)
                    .foregroundColor(Color("grey900"))

                countBadge(viewModel.representativeCountText)
            }

            if viewModel.representativeBooks.isEmpty {
                Text("등록된 대표 책이 없어요.")
                    .pretendardText(size: 14, weight: .regular)
                    .foregroundColor(Color("grey500"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(viewModel.representativeBooks) { book in
                            OtherUserBookshelfSpine(
                                title: book.title,
                                isFavorite: book.isFavorite
                            )
                        }
                    }
                    .padding(.top, 16)
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
            HStack(spacing: 8) {
                Text("인생 책")
                    .pretendardText(size: 16, weight: .semibold)
                    .foregroundColor(Color("grey900"))

                countBadge(viewModel.favoriteCountText)
            }

            HStack(alignment: .top, spacing: 12) {
                ForEach(0..<OtherUserBookShelfViewModel.maxFavoriteCount, id: \.self) { index in
                    if index < viewModel.favoriteBooks.count {
                        favoriteBookCard(viewModel.favoriteBooks[index])
                    } else {
                        favoriteEmptySlot
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
    }

    private func favoriteBookCard(_ book: BookshelfFavoriteBook) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            bookCover(imageURL: book.image, height: 170)

            Text(book.title)
                .pretendardText(size: 14, weight: .semibold)
                .foregroundColor(Color("grey900"))
                .lineLimit(1)

            Text(book.authorWithCategory)
                .pretendardText(size: 14, weight: .regular)
                .foregroundColor(Color("grey700"))
                .lineLimit(1)
        }
        .frame(width: 119, alignment: .leading)
    }

    private var favoriteEmptySlot: some View {
        Color("grey200")
            .frame(width: 119, height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Completed Empty

    private var completedEmptySection: some View {
        VStack(spacing: 8) {
            completedFilterSection

            Text("책장이 비어 있어요.")
                .pretendardText(size: 16, weight: .regular)
                .foregroundColor(Color("grey600"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, 24)
                .background(Color("white"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)
        }
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
        .padding(.top, 24)
        .padding(.bottom, 8)
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

        return LazyVGrid(columns: columns, spacing: 12) {
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

            if let date = book.formattedCompletedDate {
                Text(date)
                    .pretendardText(size: 12, weight: .regular)
                    .foregroundColor(Color("grey700"))
                    .lineLimit(1)
            }

            Text(book.title)
                .pretendardText(size: 14, weight: .semibold)
                .foregroundColor(Color("grey900"))
                .lineLimit(1)

            Text(book.authorWithCategory)
                .pretendardText(size: 14, weight: .regular)
                .foregroundColor(Color("grey700"))
                .lineLimit(1)

            if let rating = book.rating {
                OtherUserBookshelfStarRating(rating: rating)
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

                    Text(book.title)
                        .pretendardText(size: 14, weight: .semibold)
                        .foregroundColor(Color("grey900"))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                if let rating = book.rating {
                    OtherUserBookshelfStarRating(rating: rating)
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
            .placeholder { Color("grey200") }
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Representative Spine

private struct OtherUserBookshelfSpine: View {
    let title: String
    let isFavorite: Bool

    @State private var titleNaturalSize: CGSize = .zero

    private var textColor: Color {
        isFavorite ? Color("sub200") : Color("main200")
    }

    private var backgroundColor: Color {
        isFavorite ? Color("sub100") : Color("main105")
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
                            Color.clear.preference(key: OtherUserBookshelfSpineTextSizeKey.self, value: geo.size)
                        }
                    )
                    .rotationEffect(.degrees(90))
            }
            .frame(width: spineWidth, height: spineHeight)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            OtherUserBookshelfSpineTopCap(color: backgroundColor, width: spineWidth)
                .offset(y: -OtherUserBookshelfSpineTopCap.capHeight / 2)
        }
        .padding(.top, OtherUserBookshelfSpineTopCap.capHeight / 2)
        .onPreferenceChange(OtherUserBookshelfSpineTextSizeKey.self) { titleNaturalSize = $0 }
    }
}

private struct OtherUserBookshelfSpineTopCap: View {
    static let capHeight: CGFloat = 13

    let color: Color
    let width: CGFloat

    var body: some View {
        Ellipse()
            .fill(color)
            .frame(width: width, height: Self.capHeight)
    }
}

private struct OtherUserBookshelfSpineTextSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - Star Rating

private struct OtherUserBookshelfStarRating: View {
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
