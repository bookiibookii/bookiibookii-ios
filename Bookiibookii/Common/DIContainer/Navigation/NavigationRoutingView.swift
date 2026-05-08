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
        case .onboardingProfile:
            OnboardingProfileView(userService: container.api.user)
                .environmentObject(container)
        case .onboardingSteps(let name, let s3Key):
            OnboardingStepsView(name: name, s3Key: s3Key, userService: container.api.user)
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
        case .recievedReview:
            RecievedReviewView()
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .profileChange:
            ProfileChangeView(userService: container.api.user)
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .questoin:
            QuestoinView()
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .qustionDetail:
            QustionDetailView()
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .notice:
            NoticeView()
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        case .noticeDetail(let title, let dateText, let content):
            NoticeDetailView(title: title, dateText: dateText, content: content)
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
        case .hostDelivery(let groupId):
            HostDeliveryView(
                groupId: groupId,
                service: container.api.tracker,
                onBack: { container.navigationRouter.pop() }
            )
            .environmentObject(container)
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
        case .guestDelivery(let groupId):
            GuestDeliveryView(
                groupId: groupId,
                service: container.api.tracker,
                onBack: { container.navigationRouter.pop() }
            )
            .environmentObject(container)
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
        case .hostDirect(let groupId):
            HostDirectView(
                groupId: groupId,
                service: container.api.tracker,
                onBack: { container.navigationRouter.pop() }
            )
            .environmentObject(container)
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
        case .guestDirect(let groupId):
            GuestDirectView(
                groupId: groupId,
                service: container.api.tracker,
                onBack: { container.navigationRouter.pop() }
            )
            .environmentObject(container)
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
        }
    }
}
