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
        case .mainTab:
            MainTabView(container: container)
                .environmentObject(container)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        }
    }
}
