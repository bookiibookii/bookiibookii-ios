import SwiftUI

// MARK: - 탭 정의 (안드로이드 NavTab enum 대응)
enum TabItem: Int, CaseIterable {
    case home
    case group
    case tracker
    case library
    case myPage

    var title: String {
        switch self {
        case .home:    return "홈"
        case .group:   return "그룹"
        case .tracker: return "트래커"
        case .library: return "서재"
        case .myPage:  return "마이페이지"
        }
    }

    var iconName: String {
        switch self {
        case .home:    return "ic_tab_home"
        case .group:   return "ic_tab_group"
        case .tracker: return "ic_tab_tracker"
        case .library: return "ic_tab_library"
        case .myPage:  return "ic_tab_mypage"
        }
    }
}

// MARK: - 탭 바 색상 (Color+App.swift의 공통 색상 활용)
private extension Color {
    static let tabSelected   = Color.grey900
    static let tabUnselected = Color(hex: "#A4A3A0")
}

// MARK: - 메인 탭 뷰
struct MainTabView: View {
    @State private var selectedTab: TabItem = .home

    var body: some View {
        Group {
            switch selectedTab {
            case .home:    HomeView()
            case .group:   GroupView()
            case .tracker: TrackerView()
            case .library: LibraryView()
            case .myPage:  MyPageView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // safeAreaInset: 바텀 네비게이션 높이만큼 콘텐츠 하단 여백 자동 확보
        // → FAB 등 하단 요소가 네비게이션 바에 가려지지 않음
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomNavigationBar
        }
    }

    // MARK: - 바텀 네비게이션 바 (안드로이드 view_bottom_nav.xml 대응)
    private var bottomNavigationBar: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.rawValue) { tab in
                tabBarItem(tab: tab)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: -2)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(red: 0xE5/255, green: 0xE5/255, blue: 0xE5/255), lineWidth: 1)
                )
        )
        .padding(.horizontal, 0)
    }

    // MARK: - 탭 아이템 (안드로이드 각 itemHome, itemGroup 등 대응)
    private func tabBarItem(tab: TabItem) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(tab.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(isSelected ? .tabSelected : .tabUnselected)

                Text(tab.title)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .tabSelected : .tabUnselected)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView()
}
