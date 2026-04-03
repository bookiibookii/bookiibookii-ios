import Foundation

// 안드로이드 RetrofitClient + ApiService.postLogin 대응
final class AuthService {
    private let baseURL = URL(string: "https://bookii.gyeonseo.com/")!

    // 안드로이드 AuthInterceptor.refreshToken 대응
    // Authorization 헤더에 만료된 accessToken, body에 refreshToken 전달
    func refresh(accessToken: String, refreshToken: String) async throws -> RefreshResult {
        let url = baseURL.appendingPathComponent("api/auth/refresh")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(RefreshRequest(refreshToken: refreshToken))

        let (data, httpResponse) = try await URLSession.shared.data(for: request)

        guard let statusCode = (httpResponse as? HTTPURLResponse)?.statusCode,
              statusCode != 400, statusCode != 401 else {
            throw AuthError.refreshFailed
        }

        let response = try JSONDecoder().decode(RefreshResponse.self, from: data)

        guard response.isSuccess, let result = response.result else {
            throw AuthError.refreshFailed
        }
        return result
    }

    func login(socialType: String, token: String) async throws -> LoginResult {
        let url = baseURL.appendingPathComponent("api/auth/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(LoginRequest(socialType: socialType, token: token))

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(LoginResponse.self, from: data)

        guard response.isSuccess, let result = response.result else {
            throw AuthError.loginFailed(response.message)
        }
        return result
    }
}

enum AuthError: LocalizedError {
    case loginFailed(String)
    case refreshFailed

    var errorDescription: String? {
        switch self {
        case .loginFailed(let msg): return msg
        case .refreshFailed: return "토큰 갱신에 실패했습니다."
        }
    }
}
