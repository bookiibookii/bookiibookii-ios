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
                rootContent
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

    // 온보딩을 마쳤고 토큰도 있으면 스플래시를 건너뛰고 바로 메인으로,
    // 그 외(미로그인 또는 온보딩 미완료)에는 스플래시를 노출한다.
    @ViewBuilder
    private var rootContent: some View {
        if TokenManager.shared.isOnboardingDone && TokenManager.shared.hasAccessToken {
            Color("uiBg")
                .ignoresSafeArea()
                .onAppear { container.navigationRouter.hardReset(to: .mainTab) }
        } else {
            // 인트로(4~7프레임)는 앱을 처음 접하는 사용자에게만 노출한다.
            // 로그인했거나 온보딩을 마친 적 있으면 스플래시 3프레임만 보여준다.
            SplashView(
                showsIntro: !TokenManager.shared.hasAccessToken && !TokenManager.shared.isOnboardingDone
            ) {
                if TokenManager.shared.hasAccessToken {
                    container.navigationRouter.hardReset(to: .onboarding)
                } else {
                    container.navigationRouter.hardReset(to: .login)
                }
            }
        }
    }
}
