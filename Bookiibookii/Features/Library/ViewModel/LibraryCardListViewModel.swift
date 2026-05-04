import Combine
import Foundation

@MainActor
final class LibraryCardListViewModel: ObservableObject {
    enum SortType {
        case latest
        case page
    }

    @Published private(set) var topComments: [LibraryTopComment] = []
    @Published private(set) var cards: [LibraryCard] = []
    @Published private(set) var isLoading = false
    @Published var sortType: SortType = .latest

    private let groupId: Int
    private let libraryService: LibraryService

    init(groupId: Int, libraryService: LibraryService) {
        self.groupId = groupId
        self.libraryService = libraryService
    }

    var cardCountText: String { "\(cards.count) 개" }
    var sortedCards: [LibraryCard] {
        switch sortType {
        case .latest:
            return cards.sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
        case .page:
            return cards.sorted { $0.page < $1.page }
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await libraryService.fetchLibraryCards(groupId: groupId)
            topComments = result.topComments
            cards = result.cards
        } catch {
            topComments = []
            cards = []
        }
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
                    bookTitle: card.bookTitle,
                    page: card.page,
                    memo: card.memo,
                    imageURL: card.imageURL,
                    creatorName: card.creatorName,
                    isBookmarked: bookmarked,
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
}
