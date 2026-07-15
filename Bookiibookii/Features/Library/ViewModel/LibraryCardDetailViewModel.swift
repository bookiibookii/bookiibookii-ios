import Foundation
import Combine

@MainActor
final class LibraryCardDetailViewModel: ObservableObject {
    @Published private(set) var detail: LibraryCardDetail?
    @Published private(set) var comments: [LibraryCardComment] = []
    @Published private(set) var commentCount: Int = 0
    @Published private(set) var isLoading = false
    @Published private(set) var isSubmittingComment = false
    @Published var isCommentSheetPresented = false
    @Published var commentInput = ""
    @Published var toastMessage: String?
    @Published private(set) var isDeleting = false

    private let cardId: Int
    private let libraryService: LibraryService

    init(cardId: Int, libraryService: LibraryService) {
        self.cardId = cardId
        self.libraryService = libraryService
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        detail = try? await libraryService.fetchLibraryCardDetail(cardId: cardId)
    }

    func toggleBookmark() async {
        guard let current = detail else { return }
        let optimistic = !current.isBookmarked
        detail = current.updatingBookmark(optimistic)

        do {
            let serverValue = try await libraryService.toggleLibraryCardBookmark(cardId: cardId)
            detail = detail?.updatingBookmark(serverValue)
            NotificationCenter.default.post(name: .libraryCardEngagementChanged, object: nil)
        } catch {
            detail = detail?.updatingBookmark(current.isBookmarked)
        }
    }

    @discardableResult
    func toggleReaction(_ reaction: LibraryCardReaction) async -> Bool? {
        guard let current = detail else { return nil }
        let optimistic = !current.activeReactions.contains(reaction)
        detail = current.updatingReaction(reaction, active: optimistic)

        do {
            let active = try await libraryService.toggleLibraryCardReaction(
                cardId: cardId,
                reaction: reaction
            )
            detail = detail?.updatingReaction(reaction, active: active)
            NotificationCenter.default.post(name: .libraryCardEngagementChanged, object: nil)
            return active
        } catch {
            detail = detail?.updatingReaction(
                reaction,
                active: current.activeReactions.contains(reaction)
            )
            return nil
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

    func deleteCard() async -> Bool {
        guard !isDeleting else { return false }

        if detail?.isBookmarked == true {
            toastMessage = "북마크된 독서카드는 삭제할 수 없어요."
            return false
        }

        isDeleting = true
        defer { isDeleting = false }

        do {
            try await libraryService.deleteLibraryCard(cardId: cardId)
            NotificationCenter.default.post(name: .libraryCardMutationFinished, object: nil)
            NotificationCenter.default.post(name: .libraryCardEngagementChanged, object: nil)
            return true
        } catch {
            toastMessage = (error as? LibraryServiceError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }
}
