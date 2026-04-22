import Foundation

final class APIContainer: Sendable {
    let auth: AuthService
    let interceptor: AuthInterceptor
    let user: UserService

    init(auth: AuthService = AuthService()) {
        self.auth = auth
        let interceptor = AuthInterceptor(authService: auth)
        self.interceptor = interceptor
        self.user = UserService(interceptor: interceptor)
    }
}
