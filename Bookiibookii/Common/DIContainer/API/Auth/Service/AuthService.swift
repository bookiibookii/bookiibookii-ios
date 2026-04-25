import Foundation

// 안드로이드 RetrofitClient + ApiService.postLogin 대응
final class AuthService {
    // 안드로이드 AuthInterceptor.refreshToken 대응
    // Authorization 헤더에 만료된 accessToken, body에 refreshToken 전달
    func refresh(accessToken: String, refreshToken: String) async throws -> RefreshResult {
        let target = AuthAPITarget.refresh(accessToken: accessToken, refreshToken: refreshToken)
        let request = target.asURLRequest()

        let bodyString = request.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? "<nil>"
        print("[AUTH/REFRESH] url=\(request.url?.absoluteString ?? "") method=\(request.httpMethod ?? "?")")
        print("[AUTH/REFRESH] SEND accessToken(tail12)=\(accessToken.suffix(12)) refreshToken(tail12)=\(refreshToken.suffix(12))")
        print("[AUTH/REFRESH] SEND body=\(bodyString)")

        let (data, httpResponse) = try await URLSession.shared.data(for: request)

        let statusCode = (httpResponse as? HTTPURLResponse)?.statusCode ?? -1
        print("[AUTH/REFRESH] RECV status=\(statusCode) body=\(String(data: data, encoding: .utf8)?.prefix(600) ?? "<non-utf8>")")

        guard statusCode != 400, statusCode != 401 else {
            throw AuthError.refreshFailed
        }

        let response = try JSONDecoder().decode(RefreshResponse.self, from: data)

        guard response.isSuccess, let result = response.result else {
            print("[AUTH/REFRESH] isSuccess=\(response.isSuccess) code=\(response.code) message=\(response.message)")
            throw AuthError.refreshFailed
        }
        print("[AUTH/REFRESH] RECV accessToken(tail12)=\(result.accessToken.suffix(12)) refreshToken(tail12)=\(result.refreshToken.suffix(12))")
        return result
    }

    func logout(accessToken: String) async {
        let target = AuthAPITarget.logout(accessToken: accessToken)
        let request = target.asURLRequest()
        _ = try? await URLSession.shared.data(for: request)
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

    var errorDescription: String? {
        switch self {
        case .loginFailed(let msg): return msg
        case .refreshFailed: return "토큰 갱신에 실패했습니다."
        }
    }
}
