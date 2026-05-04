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
        let previous = cards[index].isBookmarked
        cards[index] = LibraryCard(
            id: cards[index].id,
            page: cards[index].page,
            memo: cards[index].memo,
            imageURL: cards[index].imageURL,
            creatorName: cards[index].creatorName,
            isBookmarked: !previous,
            createdAt: cards[index].createdAt,
            messageCount: cards[index].messageCount
        )

        do {
            let serverValue = try await libraryService.toggleLibraryCardBookmark(cardId: cardId)
            cards[index] = LibraryCard(
                id: cards[index].id,
                page: cards[index].page,
                memo: cards[index].memo,
                imageURL: cards[index].imageURL,
                creatorName: cards[index].creatorName,
                isBookmarked: serverValue,
                createdAt: cards[index].createdAt,
                messageCount: cards[index].messageCount
            )
        } catch {
            cards[index] = LibraryCard(
                id: cards[index].id,
                page: cards[index].page,
                memo: cards[index].memo,
                imageURL: cards[index].imageURL,
                creatorName: cards[index].creatorName,
                isBookmarked: previous,
                createdAt: cards[index].createdAt,
                messageCount: cards[index].messageCount
            )
        }
    }
}
