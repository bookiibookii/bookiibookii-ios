import Combine
import Foundation

@MainActor
final class LibraryBookmarkedCardsViewModel: ObservableObject {
    enum SortType {
        case latest
        case oldest
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
        case .oldest:
            return cards.sorted { ($0.createdAt ?? "") < ($1.createdAt ?? "") }
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await libraryService.fetchBookmarkedLibraryCards()
            guard !Task.isCancelled else { return }
            cards = fetched
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            // 새로고침 실패/취소 시 기존 목록 유지
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
