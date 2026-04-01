import SwiftUI

struct ContentView: View {
    @State private var showSplash = true

    var body: some View {
        if showSplash {
            SplashView {
                showSplash = false
            }
        } else {
            MainTabView()
        }
    }
}

#Preview {
    ContentView()
}
