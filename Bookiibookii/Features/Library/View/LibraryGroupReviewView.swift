import SwiftUI
import Combine

struct LibraryGroupReviewView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: LibraryGroupReviewViewModel

    init(book: LibraryBook, libraryService: LibraryService) {
        _viewModel = StateObject(
            wrappedValue: LibraryGroupReviewViewModel(
                book: book,
                libraryService: libraryService
            )
        )
    }

    var body: some View {
        ZStack {
            Color("uiBg").ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Text(errorMessage)
                            .pretendardText(size: 16)
                            .foregroundColor(Color("grey700"))
                            .multilineTextAlignment(.center)

                        Button("다시 시도") {
                            Task { await viewModel.load() }
                        }
                        .pretendardText(size: 16, weight: .medium)
                        .foregroundColor(Color("main200"))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(24)
                } else {
                    reviews
                }
            }
        }
        .task { await viewModel.load() }
        .onReceive(NotificationCenter.default.publisher(for: .libraryGroupReviewUpdated)) { _ in
            Task { await viewModel.load() }
        }
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
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("후기")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))

            Spacer()

            Button {
                container.navigationRouter.push(to: .libraryGroupReviewEdit(book: viewModel.book))
            } label: {
                Image("ic_pencil")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
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

    private var reviews: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 23) {
                if !viewModel.memberReviews.isEmpty {
                    memberReviewCard
                }

                ForEach(viewModel.bookReviewSections) { section in
                    LibraryBookReviewCard(section: section)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }

    private var memberReviewCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.book.groupName)
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey900"))

                HStack(spacing: 4) {
                    Text(viewModel.formattedDate(viewModel.book.startDate))
                    Text("~")
                    Text(viewModel.formattedDate(viewModel.book.endDate))
                }
                .pretendardText(size: 14)
                .foregroundColor(Color("grey500"))
            }
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color("grey100"))
                    .frame(height: 1)
            }

            VStack(spacing: 16) {
                ForEach(viewModel.memberReviews) { review in
                    LibraryMemberReviewRow(
                        review: review,
                        isMine: viewModel.isMine(writerId: review.writerId)
                    )
                }
            }
        }
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct LibraryMemberReviewRow: View {
    let review: LibraryGroupMemberReviewDTO
    let isMine: Bool

    var body: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: 8) {
            LibraryReviewProfile(
                nickname: review.writerNickname,
                imageURL: review.writerProfileImageUrl
            )

            HStack(alignment: .bottom, spacing: 8) {
                if isMine {
                    reactionIcon
                    contentBubble
                } else {
                    contentBubble
                    reactionIcon
                }
            }
            .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
        }
    }

    private var contentBubble: some View {
        Text(review.content ?? "-")
            .pretendardText(size: 14)
            .foregroundColor(Color("grey900"))
            .multilineTextAlignment(isMine ? .trailing : .leading)
            .frame(maxWidth: 276, alignment: isMine ? .trailing : .leading)
            .padding(16)
            .background(isMine ? Color("grey100") : Color("sub100"))
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var reactionIcon: some View {
        let isPositive = review.reaction?.uppercased() == "BOOM_UP"
        return Image(isPositive ? "ic_hand_thumbs_up" : "ic_hand_thumbs_down")
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .padding(3.5)
            .background(isPositive ? Color("main100") : Color("uiBg"))
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(
                        isPositive ? Color("main200") : Color("grey500"),
                        lineWidth: 0.5
                    )
            }
    }
}

private struct LibraryBookReviewCard: View {
    let section: LibraryBookReviewSection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                AsyncImage(url: URL(string: section.imageURL ?? "")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color("grey200")
                    }
                }
                .frame(width: 70, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(section.title)
                        .pretendardText(size: 16, weight: .semibold)
                        .foregroundColor(Color("grey900"))
                        .lineLimit(2)

                    Text(section.author ?? "-")
                        .pretendardText(size: 16, weight: .medium)
                        .foregroundColor(Color("grey700"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.bottom, 8)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color("grey100"))
                    .frame(height: 1)
            }

            VStack(spacing: 16) {
                ForEach(section.reviews) { review in
                    LibraryBookReviewRow(review: review, isMine: review.isMine)
                }
            }
        }
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct LibraryBookReviewRow: View {
    let review: LibraryBookReviewDisplay
    let isMine: Bool

    var body: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: 8) {
            LibraryReviewProfile(
                nickname: review.nickname,
                imageURL: review.profileImageURL
            )

            VStack(alignment: isMine ? .trailing : .leading, spacing: 10) {
                HStack {
                    if isMine {
                        Text(review.createdAt ?? "-")
                        Spacer()
                        LibraryReviewStars(rating: review.rating)
                    } else {
                        LibraryReviewStars(rating: review.rating)
                        Spacer()
                        Text(review.createdAt ?? "-")
                    }
                }
                .pretendardText(size: 12)
                .foregroundColor(Color("grey500"))

                Text(review.content ?? "-")
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey900"))
                    .multilineTextAlignment(isMine ? .trailing : .leading)
                    .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
            }
            .padding(16)
            .frame(maxWidth: 308)
            .background(Color("grey100"))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
    }
}

private struct LibraryReviewProfile: View {
    let nickname: String?
    let imageURL: String?

