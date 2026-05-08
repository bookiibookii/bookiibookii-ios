import Foundation

/// `navigationDestination(for:)` 라우팅에 사용할 화면 식별자입니다.
/// 기능 추가 시 case만 늘리고 `NavigationRoutingView`의 switch를 맞추면 됩니다.
enum NavigationDestination: Hashable {
    case loginIntro
    case login
    case onboardingProfile
    case onboardingSteps(name: String, s3Key: String?)
    case mainTab
    case setting
    case recievedReview
    case profileChange
    case questoin
    case qustionDetail
    case notice
    case noticeDetail(title: String, dateText: String, content: String)
    case report
    case reportDetail
    case librarySearch
    case libraryBookmarkedCards
    case libraryCards(book: LibraryBook)
    case libraryCardDetail(cardId: Int, userBookId: Int?)
    case libraryCardAdd(userBookId: Int)
    case libraryCardEdit(cardId: Int, userBookId: Int)
    case togetherReview(userBookId: Int, bookTitle: String)
    case hostDelivery(groupId: Int)
    case guestDelivery(groupId: Int)
    case hostDirect(groupId: Int)
    case guestDirect(groupId: Int)
}
