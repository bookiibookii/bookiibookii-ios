import Foundation

@MainActor
final class LibraryViewModel: ObservableObject {
    enum Tab {
        case inProgress
        case completed
    }

    @Published var selectedTab: Tab = .inProgress
    @Published var books: [LibraryBook] = []
    @Published var isLoading = false

    private let libraryService: LibraryService

    init(libraryService: LibraryService) {
        self.libraryService = libraryService
    }

    var filteredBooks: [LibraryBook] {
        switch selectedTab {
        case .inProgress:
            return books.filter { $0.status == .matched }
        case .completed:
            return books.filter { $0.status == .completed }
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
