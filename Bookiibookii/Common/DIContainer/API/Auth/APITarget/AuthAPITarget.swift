import Foundation

enum AuthAPITarget: APITargetType {
    case login(socialType: String, token: String)
    case refresh(accessToken: String, refreshToken: String)
    case logout(accessToken: String)
    case withdraw(accessToken: String)

    var path: String {
        switch self {
        case .login: return API.Path.auth + "/login"
        case .refresh: return API.Path.auth + "/refresh"
        case .logout: return API.Path.auth + "/logout"
        case .withdraw: return API.Path.auth + "/withdraw"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .withdraw: return .delete
        default:        return .post
        }
    }

    var body: Data? {
        switch self {
        case .login(let socialType, let token):
            return try? JSONEncoder().encode(LoginRequest(socialType: socialType, token: token))
        case .refresh(_, let refreshToken):
            return try? JSONEncoder().encode(RefreshRequest(refreshToken: refreshToken))
        case .logout, .withdraw:
            return nil
        }
    }

    var headers: [String: String] {
        var value: [String: String] = [:]
        switch self {
        case .login:
            value["Content-Type"] = "application/json"
        case .refresh(let accessToken, _):
            value["Content-Type"] = "application/json"
            value["Authorization"] = "Bearer \(accessToken)"
        case .logout(let accessToken):
            value["Authorization"] = "Bearer \(accessToken)"
        case .withdraw(let accessToken):
            value["Authorization"] = "Bearer \(accessToken)"
        }
        return value
    }
}
