import Foundation

@MainActor
final class LibraryCardDetailViewModel: ObservableObject {
    @Published private(set) var detail: LibraryCardDetail?
    @Published private(set) var comments: [LibraryCardComment] = []
    @Published private(set) var commentCount: Int = 0
    @Published private(set) var isLoading = false
    @Published private(set) var isSubmittingComment = false
    @Published var isCommentSheetPresented = false
    @Published var commentInput = ""

    private let cardId: Int
    private let libraryService: LibraryService

    init(cardId: Int, libraryService: LibraryService) {
        self.cardId = cardId
        self.libraryService = libraryService
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        async let detailOptional = try? await libraryService.fetchLibraryCardDetail(cardId: cardId)
        async let commentsOptional = try? await libraryService.fetchLibraryCardComments(cardId: cardId)

        detail = await detailOptional

        if let commentList = await commentsOptional {
            comments = commentList.comments
            commentCount = commentList.totalCount
        } else {
            comments = []
            commentCount = 0
        }
    }

    func reloadComments() async {
        do {
            let commentList = try await libraryService.fetchLibraryCardComments(cardId: cardId)
            comments = commentList.comments
            commentCount = commentList.totalCount
        } catch {
            comments = []
            commentCount = 0
        }
    }

    func submitComment() async {
        let trimmed = commentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSubmittingComment else { return }

        isSubmittingComment = true
        defer { isSubmittingComment = false }

        do {
            try await libraryService.createLibraryCardComment(cardId: cardId, content: trimmed)
            commentInput = ""
            await reloadComments()
        } catch {
            return
        }
    }

    func openComments() {
        isCommentSheetPresented = true
    }
}
