import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth
import GoogleSignIn

@main
struct BookiibookiiApp: App {
    @StateObject private var container = DIContainer()

    init() {
        // 안드로이드 KakaoSdk.init 대응
        // KAKAO_NATIVE_APP_KEY는 Config.xcconfig → Info.plist를 통해 주입됩니다.
        let appKey = Bundle.main.object(forInfoDictionaryKey: "KAKAO_NATIVE_APP_KEY") as? String ?? ""
        KakaoSDK.initSDK(appKey: appKey)
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $container.navigationRouter.destinations) {
                SplashView {
                    container.navigationRouter.hardReset(to: .login)
                }
                .environmentObject(container)
                .navigationDestination(for: NavigationDestination.self) { destination in
                    NavigationRoutingView(destination: destination)
                        .environmentObject(container)
                }
            }
            // 카카오 로그인 콜백 URL 처리 (안드로이드 onNewIntent 대응)
            .onReceive(NotificationCenter.default.publisher(for: .authTokenExpired)) { _ in
                container.navigationRouter.hardReset(to: .login)
            }
            .onOpenURL { url in
                if AuthApi.isKakaoTalkLoginUrl(url) {
                    _ = AuthController.handleOpenUrl(url: url)
                } else {
                    GIDSignIn.sharedInstance.handle(url)
                }
            }
        }
    }
}
