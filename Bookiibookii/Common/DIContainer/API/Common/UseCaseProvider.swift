import Foundation

protocol UseCaseProtocol {
    var auth: AuthService { get }
    var user: UserService { get }
    var group: GroupService { get }
    var recommendation: RecommendationService { get }
    var notification: NotificationService { get }
    var notice: NoticeService { get }
    var faq: FaqService { get }
    var keyword: KeywordService { get }
    var tracker: TrackerService { get }
    var library: LibraryService { get }
    var location: LocationService { get }
}

/// 도메인별 API UseCase 진입점을 한곳에서 제공합니다.
final class UseCaseProvider: UseCaseProtocol {
    let auth: AuthService
    let user: UserService
    let group: GroupService
    let recommendation: RecommendationService
    let notification: NotificationService
    let notice: NoticeService
    let faq: FaqService
    let keyword: KeywordService
    let tracker: TrackerService
    let library: LibraryService
    let location: LocationService

    init(auth: AuthService = AuthService()) {
        self.auth = auth
        let interceptor = AuthInterceptor(authService: auth)
        self.user = UserService(interceptor: interceptor)
        self.group = GroupService(interceptor: interceptor)
        self.recommendation = RecommendationService(interceptor: interceptor)
        self.notification = NotificationService(interceptor: interceptor)
        self.notice = NoticeService(interceptor: interceptor)
        self.faq = FaqService(interceptor: interceptor)
        self.keyword = KeywordService(interceptor: interceptor)
        self.tracker = TrackerService(interceptor: interceptor)
        self.library = LibraryService(interceptor: interceptor)
        self.location = LocationService(interceptor: interceptor)
    }
}
