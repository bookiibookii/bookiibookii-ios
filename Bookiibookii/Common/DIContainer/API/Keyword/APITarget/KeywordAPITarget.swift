import Foundation

enum KeywordAPITarget: APITargetType {
    case list(sort: KeywordSort)
    case create(KeywordCreateRequest)
    case delete(keywordId: Int)

    var path: String {
        switch self {
        case .list, .create:
            return API.Path.keywords
        case .delete(let keywordId):
            return API.Path.keywords + "/\(keywordId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list:   return .get
        case .create: return .post
        case .delete: return .delete
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .list(let sort):
            return [URLQueryItem(name: "sort", value: sort.rawValue)]
        default:
            return []
        }
    }

    var body: Data? {
        switch self {
        case .create(let request):
            return try? JSONEncoder().encode(request)
        default:
            return nil
        }
    }

    var headers: [String: String] {
        switch self {
        case .create:
            return ["Content-Type": "application/json"]
        default:
            return [:]
        }
    }
}
