import Foundation
import Combine

@MainActor
final class LibraryCardDetailViewModel: ObservableObject {
    @Published private(set) var cards: [LibraryCard]
    @Published var currentIndex: Int
    @Published private(set) var isLoading = false
    @Published private(set) var isSubmittingComment = false
    @Published var isCommentSheetPresented = false
    @Published var commentInput = ""
    @Published var toastMessage: String?
    @Published private(set) var isDeleting = false
    @Published private(set) var comments: [LibraryCardComment] = []
    @Published private(set) var commentCount: Int = 0

    /// 상단 진행바 옆 정렬 라벨 (예: 페이지순 / 최신순 / 과거순)
    let sortLabel: String

    private let bootstrapCardId: Int?
    private let libraryService: LibraryService

    var currentCard: LibraryCard? {
        guard cards.indices.contains(currentIndex) else { return nil }
        return cards[currentIndex]
    }

    var detail: LibraryCardDetail? {
        currentCard?.asDetail
    }

    /// 안드로이드와 동일: (현재 인덱스 + 1) / 전체 개수
    var progress: CGFloat {
        guard !cards.isEmpty else { return 0 }
        return CGFloat(currentIndex + 1) / CGFloat(cards.count)
    }

    init(
        cards: [LibraryCard],
        initialIndex: Int,
        sortLabel: String,
        libraryService: LibraryService
    ) {
        self.cards = cards
        self.currentIndex = cards.isEmpty
            ? 0
            : min(max(0, initialIndex), cards.count - 1)
        self.sortLabel = sortLabel
        self.bootstrapCardId = nil
        self.libraryService = libraryService
    }

    /// 푸시/딥링크처럼 목록 없이 cardId만 있을 때
    init(cardId: Int, libraryService: LibraryService) {
        self.cards = []
        self.currentIndex = 0
        self.sortLabel = "페이지순"
        self.bootstrapCardId = cardId
        self.libraryService = libraryService
    }

    func load() async {
        guard let bootstrapCardId, cards.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        if let detail = try? await libraryService.fetchLibraryCardDetail(cardId: bootstrapCardId) {
            cards = [detail.asListCard]
            currentIndex = 0
        }
    }

    func selectIndex(_ index: Int) {
        guard cards.indices.contains(index), currentIndex != index else { return }
        currentIndex = index
    }

    func toggleBookmark() async {
        guard let current = currentCard, current.isBookmarkable else { return }
        let index = currentIndex
        let previous = current.isBookmarked
        let optimistic = !previous
        cards[index] = current.updatingBookmark(optimistic)

        do {
            let serverValue = try await libraryService.toggleLibraryCardBookmark(cardId: current.id)
            guard cards.indices.contains(index), cards[index].id == current.id else { return }
            cards[index] = cards[index].updatingBookmark(serverValue)
            NotificationCenter.default.post(name: .libraryCardEngagementChanged, object: nil)
        } catch {
            guard cards.indices.contains(index), cards[index].id == current.id else { return }
            cards[index] = cards[index].updatingBookmark(previous)
        }
    }

    @discardableResult
    func toggleReaction(_ reaction: LibraryCardReaction) async -> Bool? {
        guard let current = currentCard else { return nil }
        let index = currentIndex
        let previous = current.activeReactions
        let optimistic = !previous.contains(reaction)
        cards[index] = current.updatingReaction(reaction, active: optimistic)

        do {
            let active = try await libraryService.toggleLibraryCardReaction(
                cardId: current.id,
                reaction: reaction
            )
            guard cards.indices.contains(index), cards[index].id == current.id else { return active }
            cards[index] = cards[index].updatingReaction(reaction, active: active)
            NotificationCenter.default.post(name: .libraryCardEngagementChanged, object: nil)
            return active
        } catch {
            guard cards.indices.contains(index), cards[index].id == current.id else { return nil }
            cards[index] = cards[index].updatingReaction(
                reaction,
                active: previous.contains(reaction)
            )
            return nil
        }
    }

    func reloadComments() async {
        guard let cardId = currentCard?.id else {
            comments = []
            commentCount = 0
            return
        }
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
        guard let cardId = currentCard?.id else { return }
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
        guard let current = currentCard else { return false }

        if current.isBookmarked {
            toastMessage = "북마크된 독서카드는 삭제할 수 없어요."
            return false
        }

        isDeleting = true
        defer { isDeleting = false }

        do {
            try await libraryService.deleteLibraryCard(cardId: current.id)
            NotificationCenter.default.post(name: .libraryCardMutationFinished, object: nil)
            NotificationCenter.default.post(name: .libraryCardEngagementChanged, object: nil)
            return true
        } catch {
            toastMessage = (error as? LibraryServiceError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }
}

private extension LibraryCardDetail {
    var asListCard: LibraryCard {
        LibraryCard(
            id: cardId,
            isBookmarkable: true,
            memberBookId: memberBookId,
            cardType: cardType,
            bookTitle: bookTitle,
            page: page,
            memo: memo,
            quotation: quotation,
            imageURL: imageURL,
            creatorName: creatorName,
            creatorProfileImageURL: creatorProfileImageURL,
            isMine: isMine,
            isBookmarked: isBookmarked,
            activeReactions: activeReactions,
            reactionCounts: [:],
            createdAt: createdAt,
            messageCount: 0
        )
    }
}
