import SwiftUI

// 안드로이드 LoginActivity 대응
struct LoginView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: LoginViewModel

    init(authService: AuthService) {
        _viewModel = StateObject(wrappedValue: LoginViewModel(authService: authService))
    }

    var body: some View {
        ZStack {
            Color("main200").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // 중앙 로고 + 타이틀 (verticalBias=0.42 대응)
                logoSection

                Spacer()

                // 로그인 성공 문구 (tv_login_complete 대응)
                if viewModel.loginSucceeded {
                    Text("로그인이 성공적으로 완료되었습니다")
                        .font(.system(size: 18))
                        .tracking(-0.36)
                        .foregroundColor(Color("white"))
                        .padding(.bottom, 32)
                }

                // 버튼 묶음 + 약관 (group_login_buttons 대응)
                if !viewModel.isLoading {
                    buttonSection
                        .padding(.horizontal, 20)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: viewModel.loginSucceeded) { _, succeeded in
            guard succeeded else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                let destination: NavigationDestination = TokenManager.shared.isOnboardingDone ? .mainTab : .onboardingProfile
                container.navigationRouter.hardReset(to: destination)
            }
        }
    }

    // MARK: - 로고 영역 (logoContainer)
    private var logoSection: some View {
        VStack(spacing: 20) {
            Image("ic_splash_logo")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 82, height: 82)
                .foregroundColor(Color("white"))

            Image("ic_title")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 204, height: 22)
                .foregroundColor(Color("white"))
        }
    }

    // MARK: - 버튼 영역 (btn_kakao_login, btn_google_login, tv_terms_notice)
    private var buttonSection: some View {
        VStack(spacing: 0) {
            loginButton(
                iconName: "ic_kakao",
                text: "카카오로 시작하기",
                backgroundColor: Color("kakao"),
                textColor: Color("grey900"),
                action: viewModel.loginWithKakao
            )

            Spacer().frame(height: 12)

            loginButton(
                iconName: "ic_google",
                text: "구글로 시작하기",
                backgroundColor: Color("grey100"),
                textColor: Color("grey900"),
                action: viewModel.loginWithGoogle
            )

            Spacer().frame(height: 12)

            Text("로그인하면 서비스 약관 및 개인정보 처리방침에 동의한 것으로 간주합니다.")
                .font(.system(size: 14))
                .foregroundColor(Color("white"))
                .multilineTextAlignment(.center)

            Spacer().frame(height: 24)
        }
    }

    private func loginButton(
        iconName: String,
        text: String,
        backgroundColor: Color,
        textColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text(text)
                    .font(.system(size: 16))
                    .tracking(-0.32)
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(backgroundColor)
            .cornerRadius(14)
        }
    }
}

#Preview {
    LoginView(authService: AuthService())
        .environmentObject(DIContainer())
}
