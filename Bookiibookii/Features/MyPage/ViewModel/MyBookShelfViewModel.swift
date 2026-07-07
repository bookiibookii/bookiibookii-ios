import Foundation
import SwiftUI
import Combine

@MainActor
final class MyBookShelfViewModel: ObservableObject {
    static let maxRepresentativeCount = 7
    static let maxFavoriteCount = 3

    @Published private(set) var representativeBooks: [BookshelfRepresentativeBook] = []
    @Published private(set) var favoriteBooks: [BookshelfFavoriteBook] = []
    @Published private(set) var completedBooks: [BookshelfCompletedBook] = []
    @Published var isGridView = true
    @Published var sort: CompletedBookSort = .newest
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var isRepresentativeEditSheetPresented = false
    @Published var editingRepresentativeBooks: [BookshelfRepresentativeBook] = []
    @Published private(set) var isRepresentativeMutating = false
    @Published var isFavoriteSearchPresented = false
    @Published var favoriteSearchQuery = ""
    @Published private(set) var favoriteSearchResults: [BookItem] = []
    @Published private(set) var isFavoriteSearching = false
    @Published private(set) var isFavoriteMutating = false

    private var favoriteSearchMode: FavoriteBookSearchMode?
    private var favoriteSearchTask: Task<Void, Never>?

    private let userService: UserService
    private let groupService: GroupService

    init(userService: UserService, groupService: GroupService) {
        self.userService = userService
        self.groupService = groupService
    }

    var representativeCountText: String {
        "\(representativeBooks.count)/\(Self.maxRepresentativeCount)권"
    }

    var favoriteCountText: String {
        "\(favoriteBooks.count)/\(Self.maxFavoriteCount)권"
    }

    var completedCountText: String {
        "\(completedBooks.count)권"
    }

    var sortedCompletedBooks: [BookshelfCompletedBook] {
        switch sort {
        case .newest:
            return completedBooks.sorted { ($0.completedAt ?? "") > ($1.completedAt ?? "") }
        case .oldest:
            return completedBooks.sorted { ($0.completedAt ?? "") < ($1.completedAt ?? "") }
        case .rating:
            return completedBooks.sorted {
                let left = $0.rating ?? -1
                let right = $1.rating ?? -1
                if left == right {
                    return ($0.completedAt ?? "") > ($1.completedAt ?? "")
                }
                return left > right
            }
        case .title:
            return completedBooks.sorted {
                $0.title.localizedCompare($1.title) == .orderedAscending
            }
        }
    }

    func isRepresentative(_ book: BookshelfCompletedBook) -> Bool {
        representativeBooks.contains { representative in
            if let memberBookId = representative.memberBookId {
                return memberBookId == book.memberBookId
            }
            return representative.title == book.title
        }
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await userService.getBookshelf()
            applyBookshelfResult(result)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func openFavoriteAddSearch() {
        guard favoriteBooks.count < Self.maxFavoriteCount else { return }
        favoriteSearchMode = .add
        clearFavoriteSearch()
        isFavoriteSearchPresented = true
    }

    func openFavoriteReplaceSearch(userBookId: Int) {
        favoriteSearchMode = .replace(userBookId: userBookId)
        clearFavoriteSearch()
        isFavoriteSearchPresented = true
    }

    func closeFavoriteSearch() {
        isFavoriteSearchPresented = false
        favoriteSearchMode = nil
        clearFavoriteSearch()
    }

    func onFavoriteSearchQueryChanged() {
        favoriteSearchTask?.cancel()
        let keyword = favoriteSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else {
            favoriteSearchResults = []
            isFavoriteSearching = false
            return
        }

        isFavoriteSearching = true
        favoriteSearchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            do {
                let books = try await groupService.searchBooks(keyword: keyword)
                guard !Task.isCancelled else { return }
                favoriteSearchResults = books
            } catch {
                favoriteSearchResults = []
            }
            isFavoriteSearching = false
        }
    }

