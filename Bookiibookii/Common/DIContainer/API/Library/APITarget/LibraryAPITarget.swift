import Foundation

enum LibraryAPITarget: APITargetType {
    case fetchBooks
    case searchBooks(keyword: String)
    case fetchCards(groupId: Int)
    case fetchBookmarkedCards
    case toggleCardBookmark(cardId: Int)
    case fetchCardDetail(cardId: Int)
    case fetchCardComments(cardId: Int)
    case createCardComment(cardId: Int, body: CardCommentCreateRequestBody)
    case cardPresignedPutURL(userBookId: Int)
    /// 카드 이미지 변경 시 (`CardController` 문서). 신규 카드용은 `cardPresignedPutURL(userBookId:)`.
    case cardPresignedPutURLForImageUpdate(cardId: Int)
    case createCard(userBookId: Int, body: CardCreateRequestBody)
    case updateCard(cardId: Int, body: CardCreateRequestBody)

    var path: String {
        switch self {
        case .fetchBooks:
            return API.Path.library + "/books"
        case .searchBooks:
            return API.Path.library + "/search"
        case .fetchCards(let groupId):
            return "/api/cards/group/\(groupId)"
        case .fetchBookmarkedCards:
            return "/api/cards/bookmarks"
        case .toggleCardBookmark(let cardId):
            return "/api/cards/\(cardId)/bookmark"
        case .fetchCardDetail(let cardId):
            return "/api/cards/detail/\(cardId)"
        case .fetchCardComments(let cardId), .createCardComment(let cardId, _):
            return "/api/cards/\(cardId)/comments"
        case .cardPresignedPutURL(let userBookId):
            return "/api/cards/\(userBookId)/presigned-url"
        case .cardPresignedPutURLForImageUpdate(let cardId):
            return "/api/cards/\(cardId)/images/presigned-url"
        case .createCard(let userBookId, _):
            return "/api/cards/\(userBookId)"
        case .updateCard(let cardId, _):
            return "/api/cards/\(cardId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchBooks, .searchBooks, .fetchCards, .fetchBookmarkedCards, .fetchCardDetail, .fetchCardComments:
            return .get
        case .toggleCardBookmark, .updateCard:
            return .patch
        case .createCardComment, .cardPresignedPutURL, .cardPresignedPutURLForImageUpdate, .createCard:
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
        case .createCard(_, let body), .updateCard(_, let body):
            return try? JSONEncoder().encode(body)
        case .createCardComment(_, let body):
            return try? JSONEncoder().encode(body)
        case .toggleCardBookmark:
            return nil
        default:
            return nil
        }
    }

    var headers: [String: String] {
        switch self {
        case .createCard, .createCardComment, .updateCard:
            return ["Content-Type": "application/json"]
        default:
            return [:]
        }
    }
}
