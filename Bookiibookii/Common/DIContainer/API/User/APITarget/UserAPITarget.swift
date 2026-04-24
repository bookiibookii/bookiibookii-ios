import Foundation

enum UserAPITarget: APITargetType {
    case checkNickname(String)
    case presignedURL
    case completeOnboarding(OnboardingRequest)
    case mypage

    var path: String {
        switch self {
        case .checkNickname:
            return API.Path.users + "/name-validation"
        case .presignedURL:
            return API.Path.users + "/me/image/presigned-url"
        case .completeOnboarding:
            return API.Path.onboarding
        case .mypage:
            return API.Path.mypage
        }
    }

    var method: HTTPMethod {
        switch self {
        case .mypage: return .get
        case .checkNickname, .presignedURL, .completeOnboarding: return .post
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .checkNickname(let nickname):
            return [URLQueryItem(name: "nickname", value: nickname)]
        default:
            return []
        }
    }

    var body: Data? {
        switch self {
        case .completeOnboarding(let request):
            return try? JSONEncoder().encode(request)
        default:
            return nil
        }
    }

    var headers: [String: String] {
        switch self {
        case .presignedURL, .completeOnboarding:
            return ["Content-Type": "application/json"]
        default:
            return [:]
        }
    }
}
