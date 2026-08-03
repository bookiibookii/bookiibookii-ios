import Foundation

enum AuthAPITarget: APITargetType {
    case login(socialType: String, token: String, authorizationCode: String?)
    case refresh(accessToken: String, refreshToken: String)
    case logout(accessToken: String)

    var path: String {
        switch self {
        case .login: return API.Path.auth + "/login"
        case .refresh: return API.Path.auth + "/refresh"
        case .logout: return API.Path.auth + "/logout"
        }
    }

    var method: HTTPMethod {
        .post
    }

    var body: Data? {
        switch self {
        case .login(let socialType, let token, let authorizationCode):
            return try? JSONEncoder().encode(
                LoginRequest(socialType: socialType, token: token, authorizationCode: authorizationCode)
            )
        case .refresh(_, let refreshToken):
            return try? JSONEncoder().encode(RefreshRequest(refreshToken: refreshToken))
        case .logout:
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
        }
        return value
    }
}
