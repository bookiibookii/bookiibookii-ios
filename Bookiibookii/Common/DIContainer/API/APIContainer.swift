import Foundation

final class APIContainer: Sendable {
    let useCaseProvider: UseCaseProvider

    init(auth: AuthService = AuthService()) {
        self.useCaseProvider = UseCaseProvider(auth: auth)
    }

    // 하위 호환: 기존 호출부(api.auth / api.user / api.group) 유지
    var auth: AuthService { useCaseProvider.auth }
    var user: UserService { useCaseProvider.user }
    var group: GroupService { useCaseProvider.group }
    var recommendation: RecommendationService { useCaseProvider.recommendation }
    var notification: NotificationService { useCaseProvider.notification }
    var notice: NoticeService { useCaseProvider.notice }
    var inquiry: InquiryService { useCaseProvider.inquiry }
    var keyword: KeywordService { useCaseProvider.keyword }
    var tracker: TrackerService { useCaseProvider.tracker }
    var library: LibraryService { useCaseProvider.library }
    var location: LocationService { useCaseProvider.location }
}
