import SwiftUI

/// 메인 탭 식별자 (안드로이드 하단 네비 5탭 대응)
enum BookiiTabCase: Int, CaseIterable {
    case home
    case group
    case tracker
    case library
    case myPage

    var title: String {
        switch self {
        case .home: return "홈"
        case .group: return "그룹"
        case .tracker: return "트래커"
        case .library: return "서재"
        case .myPage: return "마이페이지"
        }
    }

    var iconName: String {
        switch self {
        case .home: return "ic_tab_home"
        case .group: return "ic_tab_group"
        case .tracker: return "ic_tab_tracker"
        case .library: return "ic_tab_library"
        case .myPage: return "ic_tab_mypage"
        }
    }

    @ViewBuilder
    func contentView(container _: DIContainer) -> some View {
        switch self {
        case .home: HomeView()
        case .group: GroupView()
        case .tracker: TrackerView()
        case .library: LibraryView()
        case .myPage: MyPageView()
        }
    }
}