    func selectFavoriteBook(_ book: BookItem) async {
        guard let mode = favoriteSearchMode else { return }
        guard !isFavoriteMutating else { return }

        isFavoriteMutating = true
        defer { isFavoriteMutating = false }

        do {
            switch mode {
            case .add:
                try await userService.addFavoriteBook(isbn13: book.isbn13)
            case .replace(let userBookId):
                try await userService.replaceFavoriteBook(userBookId: userBookId, isbn13: book.isbn13)
            }

            let result = try await userService.getBookshelf()
            applyBookshelfResult(result)
            closeFavoriteSearch()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteFavoriteBook(userBookId: Int) async {
        guard !isFavoriteMutating else { return }

        isFavoriteMutating = true
        defer { isFavoriteMutating = false }

        do {
            try await userService.deleteFavoriteBook(userBookId: userBookId)
            let result = try await userService.getBookshelf()
            applyBookshelfResult(result)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func openRepresentativeEdit() {
        guard !representativeBooks.isEmpty else { return }
        editingRepresentativeBooks = representativeBooks.sorted { $0.displayOrder < $1.displayOrder }
        isRepresentativeEditSheetPresented = true
    }

    func metadata(for book: BookshelfRepresentativeBook) -> RepresentativeBookMetadata {
        if let favorite = favoriteBooks.first(where: { $0.userBookId == book.userBookId }) {
            return RepresentativeBookMetadata(author: favorite.author, category: favorite.category)
        }

        if let memberBookId = book.memberBookId,
           let completed = completedBooks.first(where: { $0.memberBookId == memberBookId }) {
            return RepresentativeBookMetadata(author: completed.author, category: completed.category)
        }

        if let completed = completedBooks.first(where: { $0.title == book.title }) {
            return RepresentativeBookMetadata(author: completed.author, category: completed.category)
        }

        return RepresentativeBookMetadata(author: nil, category: nil)
    }

    func reorderEditingRepresentativeBook(userBookId: Int, targetOrder: Int) async {
        let previousEditingBooks = editingRepresentativeBooks
        let previousRepresentativeBooks = representativeBooks

        isRepresentativeMutating = true
        defer { isRepresentativeMutating = false }

        do {
            try await userService.reorderRepresentativeBook(userBookId: userBookId, targetOrder: targetOrder)
            representativeBooks = editingRepresentativeBooks
        } catch {
            editingRepresentativeBooks = previousEditingBooks
            representativeBooks = previousRepresentativeBooks
            errorMessage = error.localizedDescription
        }
    }

    func deleteEditingRepresentativeBook(userBookId: Int) async {
        isRepresentativeMutating = true
        defer { isRepresentativeMutating = false }

        do {
            try await userService.deleteRepresentativeBook(userBookId: userBookId)
            let result = try await userService.getBookshelf()
            applyBookshelfResult(result)
            editingRepresentativeBooks = representativeBooks.sorted { $0.displayOrder < $1.displayOrder }

            if editingRepresentativeBooks.isEmpty {
                isRepresentativeEditSheetPresented = false
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func applyLocalRepresentativeReorder(draggedBookId: Int, overBookId: Int) {
        guard draggedBookId != overBookId,
              let fromIndex = editingRepresentativeBooks.firstIndex(where: { $0.userBookId == draggedBookId }),
              let toIndex = editingRepresentativeBooks.firstIndex(where: { $0.userBookId == overBookId }) else {
            return
        }

        var books = editingRepresentativeBooks
        books.move(
            fromOffsets: IndexSet(integer: fromIndex),
            toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
        )
        editingRepresentativeBooks = books.enumerated().map { index, book in
            book.withDisplayOrder(index + 1)
        }
    }

    func commitRepresentativeReorder(userBookId: Int) async {
        guard let targetOrder = editingRepresentativeBooks.firstIndex(where: { $0.userBookId == userBookId }) else {
            return
        }
        await reorderEditingRepresentativeBook(userBookId: userBookId, targetOrder: targetOrder + 1)
    }

    private func clearFavoriteSearch() {
        favoriteSearchTask?.cancel()
        favoriteSearchQuery = ""
        favoriteSearchResults = []
        isFavoriteSearching = false
    }

    private func applyBookshelfResult(_ result: BookshelfResult) {
        representativeBooks = result.representativeBooks.sorted { $0.displayOrder < $1.displayOrder }
        favoriteBooks = result.favoriteBooks
        completedBooks = result.completedBooks
    }
}
