import SwiftUI

/// 프리뷰·임시 진입용 (앱 실제 엔트리는 `BookiibookiiApp`과 동일한 스택 구성)
struct ContentView: View {
    @StateObject private var container = DIContainer()

    var body: some View {
        NavigationStack(path: $container.navigationRouter.destinations) {
            SplashView {
                container.navigationRouter.hardReset(to: .mainTab)
            }
            .environmentObject(container)
            .navigationDestination(for: NavigationDestination.self) { destination in
                NavigationRoutingView(destination: destination)
                    .environmentObject(container)
            }
        }
    }
}

#Preview {
    ContentView()
}
