import Combine
import Foundation

@MainActor
final class LibraryBookmarkedCardsViewModel: ObservableObject {
    enum SortType {
        case latest
        case page
    }

    @Published private(set) var cards: [LibraryCard] = []
    @Published private(set) var isLoading = false
    @Published var sortType: SortType = .latest

    private let libraryService: LibraryService

    init(libraryService: LibraryService) {
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
            cards = try await libraryService.fetchBookmarkedLibraryCards()
        } catch {
            cards = []
        }
    }

    func toggleBookmark(cardId: Int) async {
        guard cards.contains(where: { $0.id == cardId && $0.isBookmarkable }) else { return }
        do {
            _ = try await libraryService.toggleLibraryCardBookmark(cardId: cardId)
            await load()
        } catch {
            await load()
        }
    }
}
