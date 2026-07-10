import Foundation

enum FaqAPITarget: APITargetType {
    case list

    var path: String {
        switch self {
        case .list:
            return API.Path.faq
        }
    }

    var method: HTTPMethod { .get }
}
