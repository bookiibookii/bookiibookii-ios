import Foundation

enum LibraryAPITarget: APITargetType {
    case fetchBooks
    case searchBooks(keyword: String)

    var path: String {
        switch self {
        case .fetchBooks:
            return API.Path.library + "/books"
        case .searchBooks:
            return API.Path.library + "/search"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchBooks, .searchBooks:
            return .get
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
