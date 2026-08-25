import SwiftUI
import Combine

private enum ReviewEditStarState { case empty, subPale, sub }

enum ReviewEditPartnerRating: Equatable {
    case none, good, bad

    var reaction: String? {
        switch self {
        case .good: return "BOOM_UP"
        case .bad: return "BOOM_DOWN"
        case .none: return nil
        }
    }

    init(reaction: String?) {
        switch reaction?.uppercased() {
        case "BOOM_UP": self = .good
        case "BOOM_DOWN": self = .bad
        default: self = .none
        }
    }
}

private func reviewEditStarState(score: Int, index: Int) -> ReviewEditStarState {
    let halfPos = (index + 1) * 2 - 1
    let fullPos = (index + 1) * 2
    if fullPos <= score { return .sub }
    if halfPos == score { return .subPale }
    return .empty
}

private func reviewEditNextScore(score: Int, index: Int) -> Int {
    let halfPos = (index + 1) * 2 - 1
    let fullPos = (index + 1) * 2
    if score < halfPos { return halfPos }
    if score == halfPos { return fullPos }
    return halfPos
}

struct LibraryGroupReviewEditView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: LibraryGroupReviewEditViewModel

    init(
        book: LibraryBook,
        libraryService: LibraryService,
        trackerService: TrackerService
    ) {
        _viewModel = StateObject(
            wrappedValue: LibraryGroupReviewEditViewModel(
                book: book,
                libraryService: libraryService,
                trackerService: trackerService
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            CustomNavigationBar(title: "후기 수정", onBack: { container.navigationRouter.pop() })

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
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        groupInfoCard

                        ForEach($viewModel.bookReviews) { $review in
                            bookReviewCard(review: $review)
                        }

                        partnerReviewCard
                    }
                    .padding(16)
                    .padding(.bottom, 16)
                }
                .scrollDismissesKeyboard(.interactively)
            }

            FooterButton(
                text: "수정",
                enabled: viewModel.canSubmit,
                isLoading: viewModel.isSubmitting,
                action: {
                    Task {
                        let success = await viewModel.submit()
                        if success {
                            NotificationCenter.default.post(name: .libraryGroupReviewUpdated, object: nil)
                            container.navigationRouter.pop()
                        }
                    }
                }
            )
            .padding(16)
        }
        .background(Color("uiBg"))
        .navigationBarBackButtonHidden(true)
        .task { await viewModel.load() }
        .alert("안내", isPresented: Binding(
            get: { viewModel.toastMessage != nil },
            set: { if !$0 { viewModel.toastMessage = nil } }
        )) {
            Button("확인", role: .cancel) { viewModel.toastMessage = nil }
        } message: {
            Text(viewModel.toastMessage ?? "")
        }
    }

    private var groupInfoCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.book.groupName)
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey800"))

            HStack(spacing: 4) {
                Text(viewModel.formattedDate(viewModel.book.startDate))
                Text("~")
                Text(viewModel.formattedDate(viewModel.book.endDate))
            }
            .pretendardText(size: 14)
            .foregroundColor(Color("grey500"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func bookReviewCard(review: Binding<EditableGroupBookReview>) -> some View {
        VStack(spacing: 16) {
            BookCover(imageUrl: review.wrappedValue.imageURL)
                .frame(width: 122, height: 180)

            (
                Text(review.wrappedValue.title).foregroundColor(Color("main200"))
                + Text("에 대한 평가를 남겨주세요!").foregroundColor(Color("grey900"))
            )
            .pretendardText(size: 16, weight: .medium)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)

            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { index in
                    ReviewEditStarItem(
                        state: reviewEditStarState(score: review.wrappedValue.ratingScore, index: index)
                    ) {
                        review.wrappedValue.ratingScore = reviewEditNextScore(
                            score: review.wrappedValue.ratingScore,
                            index: index
                        )
                    }
                }
            }
            .padding(.bottom, 8)

            reviewTextEditor(
                text: review.comment,
                placeholder: "감상평을 자유롭게 남겨주세요.",
                maxLength: 500
            )
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var partnerReviewCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 4) {
                ProfilePlaceholder(imageUrl: viewModel.partnerProfileImageURL, size: 20)
                (
                    Text(viewModel.partnerNickname).foregroundColor(Color("main200"))
                    + Text("님과의 교환독서는 어떠셨나요?").foregroundColor(Color("grey900"))
                )
                .pretendardText(size: 16, weight: .medium)
            }

            HStack(spacing: 12) {
                partnerRatingButton(
                    text: "좋았어요",
                    icon: "ic_hand_thumbs_up",
                    target: .good,
                    isPositive: true
                )
                partnerRatingButton(
                    text: "별로였어요",
                    icon: "ic_hand_thumbs_down",
                    target: .bad,
                    isPositive: false
                )
            }

            reviewTextEditor(
                text: $viewModel.partnerComment,
                placeholder: "부키메이트에 대한 솔직한 후기를 남겨주세요",
                maxLength: 20
            )
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func partnerRatingButton(
        text: String,
        icon: String,
        target: ReviewEditPartnerRating,
        isPositive: Bool
    ) -> some View {
        let isSelected = viewModel.partnerRating == target
        let background = isSelected ? Color("main100") : Color("white")
        let border = isSelected ? Color("main105") : Color("grey200")
        let content = isSelected ? Color("main200") : (isPositive ? Color("grey900") : Color("grey500"))

        return Button {
            viewModel.partnerRating = isSelected ? .none : target
        } label: {
            HStack(spacing: 8) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(content)
                Text(text)
                    .pretendardText(size: 16, weight: .regular)
                    .foregroundColor(content)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(background)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private func reviewTextEditor(
        text: Binding<String>,
        placeholder: String,
        maxLength: Int
    ) -> some View {
        ZStack(alignment: .topLeading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey500"))
                    .padding(.top, 8)
                    .padding(.leading, 4)
            }
            TextEditor(text: text)
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey900"))
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .tint(Color("main200"))
                .onChange(of: text.wrappedValue) { _, value in
                    if value.count > maxLength {
                        text.wrappedValue = String(value.prefix(maxLength))
                    }
                }
        }
        .frame(minHeight: 160)
        .padding(20)
        .background(Color("grey100"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct ReviewEditStarItem: View {
    let state: ReviewEditStarState
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                switch state {
                case .empty:
                    star("ic_star", Color("grey300"))
                case .subPale:
                    star("ic_star_fill", Color("sub100"))
                    star("ic_star", Color("sub200"))
                case .sub:
                    star("ic_star_fill", Color("sub200"))
                }
            }
            .frame(width: 40, height: 40)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func star(_ name: String, _ color: Color) -> some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40)
            .foregroundColor(color)
    }
}

struct EditableGroupBookReview: Identifiable, Equatable {
    let id: Int
    let memberBookId: Int
    let title: String
    let imageURL: String?
    var ratingScore: Int
    var comment: String
}

@MainActor
final class LibraryGroupReviewEditViewModel: ObservableObject {
    @Published var bookReviews: [EditableGroupBookReview] = []
    @Published var partnerRating: ReviewEditPartnerRating = .none
    @Published var partnerComment = ""
    @Published private(set) var partnerNickname = "-"
    @Published private(set) var partnerProfileImageURL: String?
    @Published private(set) var isLoading = false
    @Published private(set) var isSubmitting = false
    @Published private(set) var errorMessage: String?
    @Published var toastMessage: String?

    let book: LibraryBook
    private let libraryService: LibraryService
    private let trackerService: TrackerService
    private var baselineBookReviews: [EditableGroupBookReview] = []
    private var baselinePartnerRating: ReviewEditPartnerRating = .none
    private var baselinePartnerComment = ""
    private var hasLoadedBaseline = false

    init(
        book: LibraryBook,
        libraryService: LibraryService,
        trackerService: TrackerService
    ) {
        self.book = book
        self.libraryService = libraryService
        self.trackerService = trackerService
    }

    var canSubmit: Bool {
        guard hasLoadedBaseline, !bookReviews.isEmpty, !isSubmitting else { return false }
        let hasBookRatings = bookReviews.allSatisfy { $0.ratingScore > 0 }
        guard hasBookRatings else { return false }
        return hasChangesFromBaseline
    }

    private var hasChangesFromBaseline: Bool {
        if partnerRating != baselinePartnerRating { return true }

        let partnerNow = partnerComment.trimmingCharacters(in: .whitespacesAndNewlines)
        let partnerBaseline = baselinePartnerComment.trimmingCharacters(in: .whitespacesAndNewlines)
        if partnerNow != partnerBaseline { return true }

        guard bookReviews.count == baselineBookReviews.count else { return true }

        for (current, baseline) in zip(bookReviews, baselineBookReviews) {
            if current.memberBookId != baseline.memberBookId { return true }
            if current.ratingScore != baseline.ratingScore { return true }

            let commentNow = current.comment.trimmingCharacters(in: .whitespacesAndNewlines)
            let commentBaseline = baseline.comment.trimmingCharacters(in: .whitespacesAndNewlines)
            if commentNow != commentBaseline { return true }
        }

        return false
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let myReviewsRequest = trackerService.fetchMyBookReviews(groupId: book.groupId)
            async let groupReviewsRequest = libraryService.fetchGroupReviews(groupId: book.groupId)
            async let libraryBooksRequest = libraryService.fetchLibraryBooks()

            let (myReviewsResponse, groupReviewsResponse, libraryBooks) = try await (
                myReviewsRequest,
                groupReviewsRequest,
                libraryBooksRequest
            )

            let groupBooks = libraryBooks.filter { $0.groupId == book.groupId }
            let myReviews = myReviewsResponse.reviews ?? []
            let orderedReviews = orderedBookReviews(myReviews, libraryBooks: groupBooks)

            bookReviews = orderedReviews.compactMap { review in
                guard let memberBookId = memberBookId(for: review, libraryBooks: groupBooks) else {
                    return nil
                }
                return EditableGroupBookReview(
                    id: memberBookId,
                    memberBookId: memberBookId,
                    title: review.bookTitle ?? "-",
                    imageURL: review.bookImageUrl,
                    ratingScore: Int(((review.rating ?? 0) * 2).rounded()),
                    comment: review.content ?? ""
                )
            }

            if let myMemberReview = (groupReviewsResponse.memberReviews ?? []).first(where: {
                isMine(writerId: $0.writerId)
            }) {
                partnerRating = ReviewEditPartnerRating(reaction: myMemberReview.reaction)
                partnerComment = myMemberReview.content ?? ""
            }

            if let partnerReview = (groupReviewsResponse.memberReviews ?? []).first(where: {
                !isMine(writerId: $0.writerId)
            }) {
                partnerNickname = partnerReview.writerNickname ?? "-"
                partnerProfileImageURL = partnerReview.writerProfileImageUrl
            } else if book.isCreatedByMe {
                partnerNickname = "-"
            } else {
                partnerNickname = book.hostNickname
            }

            if bookReviews.isEmpty {
                errorMessage = "수정할 후기를 불러오지 못했어요."
            } else {
                baselineBookReviews = bookReviews
                baselinePartnerRating = partnerRating
                baselinePartnerComment = partnerComment
                hasLoadedBaseline = true
            }
        } catch {
            errorMessage = "후기를 불러오지 못했어요.\n잠시 후 다시 시도해 주세요."
        }
    }

    func submit() async -> Bool {
        guard canSubmit else { return false }
        isSubmitting = true
        defer { isSubmitting = false }

        let trimmedPartnerComment = partnerComment.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = MyGroupReviewsUpdateRequestBody(
            bookReviews: bookReviews.map {
                MyGroupBookReviewUpdateItem(
                    memberBookId: $0.memberBookId,
                    star: Double($0.ratingScore) / 2.0,
                    comment: $0.comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? nil
                        : $0.comment
                )
            },
            memberReview: MyGroupMemberReviewUpdateItem(
                reaction: partnerRating.reaction,
                comment: trimmedPartnerComment.isEmpty ? nil : trimmedPartnerComment
            )
        )

        do {
            _ = try await trackerService.updateMyGroupReviews(groupId: book.groupId, body: body)
            return true
        } catch {
            toastMessage = (error as? TrackerServiceError)?.errorDescription ?? "후기 수정에 실패했어요."
            return false
        }
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

    private func isMine(writerId: Int?) -> Bool {
        writerId != nil && writerId == TokenManager.shared.userId
    }

    private func memberBookId(for review: BookReviewItem, libraryBooks: [LibraryBook]) -> Int? {
        if let bookId = review.bookId,
           let matched = libraryBooks.first(where: { $0.bookId == bookId }) {
            return matched.id
        }

        let isMyBook = review.reviewType?.uppercased() == "MY_BOOK"
        return libraryBooks.first(where: { $0.isMyOriginalBook == isMyBook })?.id
    }

    private func orderedBookReviews(
        _ reviews: [BookReviewItem],
        libraryBooks: [LibraryBook]
    ) -> [BookReviewItem] {
        let hostBookId = libraryBooks.first {
            book.isCreatedByMe ? $0.isMyOriginalBook : !$0.isMyOriginalBook
        }?.bookId
        let guestBookId = libraryBooks.first {
            book.isCreatedByMe ? !$0.isMyOriginalBook : $0.isMyOriginalBook
        }?.bookId

        return reviews.sorted { lhs, rhs in
            let lhsIsHostBook = lhs.bookId == hostBookId
            let rhsIsHostBook = rhs.bookId == hostBookId
            if lhsIsHostBook != rhsIsHostBook {
                return lhsIsHostBook
            }
            return (lhs.bookId ?? 0) < (rhs.bookId ?? 0)
        }
    }
}
