import Foundation

enum RecommendationAPITarget: APITargetType {
    case recommendedGroups(refresh: Bool)
    case recommendedBookmates

    var path: String {
        switch self {
        case .recommendedGroups:
            return API.Path.recommendations + "/groups"
        case .recommendedBookmates:
            return API.Path.recommendations + "/bookmates"
        }
    }

    var method: HTTPMethod { .get }

    var queryItems: [URLQueryItem] {
        switch self {
        case .recommendedGroups(let refresh):
            return [URLQueryItem(name: "refresh", value: refresh ? "true" : "false")]
        case .recommendedBookmates:
            return []
        }
    }
}
