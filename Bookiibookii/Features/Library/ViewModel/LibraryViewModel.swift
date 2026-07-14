import Foundation
import Combine

@MainActor
final class LibraryViewModel: ObservableObject {
    enum LayoutStyle {
        case album
        case list
    }

    enum SortOption: CaseIterable {
        case newest
        case oldest
        case rating
        case title

        var title: String {
            switch self {
            case .newest: return "최신순"
            case .oldest: return "과거순"
            case .rating: return "별점순"
            case .title: return "제목순"
            }
        }
    }

    @Published var layoutStyle: LayoutStyle = .album
    @Published var sortOption: SortOption = .newest
    @Published var searchText = ""
    @Published private(set) var books: [LibraryBook] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isShowingSearchResults = false

    private let libraryService: LibraryService

    init(libraryService: LibraryService) {
        self.libraryService = libraryService
    }

    var visibleBooks: [LibraryBook] {
        sort(books.filter { $0.status != .deleted })
    }

    var inProgressBooks: [LibraryBook] {
        visibleBooks.filter { $0.status != .completed }
    }

    var completedBooks: [LibraryBook] {
        visibleBooks.filter { $0.status == .completed }
    }

    var searchResultBooks: [LibraryBook] {
        books.filter { $0.status != .deleted }
    }

    var bookCountText: String {
        "\(visibleBooks.count) 권"
    }

    var searchResultCountText: String {
        "\(searchResultBooks.count) 권"
    }

    func toggleLayout() {
        layoutStyle = layoutStyle == .album ? .list : .album
    }

    func loadBooks() async {
        isShowingSearchResults = false
        await requestBooks(keyword: nil)
    }

    func submitSearch() async {
        guard !isLoading else { return }
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        isShowingSearchResults = !keyword.isEmpty
        books = []
        await requestBooks(keyword: keyword.isEmpty ? nil : keyword)
    }

    private func requestBooks(keyword: String?) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if let keyword {
                books = try await libraryService.searchLibraryBooks(keyword: keyword)
            } else {
                books = try await libraryService.fetchLibraryBooks()
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "서재를 불러오지 못했습니다."
        }
    }

    private func sort(_ books: [LibraryBook]) -> [LibraryBook] {
        books.sorted { left, right in
            switch sortOption {
            case .newest:
                return dateKey(left) == dateKey(right)
                    ? left.id > right.id
                    : dateKey(left) > dateKey(right)
            case .oldest:
                return dateKey(left) == dateKey(right)
                    ? left.id < right.id
                    : dateKey(left) < dateKey(right)
            case .rating:
                let leftRating = left.rating ?? -1
                let rightRating = right.rating ?? -1
                return leftRating == rightRating
                    ? dateKey(left) > dateKey(right)
                    : leftRating > rightRating
            case .title:
                let comparison = left.title.localizedCompare(right.title)
                return comparison == .orderedSame ? left.id < right.id : comparison == .orderedAscending
            }
        }
    }

    private func dateKey(_ book: LibraryBook) -> String {
        book.completedAtISO ?? book.startDate ?? ""
    }
}
