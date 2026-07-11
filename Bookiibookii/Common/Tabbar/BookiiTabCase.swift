import SwiftUI

/// 메인 탭 식별자 (안드로이드 하단 네비 3탭: 탐색/트래커/서재)
enum BookiiTabCase: Int, CaseIterable {
    case home      // 라벨 "탐색"
    case tracker
    case library

    var title: String {
        switch self {
        case .home: return "탐색"
        case .tracker: return "트래커"
        case .library: return "서재"
        }
    }

    var iconName: String {
        switch self {
        case .home: return "ic_group_32"
        case .tracker: return "ic_tracker_32"
        case .library: return "ic_book_32"
        }
    }

    @ViewBuilder
    func contentView(container: DIContainer) -> some View {
        switch self {
        case .home:
            HomeView(
                groupService: container.api.group,
                notificationService: container.api.notification,
                userService: container.api.user,
                onNavigateToGroup: { container.navigationRouter.push(to: .group) },
                onCreateGroupTap: { container.navigationRouter.push(to: .groupEditor(groupId: nil)) }
            )
        case .tracker:
            TrackerMainRoute(
                viewModel: TrackerMainViewModel(
                    trackerService: container.api.tracker,
                    notificationService: container.api.notification
                ),
                onProfileTap: { container.navigationRouter.push(to: .myPage) },
                onNotificationTap: { container.navigationRouter.push(to: .notification) },
                onCreateGroupTap: { container.navigationRouter.push(to: .groupEditor(groupId: nil)) }
            )
        case .library:
            LibraryView(libraryService: container.api.library)
        }
    }
}
