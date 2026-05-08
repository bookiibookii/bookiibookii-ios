import Foundation

enum InquiryAPITarget: APITargetType {
    case list
    case create(InquiryCreateRequestDto)

    var path: String { API.Path.inquiry }

    var method: HTTPMethod {
        switch self {
        case .list: return .get
        case .create: return .post
        }
    }

    var body: Data? {
        switch self {
        case .create(let payload):
            return try? JSONEncoder().encode(payload)
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
