import Foundation

// 안드로이드 AuthInterceptor.kt 대응
// 401 응답 시 Access Token 자동 갱신 후 원래 요청 재시도
// actor 사용으로 동시 갱신 방지 (안드로이드 synchronized 블록 대응)
actor AuthInterceptor {
    private let authService: AuthService
    private var isRefreshing = false
    private var pendingContinuations: [CheckedContinuation<String, Error>] = []

    init(authService: AuthService) {
        self.authService = authService
    }

    // MARK: - 인증 요청 실행 (외부 진입점)
    func request(_ urlRequest: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let authedRequest = attach(token: TokenManager.shared.accessToken, to: urlRequest)
        let (data, response) = try await URLSession.shared.data(for: authedRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 401 else {
            return (data, httpResponse)
        }

        // refresh 엔드포인트 자체가 401이면 무한루프 방지 → 로그아웃
        if urlRequest.url?.path.contains("/api/auth/refresh") == true {
            await forceLogout()
            throw AuthError.refreshFailed
        }

        // Access Token 갱신 후 재시도
        let newToken = try await refreshIfNeeded()
        let retryRequest = attach(token: newToken, to: urlRequest)
        let (retryData, retryResponse) = try await URLSession.shared.data(for: retryRequest)

        guard let retryHTTPResponse = retryResponse as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // 재시도도 401이면 로그아웃
        if retryHTTPResponse.statusCode == 401 {
            await forceLogout()
            throw AuthError.refreshFailed
        }

        return (retryData, retryHTTPResponse)
    }

    // MARK: - 토큰 갱신 (동시 호출 시 첫 번째만 실제 갱신, 나머지는 대기)
    private func refreshIfNeeded() async throws -> String {
        if isRefreshing {
            // 이미 갱신 중 → 완료될 때까지 대기
            return try await withCheckedThrowingContinuation { continuation in
                pendingContinuations.append(continuation)
            }
        }

        isRefreshing = true

        do {
            guard let expiredToken = TokenManager.shared.accessToken,
                  let refreshToken = TokenManager.shared.refreshToken else {
                throw AuthError.refreshFailed
            }

            let result = try await authService.refresh(
                accessToken: expiredToken,
                refreshToken: refreshToken
            )

            TokenManager.shared.accessToken = result.accessToken
            TokenManager.shared.refreshToken = result.refreshToken
            TokenManager.shared.userId = result.userId

            // 대기 중인 요청들에 새 토큰 전달
            let waiting = pendingContinuations
            pendingContinuations = []
            isRefreshing = false
            waiting.forEach { $0.resume(returning: result.accessToken) }

            return result.accessToken
        } catch {
            let waiting = pendingContinuations
            pendingContinuations = []
            isRefreshing = false
            waiting.forEach { $0.resume(throwing: error) }
            throw error
        }
    }

    // MARK: - Authorization 헤더 주입
    private func attach(token: String?, to request: URLRequest) -> URLRequest {
        guard let token else { return request }
        var modified = request
        modified.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return modified
    }

    // MARK: - 강제 로그아웃 (Refresh Token 만료 시)
    private func forceLogout() async {
        TokenManager.shared.clear()
        await MainActor.run {
            NotificationCenter.default.post(name: .authTokenExpired, object: nil)
        }
    }
}

extension Notification.Name {
    static let authTokenExpired = Notification.Name("authTokenExpired")
}
