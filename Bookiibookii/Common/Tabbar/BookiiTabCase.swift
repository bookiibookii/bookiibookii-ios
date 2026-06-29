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
                recommendationService: container.api.recommendation,
                groupService: container.api.group,
                notificationService: container.api.notification,
                trackerService: container.api.tracker,
                onNavigateToGroup: { container.navigationRouter.push(to: .group) }
            )
        case .tracker:
            TrackerView(
                trackerService: container.api.tracker,
                libraryService: container.api.library,
                onNavigateToGroup: { container.navigationRouter.push(to: .group) }
            )
        case .library:
            LibraryView(libraryService: container.api.library)
        }
    }
}
