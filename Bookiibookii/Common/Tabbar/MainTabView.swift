import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var container: DIContainer

    init(container: DIContainer) {}

    @State private var selectedTab: BookiiTabCase = .home

    var body: some View {
        selectedTab.contentView(container: container)
            .environmentObject(container)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                tabBar
            }
    }

    // 피그마 알약형 플로팅 탭바 (너비 256, 선택 탭 = 회색 알약 + 아이콘만)
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(BookiiTabCase.allCases, id: \.rawValue) { tab in
                tabBarItem(tab: tab)
            }
        }
        .padding(8)
        .frame(width: 256)
        .background(
            Capsule()
                .fill(Color("white"))
                .overlay(Capsule().stroke(Color("grey100"), lineWidth: 1))
        )
        .padding(.bottom, 12)
    }

    private func tabBarItem(tab: BookiiTabCase) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 2) {
                Image(tab.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(Color("grey900"))

                if !isSelected {
                    Text(tab.title)
                        .pretendardText(size: 11, weight: .medium)
                        .foregroundColor(Color("grey900"))
                }
            }
            .frame(width: 80, height: 60)
            .background(
                Capsule().fill(isSelected ? Color("grey100") : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

extension MainTabView {
    // NavigationStack 내에서 back 제스처/버튼 노출 방지
    func withHiddenNavigation() -> some View {
        self.toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    let container = DIContainer()
    MainTabView(container: container)
        .environmentObject(container)
}
