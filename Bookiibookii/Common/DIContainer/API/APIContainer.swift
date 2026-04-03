import Foundation

final class APIContainer: Sendable {
    let auth: AuthService
    let interceptor: AuthInterceptor

    init(auth: AuthService = AuthService()) {
        self.auth = auth
        self.interceptor = AuthInterceptor(authService: auth)
    }
}
