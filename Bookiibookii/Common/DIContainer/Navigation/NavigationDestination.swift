import Foundation

/// `navigationDestination(for:)` 라우팅에 사용할 화면 식별자입니다.
/// 기능 추가 시 case만 늘리고 `NavigationRoutingView`의 switch를 맞추면 됩니다.
enum NavigationDestination: Hashable {
    case loginIntro
    case login
    case onboarding
    case mainTab
    case setting
    case accountWithdrawal
    case myReviews(initialTab: MyReviewTab, nickname: String)
    case profileChange
    case addressManagement(initialTab: AddressManagementTab = .delivery)
    case notice
    case noticeDetail(noticeId: Int)
    case faq
    case legalDocument(LegalDocumentType)
    case librarySearch
    case libraryBookmarkedCards
    case libraryCards(book: LibraryBook)
    case libraryCardDetail(cardId: Int, userBookId: Int?)
    case libraryBookmarkedCardDetail(cardId: Int, userBookId: Int?)
    case libraryCardAdd(userBookId: Int, cardType: LibraryCardType, bookTitle: String)
    case libraryCardEdit(cardId: Int, userBookId: Int)
    case togetherReview(userBookId: Int, bookTitle: String)
    case group
    case groupEditor(groupId: Int?)
    case myPage
    case myBookShelf
    case userProfile(nickname: String)
    case userReviews(nickname: String, initialTab: MyReviewTab)
    case userBookShelf(nickname: String)
    case notification
}
