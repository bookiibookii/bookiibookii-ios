import Foundation

// 안드로이드 AuthInterceptor.kt 대응
// 401 응답 시 Access Token 자동 갱신 후 원래 요청 재시도
// actor 사용으로 동시 갱신 방지 (안드로이드 synchronized 블록 대응)
actor AuthInterceptor {
    private let authService: AuthService
    private var isRefreshing = false
    private var pendingContinuations: [CheckedContinuation<String, Error>] = []
    /// 동시에 실패한 요청들이 로그아웃 라우팅을 중복 실행하지 않도록 하는 쿨다운.
    private static let routeCooldown: TimeInterval = 3
    private var lastRoutedAt: Date?

    init(authService: AuthService) {
        self.authService = authService
    }

    // MARK: - 인증 요청 실행 (외부 진입점)
    func request(_ urlRequest: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let sentToken = TokenManager.shared.accessToken
        let authedRequest = attach(token: sentToken, to: urlRequest)
        let (data, response) = try await URLSession.shared.data(for: authedRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 401 else {
            // 서버는 만료(401) 외의 인증 실패를 400/404 + code "AUTH…"로 내려준다.
            // 그대로 두면 갱신도 로그아웃도 없이 실패만 반복되므로 로그아웃해 재로그인을 유도한다.
            if httpResponse.statusCode == 400 || httpResponse.statusCode == 404,
               isAuthFailure(data) {
                await forceLogout()
                throw AuthError.refreshFailed
            }
            return (data, httpResponse)
        }

        // refresh 엔드포인트 자체가 401이면 무한루프 방지 → 로그아웃
        if urlRequest.url?.path.contains("/api/auth/refresh") == true {
            await forceLogout()
            throw AuthError.refreshFailed
        }

        // Access Token 갱신 후 재시도
        let newToken: String
        do {
            newToken = try await refreshIfNeeded(sentToken: sentToken)
        } catch AuthError.refreshFailed {
            // refresh 자체가 400/401 (refreshToken 불일치/만료) → 안드로이드 routeLogout 대응
            await forceLogout()
            throw AuthError.refreshFailed
        }
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
    private func refreshIfNeeded(sentToken: String?) async throws -> String {
        // 요청을 보낸 뒤 다른 요청이 이미 갱신을 마친 경우(요청 시점 토큰 ≠ 현재 토큰)
        // 갱신을 반복하지 않고 현재 토큰으로 바로 재시도한다.
        if let currentToken = TokenManager.shared.accessToken, currentToken != sentToken {
            return currentToken
        }

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

            // refresh는 대기 중인 다른 요청들이 공유하는 작업이므로 호출자(뷰 태스크) 취소가 전파되면 안 된다.
            // 독립 태스크로 감싸 취소 전파를 끊는다.
            let result = try await Task {
                try await authService.refresh(
                    accessToken: expiredToken,
                    refreshToken: refreshToken
                )
            }.value

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

    // MARK: - 인증 실패 판정 (응답 본문의 code가 "AUTH"로 시작하는지)
    private func isAuthFailure(_ data: Data) -> Bool {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let code = json["code"] as? String else { return false }
        return code.hasPrefix("AUTH")
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
        // 홈 진입처럼 요청이 동시에 여러 개 실패하면 화면 전환이 반복되므로 쿨다운 안에서는 한 번만 실행한다.
        let now = Date()
        if let lastRoutedAt, now.timeIntervalSince(lastRoutedAt) < Self.routeCooldown {
            return
        }
        lastRoutedAt = now

        TokenManager.shared.clear()
        await MainActor.run {
            NotificationCenter.default.post(name: .authTokenExpired, object: nil)
        }
    }
}

extension Notification.Name {
    static let authTokenExpired = Notification.Name("authTokenExpired")
}
