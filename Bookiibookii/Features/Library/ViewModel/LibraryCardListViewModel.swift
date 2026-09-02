import Combine
import Foundation

@MainActor
final class LibraryCardListViewModel: ObservableObject {
    enum SortType {
        case latest
        case page
    }

    @Published private(set) var cards: [LibraryCard] = []
    @Published private(set) var isLoading = false
    @Published var sortType: SortType = .latest
    @Published var showOnlyMine = false
    @Published private(set) var isRepresentative: Bool?
    @Published private(set) var isRepresentativeMutating = false

    /// 후기 작성 후 라이브러리 응답에서 다시 받아온 책 별점(`rating`).
    /// `nil`이면 초기 `book.rating` 을 그대로 사용합니다.
    @Published private(set) var refreshedBookRating: Double?

    @Published var toastMessage: String?
    @Published private(set) var isDeletingLibrary = false

    private let groupId: Int
    private let memberBookId: Int?
    private let bookTitle: String
    private let libraryService: LibraryService
    private let userService: UserService
    private var representativeUserBookId: Int?
    /// `.task` / `.refreshable` / 알림이 동시에 `load()`를 호출할 때,
    /// 취소된 요청이 나중에 도착해도 성공 결과를 덮어쓰지 않도록 세대 번호를 둡니다.
    private var loadGeneration = 0

    init(
        book: LibraryBook,
        libraryService: LibraryService,
        userService: UserService
    ) {
        self.groupId = book.groupId
        self.memberBookId = book.userBookId
        self.bookTitle = book.title
        self.libraryService = libraryService
        self.userService = userService
    }

    var sortedCards: [LibraryCard] {
        let visibleCards = showOnlyMine ? cards.filter(\.isMine) : cards
        switch sortType {
        case .latest:
            return visibleCards.sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
        case .page:
            return visibleCards.sorted {
                $0.page == $1.page
                    ? ($0.createdAt ?? "") > ($1.createdAt ?? "")
                    : $0.page < $1.page
            }
        }
    }

    func load() async {
        loadGeneration += 1
        let generation = loadGeneration
        isLoading = true
        defer {
            if generation == loadGeneration {
                isLoading = false
            }
        }

        do {
            try await reloadCardsOnly(generation: generation)
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            // 새로고침 실패 시 기존 목록을 유지합니다. (취소/레이스로 빈 리스트가 보이던 문제 방지)
            guard generation == loadGeneration else { return }
            if cards.isEmpty {
                toastMessage = (error as? LocalizedError)?.errorDescription
                    ?? "독서카드를 불러오지 못했습니다."
            }
            return
        }

        guard generation == loadGeneration, !Task.isCancelled else { return }

        await refreshBookRatingFromLibrary()
        guard generation == loadGeneration, !Task.isCancelled else { return }
        await refreshRepresentativeStatus(showError: false)
    }

    func refreshRepresentativeStatus(showError: Bool = true) async {
        do {
            let bookshelf = try await userService.getBookshelf()
            let representative = bookshelf.representativeBooks.first { candidate in
                if let candidateMemberBookId = candidate.memberBookId,
                   let memberBookId {
                    return candidateMemberBookId == memberBookId
                }
                return candidate.title == bookTitle
            }
            representativeUserBookId = representative?.userBookId
            isRepresentative = representative != nil
        } catch {
            isRepresentative = nil
            if showError {
                toastMessage = error.localizedDescription
            }
        }
    }

