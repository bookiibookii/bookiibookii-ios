import Foundation

// 안드로이드 RetrofitClient + ApiService.postLogin 대응
final class AuthService {
    // 안드로이드 AuthInterceptor.refreshToken 대응
    // Authorization 헤더에 만료된 accessToken, body에 refreshToken 전달
    func refresh(accessToken: String, refreshToken: String) async throws -> RefreshResult {
        let target = AuthAPITarget.refresh(accessToken: accessToken, refreshToken: refreshToken)
        let request = target.asURLRequest()

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

    func logout(accessToken: String) async {
        let target = AuthAPITarget.logout(accessToken: accessToken)
        let request = target.asURLRequest()
        _ = try? await URLSession.shared.data(for: request)
    }

    // 안드로이드 AuthApi.withdraw 대응 — DELETE /api/auth/withdraw
    func withdraw(accessToken: String) async throws {
        let target = AuthAPITarget.withdraw(accessToken: accessToken)
        let request = target.asURLRequest()

        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        guard let statusCode = (httpResponse as? HTTPURLResponse)?.statusCode,
              (200...299).contains(statusCode) else {
            throw AuthError.withdrawFailed
        }
        let response = try JSONDecoder().decode(SimpleResponse.self, from: data)
        guard response.isSuccess else {
            throw AuthError.withdrawFailed
        }
    }

    func login(socialType: String, token: String) async throws -> LoginResult {
        let target = AuthAPITarget.login(socialType: socialType, token: token)
        let request = target.asURLRequest()

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
    case withdrawFailed

    var errorDescription: String? {
        switch self {
        case .loginFailed(let msg): return msg
        case .refreshFailed: return "토큰 갱신에 실패했습니다."
        case .withdrawFailed: return "회원탈퇴에 실패했습니다."
        }
    }
}
