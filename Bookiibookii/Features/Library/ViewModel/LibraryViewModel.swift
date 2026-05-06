import Foundation
import Combine

@MainActor
final class LibraryViewModel: ObservableObject {
    enum Tab {
        case inProgress
        case completed
    }

    enum LayoutStyle {
        case grid
        case list
    }

    @Published var selectedTab: Tab = .inProgress
    @Published var layoutStyle: LayoutStyle = .grid
    @Published var books: [LibraryBook] = []
    @Published var isLoading = false

    private let libraryService: LibraryService

    init(libraryService: LibraryService) {
        self.libraryService = libraryService
    }

    var filteredBooks: [LibraryBook] {
        let visibleBooks = books.filter { $0.status != .deleted }

        switch selectedTab {
        case .inProgress:
            return visibleBooks.filter { $0.status == .matched }
        case .completed:
            return visibleBooks.filter { $0.status == .completed }
        }
    }

    var bookCountText: String {
        "\(filteredBooks.count) 권"
    }

    func loadBooks() async {
        isLoading = true
        defer { isLoading = false }

        do {
            books = try await libraryService.fetchLibraryBooks()
        } catch {
            books = []
            print("서재 조회 실패: \(error)")
        }
    }
}