    func deleteLibrary() async -> Bool {
        guard let memberBookId else {
            toastMessage = "삭제할 서재 정보를 찾지 못했습니다."
            return false
        }
        guard !isDeletingLibrary else { return false }

        isDeletingLibrary = true
        defer { isDeletingLibrary = false }

        do {
            try await libraryService.deleteLibraryMemberBook(memberBookId: memberBookId)
            NotificationCenter.default.post(name: .libraryCardMutationFinished, object: nil)
            return true
        } catch {
            toastMessage = (error as? LibraryServiceError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    func toggleRepresentative() async {
        guard let memberBookId else {
            toastMessage = "대표 도서로 등록할 책 정보를 찾지 못했습니다."
            return
        }

        isRepresentativeMutating = true
        defer { isRepresentativeMutating = false }

        do {
            if isRepresentative == true {
                guard let representativeUserBookId else {
                    await refreshRepresentativeStatus()
                    return
                }
                try await userService.deleteRepresentativeBook(userBookId: representativeUserBookId)
            } else {
                try await userService.addRepresentativeBook(memberBookId: memberBookId)
            }
            await refreshRepresentativeStatus()
        } catch {
            toastMessage = error.localizedDescription
        }
    }

    private func reloadCardsOnly(generation: Int) async throws {
        guard let memberBookId else {
            throw LibraryServiceError.server("서재 정보를 찾지 못했습니다.")
        }
        let result = try await libraryService.fetchLibraryCards(memberBookId: memberBookId)
        guard generation == loadGeneration, !Task.isCancelled else {
            throw CancellationError()
        }
        cards = result.cards
    }

    private func refreshBookRatingFromLibrary() async {
        do {
            let books = try await libraryService.fetchLibraryBooks()
            guard let match = books.first(where: { $0.groupId == groupId }) else { return }
            if let rating = match.rating {
                refreshedBookRating = rating
            }
        } catch {}
    }

    func toggleBookmark(cardId: Int) async {
        guard let index = cards.firstIndex(where: { $0.id == cardId }) else { return }
        guard cards[index].isBookmarkable else { return }
        let previous = cards[index].isBookmarked
        let optimistic = !previous

        func replacingCard(at i: Int, bookmarked: Bool) -> [LibraryCard] {
            cards.enumerated().map { idx, card in
                guard idx == i else { return card }
                return LibraryCard(
                    id: card.id,
                    isBookmarkable: card.isBookmarkable,
                    memberBookId: card.memberBookId,
                    cardType: card.cardType,
                    bookTitle: card.bookTitle,
                    page: card.page,
                    memo: card.memo,
                    quotation: card.quotation,
                    imageURL: card.imageURL,
                    creatorName: card.creatorName,
                    creatorProfileImageURL: card.creatorProfileImageURL,
                    isMine: card.isMine,
                    isBookmarked: bookmarked,
                    activeReactions: card.activeReactions,
                    reactionCounts: card.reactionCounts,
                    createdAt: card.createdAt,
                    messageCount: card.messageCount
                )
            }
        }

        cards = replacingCard(at: index, bookmarked: optimistic)

        do {
            let serverValue = try await libraryService.toggleLibraryCardBookmark(cardId: cardId)
            guard let idx = cards.firstIndex(where: { $0.id == cardId }) else { return }
            cards = replacingCard(at: idx, bookmarked: serverValue)
        } catch {
            guard let idx = cards.firstIndex(where: { $0.id == cardId }) else { return }
            cards = replacingCard(at: idx, bookmarked: previous)
        }
    }

    func toggleReaction(cardId: Int, reaction: LibraryCardReaction) async {
        guard let index = cards.firstIndex(where: { $0.id == cardId }) else { return }
        let previous = cards[index].activeReactions
        let optimistic = !previous.contains(reaction)

        func replacingCard(
            at targetIndex: Int,
            reactionActive: Bool
        ) -> [LibraryCard] {
            cards.enumerated().map { index, card in
                guard index == targetIndex else { return card }
                var reactions = card.activeReactions
                let wasActive = reactions.contains(reaction)
                if reactionActive {
                    reactions.insert(reaction)
                } else {
                    reactions.remove(reaction)
                }
                var reactionCounts = card.reactionCounts
                let currentCount = reactionCounts[reaction] ?? 0
                if wasActive != reactionActive {
                    reactionCounts[reaction] = reactionActive
                        ? currentCount + 1
                        : max(0, currentCount - 1)
                }
                return LibraryCard(
                    id: card.id,
                    isBookmarkable: card.isBookmarkable,
                    memberBookId: card.memberBookId,
                    cardType: card.cardType,
                    bookTitle: card.bookTitle,
                    page: card.page,
                    memo: card.memo,
                    quotation: card.quotation,
                    imageURL: card.imageURL,
                    creatorName: card.creatorName,
                    creatorProfileImageURL: card.creatorProfileImageURL,
                    isMine: card.isMine,
                    isBookmarked: card.isBookmarked,
                    activeReactions: reactions,
                    reactionCounts: reactionCounts,
                    createdAt: card.createdAt,
                    messageCount: card.messageCount
                )
            }
        }

        cards = replacingCard(at: index, reactionActive: optimistic)

        do {
            let active = try await libraryService.toggleLibraryCardReaction(
                cardId: cardId,
                reaction: reaction
            )
            guard let currentIndex = cards.firstIndex(where: { $0.id == cardId }) else { return }
            cards = replacingCard(at: currentIndex, reactionActive: active)
        } catch {
            guard let currentIndex = cards.firstIndex(where: { $0.id == cardId }) else { return }
            cards = replacingCard(
                at: currentIndex,
                reactionActive: previous.contains(reaction)
            )
        }
    }
}
