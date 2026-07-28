import Foundation
import Combine
import KakaoSDKCommon
import KakaoSDKUser
import KakaoSDKAuth
import GoogleSignIn
import UIKit

// 안드로이드 LoginViewModel + LoginActivity.loginToKakao 로직 대응
final class LoginViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var loginSucceeded = false

    private let authService: AuthService
    private let appleSignInController = AppleSignInController()

    init(authService: AuthService) {
        self.authService = authService
    }

    // MARK: - 카카오 로그인 진입점
    func loginWithKakao() {
        guard !isLoading else { return }
        setLoading(true)

        // 카카오톡 앱 설치 여부에 따라 분기 (안드로이드 isKakaoTalkLoginAvailable 대응)
        if UserApi.isKakaoTalkLoginAvailable() {
            loginWithKakaoTalk()
        } else {
            loginWithKakaoAccount()
        }
    }

    // MARK: - 카카오톡 앱으로 로그인
    private func loginWithKakaoTalk() {
        UserApi.shared.loginWithKakaoTalk { [weak self] token, error in
            guard let self else { return }

            if let error {
                // 사용자가 취소한 경우 (ClientErrorCause.Cancelled 대응)
                if let sdkError = error as? SdkError, sdkError.isClientFailed {
                    self.setLoading(false)
                    return
                }
                // 카카오톡 앱 로그인 실패 → 카카오 계정으로 폴백
                self.loginWithKakaoAccount()
                return
            }

            guard let token else { self.setLoading(false); return }
            Task { [weak self] in await self?.sendToBackend(token.accessToken, socialType: "KAKAO") }
        }
    }

    // MARK: - 카카오 계정(웹)으로 로그인
    private func loginWithKakaoAccount() {
        UserApi.shared.loginWithKakaoAccount { [weak self] token, error in
            guard let self else { return }
            guard let token, error == nil else {
                self.setLoading(false)
                return
            }
            Task { [weak self] in await self?.sendToBackend(token.accessToken, socialType: "KAKAO") }
        }
    }

    // MARK: - 구글 로그인
    func loginWithGoogle() {
        guard !isLoading else { return }
        setLoading(true)

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            setLoading(false)
            return
        }

        let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String ?? ""
        let serverClientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_SERVER_CLIENT_ID") as? String
        let config = GIDConfiguration(clientID: clientID, serverClientID: serverClientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { [weak self] result, error in
            guard let self else { return }

            if let error = error as? GIDSignInError, error.code == .canceled {
                self.setLoading(false)
                return
            }

            guard error == nil, let idToken = result?.user.idToken?.tokenString else {
                self.setLoading(false)
                return
            }

            Task { [weak self] in await self?.sendToBackend(idToken, socialType: "GOOGLE") }
        }
    }

    // MARK: - 애플 로그인
    func loginWithApple() {
        guard !isLoading else { return }
        setLoading(true)

        Task { [weak self] in
            guard let self else { return }
            do {
                let identityToken = try await appleSignInController.requestIdentityToken()
                await sendToBackend(identityToken, socialType: "APPLE")
            } catch AppleSignInError.canceled {
                // 사용자가 취소한 경우 (카카오·구글과 동일하게 조용히 종료)
                setLoading(false)
            } catch {
                print("❌ [APPLE] 로그인 실패: \(error)")
                setLoading(false)
            }
        }
    }

    private func sendToBackend(_ token: String, socialType: String) async {
        do {
            let result = try await authService.login(socialType: socialType, token: token)
            TokenManager.shared.saveLoginResult(result)
            await MainActor.run { loginSucceeded = true }
        } catch {
            print("❌ [\(socialType)] 백엔드 로그인 실패: \(error)")
            await MainActor.run { setLoading(false) }
        }
    }

    private func setLoading(_ value: Bool) {
        Task { @MainActor in self.isLoading = value }
    }
}
