import Foundation

protocol UseCaseProtocol {
    var auth: AuthService { get }
    var user: UserService { get }
    var group: GroupService { get }
}

/// 도메인별 API UseCase 진입점을 한곳에서 제공합니다.
final class UseCaseProvider: UseCaseProtocol {
    let auth: AuthService
    let user: UserService
    let group: GroupService

    init(auth: AuthService = AuthService()) {
        self.auth = auth
        let interceptor = AuthInterceptor(authService: auth)
        self.user = UserService(interceptor: interceptor)
        self.group = GroupService(interceptor: interceptor)
    }
}
