import Foundation

/// 안드로이드 MainActivity.dispatchNotificationRedirect 대응.
@MainActor
enum NotificationRedirectDispatcher {
    static func dispatch(_ redirect: NotificationRedirect, router: NavigationRouter) {
        switch redirect.redirectType {
        case "EXPLORE_HOME":
            router.selectedTab = .home
            router.popToRoot()

        case "TRACKER_HOME":
            router.selectedTab = .tracker
            router.popToRoot()

        case "APPLICATION_MANAGEMENT":
            guard let groupId = redirect.groupId else { return }
            router.popToRoot()
            router.push(to: .groupDetail(groupId: groupId, openApplicants: true))

        case "GROUP_DETAIL":
            guard let groupId = redirect.groupId else { return }
            router.popToRoot()
            router.push(to: .groupDetail(groupId: groupId, openApplicants: false))

        case "TRACKER_DETAIL":
            guard let groupId = redirect.groupId else { return }
            router.selectedTab = .tracker
            router.popToRoot()
            router.push(to: .trackerDetail(groupId: groupId))

        case "TRACKER_COMMENT":
            guard let groupId = redirect.groupId else { return }
            router.selectedTab = .tracker
            router.popToRoot()
            router.push(to: .trackerComment(groupId: groupId, title: redirect.title ?? ""))

        case "BOOK_CARD_DETAIL":
            guard let cardId = redirect.cardId else { return }
            router.selectedTab = .library
            router.popToRoot()
            router.push(to: .libraryCardDetail(cardId: cardId, userBookId: nil))

        case "NOTICE_DETAIL":
            // 안드로이드도 미구현. 공지 목록으로 안내.
            router.popToRoot()
            router.push(to: .notice)

        default:
            break
        }
    }
}
