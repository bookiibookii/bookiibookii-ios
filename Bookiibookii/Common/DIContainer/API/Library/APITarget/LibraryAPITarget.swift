import Foundation

enum LibraryAPITarget: APITargetType {
    case fetchBooks
    case searchBooks(keyword: String)
    case fetchCards(groupId: Int)
    case fetchGroupReviews(groupId: Int)
    case fetchBookmarkedCards
    case toggleCardBookmark(cardId: Int)
    case toggleCardReaction(cardId: Int, body: CardReactionToggleRequestBody)
    case fetchCardDetail(cardId: Int)
    case fetchCardComments(cardId: Int)
    case createCardComment(cardId: Int, body: CardCommentCreateRequestBody)
    case cardPresignedPutURL(userBookId: Int)
    case createCard(userBookId: Int, body: CardCreateRequestBody)
    case updateCard(cardId: Int, body: CardUpdateRequestBody)
    case deleteCard(cardId: Int)
    case deleteMemberBook(memberBookId: Int)

    var path: String {
        switch self {
        case .fetchBooks:
            return API.Path.library + "/memberbooks"
        case .searchBooks:
            return API.Path.library + "/memberbooks/search"
        case .fetchCards(let groupId):
            return "/api/member-books/group/\(groupId)/cards"
        case .fetchGroupReviews(let groupId):
            return API.Path.groupReviews(groupId: groupId)
        case .fetchBookmarkedCards:
            return "/api/member-books/cards/bookmarks"
        case .toggleCardBookmark(let cardId):
            return "/api/member-books/cards/\(cardId)/bookmark"
        case .toggleCardReaction(let cardId, _):
            return "/api/member-books/cards/\(cardId)/reactions"
        case .fetchCardDetail(let cardId):
            return "/api/member-books/cards/detail/\(cardId)"
        case .fetchCardComments(let cardId), .createCardComment(let cardId, _):
            return "/api/cards/\(cardId)/comments"
        case .cardPresignedPutURL(let userBookId):
            return "/api/member-books/\(userBookId)/cards/presigned-url"
        case .createCard(let userBookId, _):
            return "/api/member-books/\(userBookId)/cards"
        case .updateCard(let cardId, _):
            return "/api/member-books/cards/\(cardId)"
        case .deleteCard(let cardId):
            return "/api/member-books/cards/\(cardId)"
        case .deleteMemberBook(let memberBookId):
            return API.Path.library + "/memberbooks/\(memberBookId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchBooks, .searchBooks, .fetchCards, .fetchGroupReviews,
             .fetchBookmarkedCards, .fetchCardDetail, .fetchCardComments:
            return .get
        case .toggleCardBookmark, .toggleCardReaction, .updateCard:
            return .patch
        case .deleteCard, .deleteMemberBook:
            return .delete
        case .createCardComment, .cardPresignedPutURL, .createCard:
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
        case .updateCard(_, let body):
            return try? JSONEncoder().encode(body)
        case .createCardComment(_, let body):
            return try? JSONEncoder().encode(body)
        case .toggleCardReaction(_, let body):
            return try? JSONEncoder().encode(body)
        case .toggleCardBookmark:
            return nil
        default:
            return nil
        }
    }

    var headers: [String: String] {
        switch self {
        case .createCard, .createCardComment, .toggleCardReaction, .updateCard:
            return ["Content-Type": "application/json"]
        default:
            return [:]
        }
    }
}
