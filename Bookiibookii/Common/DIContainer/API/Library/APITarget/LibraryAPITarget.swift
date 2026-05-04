import Foundation

enum LibraryAPITarget: APITargetType {
    case fetchBooks
    case searchBooks(keyword: String)
    case fetchCards(groupId: Int)
    case toggleCardBookmark(cardId: Int)
    case cardPresignedPutURL(userBookId: Int)
    case createCard(userBookId: Int, body: CardCreateRequestBody)

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
        case .cardPresignedPutURL(let userBookId):
            return "/api/cards/\(userBookId)/presigned-url"
        case .createCard(let userBookId, _):
            return "/api/cards/\(userBookId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchBooks, .searchBooks, .fetchCards:
            return .get
        case .toggleCardBookmark:
            return .patch
        case .cardPresignedPutURL, .createCard:
            return .post
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

    var body: Data? {
        switch self {
        case .createCard(_, let body):
            return try? JSONEncoder().encode(body)
        default:
            return nil
        }
    }

    var headers: [String: String] {
        switch self {
        case .createCard:
            return ["Content-Type": "application/json"]
        default:
            return [:]
        }
    }
}
