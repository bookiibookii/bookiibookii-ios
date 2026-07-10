import Foundation
import Combine

@MainActor
final class OtherUserBookShelfViewModel: ObservableObject {
    static let maxRepresentativeCount = 7
    static let maxFavoriteCount = 3

    let nickname: String

    @Published private(set) var representativeBooks: [BookshelfRepresentativeBook] = []
    @Published private(set) var favoriteBooks: [BookshelfFavoriteBook] = []
    @Published private(set) var completedBooks: [BookshelfCompletedBook] = []
    @Published var isGridView = false
    @Published var sort: CompletedBookSort = .newest
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let userService: UserService

    init(nickname: String, userService: UserService) {
        self.nickname = nickname
        self.userService = userService
    }

    var representativeCountText: String {
        "\(representativeBooks.count)/\(Self.maxRepresentativeCount)권"
    }

    var favoriteCountText: String {
        "\(favoriteBooks.count)/\(Self.maxFavoriteCount)권"
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
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await userService.getProfileBookshelf(nickname: nickname)
            representativeBooks = result.representativeBooks.sorted { $0.displayOrder < $1.displayOrder }
            favoriteBooks = result.favoriteBooks
            completedBooks = result.completedBooks
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "책장을 불러오지 못했습니다."
        }
    }
}
