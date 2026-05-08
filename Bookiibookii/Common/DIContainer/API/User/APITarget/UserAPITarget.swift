import Foundation

enum UserAPITarget: APITargetType {
    case checkNickname(String)
    case presignedURL
    case completeOnboarding(OnboardingRequest)
    case mypage
    case updateMypage(MypageUpdateRequest)
    case profileChangeInfo
    case updateProfileChangeInfo(ProfileChangeUpdateRequest)

    var path: String {
        switch self {
        case .checkNickname:
            return API.Path.users + "/name-validation"
        case .presignedURL:
            return API.Path.users + "/me/image/presigned-url"
        case .completeOnboarding:
            return API.Path.onboarding
        case .mypage, .updateMypage:
            return API.Path.mypage
        case .profileChangeInfo, .updateProfileChangeInfo:
            return API.Path.users + "/me/profile-change"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .mypage, .profileChangeInfo: return .get
        case .updateMypage: return .patch
        case .updateProfileChangeInfo: return .put
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
        case .updateMypage(let request):
            return try? JSONEncoder().encode(request)
        case .updateProfileChangeInfo(let request):
            return try? JSONEncoder().encode(request)
        default:
            return nil
        }
    }

    var headers: [String: String] {
        switch self {
        case .presignedURL, .completeOnboarding, .updateMypage, .updateProfileChangeInfo:
            return ["Content-Type": "application/json"]
        default:
            return [:]
        }
    }
}