    var body: some View {
        HStack(spacing: 8) {
            AsyncImage(url: URL(string: imageURL ?? "")) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Color("grey200")
                }
            }
            .frame(width: 20, height: 20)
            .clipShape(Circle())

            Text(nickname ?? "-")
                .pretendardText(size: 12, weight: .medium)
                .foregroundColor(Color("grey800"))
        }
    }
}

private struct LibraryReviewStars: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { index in
                Image(starName(at: index))
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(Color("sub200"))
            }
        }
    }

    private func starName(at index: Int) -> String {
        let threshold = Double(index)
        if rating >= threshold + 1 { return "ic_star_fill" }
        if rating >= threshold + 0.5 { return "ic_star_half" }
        return "ic_star"
    }
}

struct LibraryBookReviewSection: Identifiable {
    let bookId: Int
    let title: String
    let author: String?
    let imageURL: String?
    let reviews: [LibraryBookReviewDisplay]

    var id: Int { bookId }
}

struct LibraryBookReviewDisplay: Identifiable {
    let id: Int
    let nickname: String?
    let profileImageURL: String?
    let rating: Double
    let content: String?
    let createdAt: String?
    let isMine: Bool
}

@MainActor
final class LibraryGroupReviewViewModel: ObservableObject {
    @Published private(set) var memberReviews: [LibraryGroupMemberReviewDTO] = []
    @Published private(set) var bookReviewSections: [LibraryBookReviewSection] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    let book: LibraryBook
    private let libraryService: LibraryService

    init(book: LibraryBook, libraryService: LibraryService) {
        self.book = book
        self.libraryService = libraryService
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let reviewsRequest = libraryService.fetchGroupReviews(groupId: book.groupId)
            async let booksRequest = libraryService.fetchLibraryBooks()
            let (response, libraryBooks) = try await (reviewsRequest, booksRequest)

            memberReviews = sortByWriterRole(
                response.memberReviews ?? [],
                hostFirst: true,
                nickname: \.writerNickname
            )
            bookReviewSections = makeBookSections(
                reviews: response.bookReviews ?? [],
                libraryBooks: libraryBooks.filter { $0.groupId == book.groupId }
            )
        } catch {
            errorMessage = "후기를 불러오지 못했어요.\n잠시 후 다시 시도해 주세요."
        }
    }

    func isMine(writerId: Int?) -> Bool {
        writerId != nil && writerId == TokenManager.shared.userId
    }

    func formattedDate(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "-" }
        if value.contains(". ") {
            return value
        }
        let input = DateFormatter()
        input.locale = Locale(identifier: "en_US_POSIX")
        input.dateFormat = "yyyy-MM-dd"
        let source = String(value.prefix(10))
        guard let date = input.date(from: source) else { return source }

        let output = DateFormatter()
        output.locale = Locale(identifier: "ko_KR")
        output.dateFormat = "yyyy. MM. dd."
        return output.string(from: date)
    }

    private func makeBookSections(
        reviews: [LibraryGroupBookReviewDTO],
        libraryBooks: [LibraryBook]
    ) -> [LibraryBookReviewSection] {
        let grouped = Dictionary(grouping: reviews) { $0.bookId ?? -1 }
        let currentUserIsHost = book.isCreatedByMe

        let knownBookIds = libraryBooks.compactMap(\.bookId)
        let hostBookId = libraryBooks.first {
            currentUserIsHost ? $0.isMyOriginalBook : !$0.isMyOriginalBook
        }?.bookId
        let guestBookId = libraryBooks.first {
            currentUserIsHost ? !$0.isMyOriginalBook : $0.isMyOriginalBook
        }?.bookId

        var orderedIds = [hostBookId, guestBookId].compactMap { $0 }
        orderedIds.append(
            contentsOf: grouped.keys
                .filter { !orderedIds.contains($0) }
                .sorted()
        )

        if orderedIds.isEmpty {
            orderedIds = Array(Set(knownBookIds)).sorted()
        }

        return orderedIds.compactMap { bookId in
            guard let sectionReviews = grouped[bookId], let first = sectionReviews.first else {
                return nil
            }
            let isHostBook = bookId == hostBookId
            let sorted = sortByWriterRole(
                sectionReviews,
                hostFirst: isHostBook,
                nickname: \.writerNickname
            )

            return LibraryBookReviewSection(
                bookId: bookId,
                title: first.bookTitle ?? "-",
                author: first.bookAuthor,
                imageURL: first.bookImageUrl,
                reviews: sorted.map {
                    LibraryBookReviewDisplay(
                        id: $0.id,
                        nickname: $0.writerNickname,
                        profileImageURL: $0.writerProfileImageUrl,
                        rating: $0.rating ?? 0,
                        content: $0.content,
                        createdAt: formattedDate($0.createdAt),
                        isMine: isMine(writerId: $0.writerId)
                    )
                }
            )
        }
    }

    private func sortByWriterRole<T>(
        _ items: [T],
        hostFirst: Bool,
        nickname: KeyPath<T, String?>
    ) -> [T] {
        items.sorted { lhs, rhs in
            let lhsIsHost = lhs[keyPath: nickname] == book.hostNickname
            let rhsIsHost = rhs[keyPath: nickname] == book.hostNickname
            guard lhsIsHost != rhsIsHost else { return false }
            return hostFirst ? lhsIsHost : !lhsIsHost
        }
    }
}
