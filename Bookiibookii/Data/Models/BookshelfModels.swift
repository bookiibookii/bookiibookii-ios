import Foundation

// MARK: - GET /api/mypage/bookshelf

struct BookshelfResult: Decodable, Equatable {
    let completedBooks: [BookshelfCompletedBook]
    let favoriteBooks: [BookshelfFavoriteBook]
    let representativeBooks: [BookshelfRepresentativeBook]
}

struct BookshelfCompletedBook: Decodable, Identifiable, Equatable {
    let memberBookId: Int
    let groupId: Int
    let title: String
    let author: String
    let image: String
    let category: String?
    let rating: Double?
    let completedAt: String?

    var id: Int { memberBookId }

    var authorWithCategory: String {
        guard let category, !category.isEmpty else { return author }
        return "\(author)(\(category))"
    }

    var formattedCompletedDate: String? {
        guard let completedAt, !completedAt.isEmpty else { return nil }
        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd"
        input.locale = Locale(identifier: "ko_KR")
        guard let date = input.date(from: completedAt) else { return completedAt }
        let output = DateFormatter()
        output.dateFormat = "yyyy.MM.dd."
        output.locale = Locale(identifier: "ko_KR")
        return output.string(from: date)
    }
}

struct BookshelfFavoriteBook: Decodable, Identifiable, Equatable {
    let userBookId: Int
    let title: String
    let author: String
    let category: String?
    let image: String

    var id: Int { userBookId }

    var authorWithCategory: String {
        guard let category, !category.isEmpty else { return author }
        return "\(author)(\(category))"
    }
}

struct BookshelfRepresentativeBook: Decodable, Identifiable, Equatable {
    let userBookId: Int
    let memberBookId: Int?
    let title: String
    let displayOrder: Int
    let isFavorite: Bool
    let rating: Double?

    var id: Int { userBookId }

    func withDisplayOrder(_ displayOrder: Int) -> BookshelfRepresentativeBook {
        BookshelfRepresentativeBook(
            userBookId: userBookId,
            memberBookId: memberBookId,
            title: title,
            displayOrder: displayOrder,
            isFavorite: isFavorite,
            rating: rating
        )
    }
}

struct ReorderRepresentativeRequest: Encodable {
    let userBookId: Int
    let targetOrder: Int
}

struct AddRepresentativeBookRequest: Encodable {
    let userBookId: Int?
    let memberBookId: Int?
}

struct FavoriteBookISBNRequest: Encodable {
    let isbn13: String
}

struct RepresentativeBookMetadata: Equatable {
    let author: String?
    let category: String?
}

enum FavoriteBookSearchMode: Equatable {
    case add
    case replace(userBookId: Int)
}

enum CompletedBookSort: String, CaseIterable {
    case newest
    case oldest
    case rating
    case title

    var label: String {
        switch self {
        case .newest: return "최신순"
        case .oldest: return "과거순"
        case .rating: return "별점순"
        case .title: return "제목순"
        }
    }
}
