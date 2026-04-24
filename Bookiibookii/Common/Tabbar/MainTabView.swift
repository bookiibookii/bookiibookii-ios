import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var container: DIContainer

    init(container: DIContainer) {}

    @State private var selectedTab: BookiiTabCase = .home

    var body: some View {
        selectedTab.contentView(container: container, selectTab: { selectedTab = $0 })
            .environmentObject(container)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                tabBar
            }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(BookiiTabCase.allCases, id: \.rawValue) { tab in
                tabBarItem(tab: tab)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("white"))
                .shadow(color: Color("black").opacity(0.08), radius: 8, x: 0, y: -2)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color("grey200"), lineWidth: 1)
                )
        )
        .background(
            Color("grey100").ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabBarItem(tab: BookiiTabCase) -> some View {
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
                    .foregroundColor(isSelected ? Color("grey900") : Color("grey400"))

                Text(tab.title)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? Color("grey900") : Color("grey400"))
            }
            .frame(maxWidth: .infinity)
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
