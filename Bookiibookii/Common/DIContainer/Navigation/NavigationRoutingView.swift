import SwiftUI

/// `NavigationDestination` → 실제 화면 매핑 (앱 전역 라우팅 허브)
struct NavigationRoutingView: View {
    @EnvironmentObject private var container: DIContainer

    let destination: NavigationDestination

    var body: some View {
        switch destination {
        case .loginIntro:
            LoginIntroView()
                .environmentObject(container)
        case .login:
            LoginView(authService: container.api.auth)
                .environmentObject(container)
        case .onboarding:
            OnboardingView(userService: container.api.user, groupService: container.api.group)
                .environmentObject(container)
        case .mainTab:
            MainTabView(container: container)
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .setting:
            SettingView()
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .myReviews(let initialTab, let nickname):
            MyReviewsView(
                userService: container.api.user,
                initialTab: initialTab,
                nickname: nickname
            )
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .profileChange:
            ProfileChangeView(userService: container.api.user)
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .addressManagement:
            AddressManagementView(locationService: container.api.location)
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .questoin:
            QuestoinView(inquiryService: container.api.inquiry)
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .qustionDetail:
            QustionDetailView(inquiryService: container.api.inquiry)
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .notice:
            NoticeView(noticeService: container.api.notice)
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .noticeDetail(let noticeId):
            NoticeDetailView(noticeId: noticeId, noticeService: container.api.notice)
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .report:
            ReportView()
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .reportDetail:
            ReportDetailView()
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .librarySearch:
            LibrarySearchView(libraryService: container.api.library)
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .libraryBookmarkedCards:
            LibraryBookmarkedCardsView(libraryService: container.api.library)
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .libraryCards(let book):
            LibraryCardListView(
                book: book,
                libraryService: container.api.library,
                groupService: container.api.group,
                trackerService: container.api.tracker
            )
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .libraryCardDetail(let cardId, let userBookId):
            LibraryCardDetailView(cardId: cardId, userBookId: userBookId, libraryService: container.api.library)
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .libraryCardAdd(let userBookId):
            CardAddView(userBookId: userBookId, libraryService: container.api.library)
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .libraryCardEdit(let cardId, let userBookId):
            CardAddView(mode: .edit(cardId: cardId, userBookId: userBookId), libraryService: container.api.library)
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .togetherReview(let userBookId, let bookTitle):
            TogetherReviewView(
                userBookId: userBookId,
                bookTitle: bookTitle,
                groupService: container.api.group
            )
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .group:
            GroupView(groupService: container.api.group)
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .myPage:
            MyPageView(userService: container.api.user)
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .myBookShelf:
            MyBookShelfView(
                userService: container.api.user,
                groupService: container.api.group
            )
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .notification:
            NotificationView(
                notificationService: container.api.notification,
                keywordService: container.api.keyword,
                groupService: container.api.group
            )
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        }
    }
}
