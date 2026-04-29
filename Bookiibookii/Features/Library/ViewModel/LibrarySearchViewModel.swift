import Foundation
import Combine

@MainActor
final class LibrarySearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var resultBooks: [LibraryBook] = []
    @Published var recentKeywords: [String] = []
    @Published var isLoading = false

    private let libraryService: LibraryService
    private let storageKey = "library.recent.keywords"

    init(libraryService: LibraryService) {
        self.libraryService = libraryService
        self.recentKeywords = UserDefaults.standard.stringArray(forKey: storageKey) ?? []
    }

    var isShowingRecentKeywords: Bool {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var resultCountText: String {
        "\(resultBooks.count) 권"
    }

    func submitSearch() async {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return }

        addRecentKeyword(keyword)
        isLoading = true
        defer { isLoading = false }

        do {
            resultBooks = try await libraryService.searchLibraryBooks(keyword: keyword)
        } catch {
            resultBooks = []
            print("서재 검색 실패: \(error)")
        }
    }

    func addRecentKeyword(_ keyword: String) {
        let cleaned = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        recentKeywords.removeAll { $0 == cleaned }
        recentKeywords.insert(cleaned, at: 0)
        recentKeywords = Array(recentKeywords.prefix(20))
        UserDefaults.standard.set(recentKeywords, forKey: storageKey)
    }

    func removeRecentKeyword(_ keyword: String) {
        recentKeywords.removeAll { $0 == keyword }
        UserDefaults.standard.set(recentKeywords, forKey: storageKey)
    }

    func selectRecentKeyword(_ keyword: String) async {
        searchText = keyword
        await submitSearch()
    }
}
