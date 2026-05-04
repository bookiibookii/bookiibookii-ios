import Foundation

enum LibraryAPITarget: APITargetType {
    case fetchBooks
    case searchBooks(keyword: String)
    case fetchCards(groupId: Int)
    case toggleCardBookmark(cardId: Int)

    var path: String {
        switch self {
        case .fetchBooks:
            return API.Path.library + "/books"
        case .searchBooks:
            return API.Path.library + "/search"
        case .fetchCards(let groupId):
            return "/api/cards/group/\(groupId)"
        case .toggleCardBookmark(let cardId):
            return "/api/cards/\(cardId)/bookmark"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchBooks, .searchBooks, .fetchCards:
            return .get
        case .toggleCardBookmark:
            return .patch
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .searchBooks(let keyword):
            return [URLQueryItem(name: "keyword", value: keyword)]
        default:
            return []
        }
    }
}
