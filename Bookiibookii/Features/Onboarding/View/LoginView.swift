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

                logoSection

                Spacer()

                // 로그인 성공 문구(tv_login_complete 대응) ↔ SNS 로그인 영역 전환
                if viewModel.loginSucceeded {
                    Text("로그인이 성공적으로 완료되었습니다")
                        .pretendardText(size: 18)
                        .foregroundColor(Color("white"))
                } else if !viewModel.isLoading {
                    snsSection
                }

                Spacer().frame(height: 36)

                termsNotice

                Spacer().frame(height: 34)
            }
        }
        // 약관 안내 문구 위에 뜨도록 하단 여백을 키운다
        .toast($viewModel.toast, bottomPadding: 110)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: viewModel.loginSucceeded) { _, succeeded in
            guard succeeded else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                PushNotificationManager.shared.registerAfterLogin()
                let destination: NavigationDestination = TokenManager.shared.isOnboardingDone ? .mainTab : .onboarding
                container.navigationRouter.hardReset(to: destination)
                PushNotificationManager.shared.handlePendingRedirectIfNeeded()
            }
        }
    }

    // MARK: - 로고 + 워드마크 + 태그라인
    private var logoSection: some View {
        VStack(spacing: 20) {
            Image("ic_logo_symbol")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .foregroundColor(Color("white"))

            Image("ic_bookii_text")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 204, height: 22)
                .foregroundColor(Color("white"))

            (
                Text("읽고, 교환하고, 기록하다 -\n")
                    .font(.pretendard(size: 14, weight: .regular))
                + Text("부키부키")
                    .font(.pretendard(size: 14, weight: .bold))
                + Text("에서 교환독서 파트너를 찾아보세요")
                    .font(.pretendard(size: 14, weight: .regular))
            )
            .foregroundColor(Color("white"))
            .tracking(-0.14)
            .lineSpacing(4)
            .multilineTextAlignment(.center)
        }
    }

    // MARK: - SNS 로그인 영역 (안내 문구 + 원형 버튼 3개)
    private var snsSection: some View {
        VStack(spacing: 12) {
            Text("SNS 계정으로 간편 가입하기")
                .pretendardText(size: 14)
                .foregroundColor(Color("white"))

            HStack(spacing: 24) {
                circleButton(icon: "ic_kakao", background: Color("kakao"), action: viewModel.loginWithKakao)
                circleButton(icon: "ic_google", background: Color("white"), action: viewModel.loginWithGoogle)
                circleButton(icon: "ic_apple", background: Color("black"), tint: Color("white"), action: viewModel.loginWithApple)
            }
        }
    }

    private func circleButton(
        icon: String,
        background: Color,
        tint: Color? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Group {
                if let tint {
                    Image(icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(tint)
                } else {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(width: 36, height: 36)
            .frame(width: 80, height: 80)
            .background(background)
            .clipShape(Circle())
        }
    }

    // MARK: - 약관 안내 (tv_terms_notice 대응)
    // "서비스 약관"/"개인정보 처리방침"만 클릭 가능(흰색 밑줄) → 외부 브라우저로 열림
    private static let termsURL = URL(string: "https://www.bookiibookii.com/terms")!
    private static let privacyURL = URL(string: "https://www.bookiibookii.com/privacy")!

    private var termsAttributed: AttributedString {
        func link(_ text: String, _ url: URL) -> AttributedString {
            var part = AttributedString(text)
            part.link = url
            part.underlineStyle = .single
            part.foregroundColor = Color("white")
            return part
        }
        var result = AttributedString("로그인하면 부키부키의 ")
        result += link("서비스 약관", Self.termsURL)
        result += AttributedString(" 및 ")
        result += link("개인정보 처리방침", Self.privacyURL)
        result += AttributedString("에 동의하게 됩니다.")
        return result
    }

    private var termsNotice: some View {
        Text(termsAttributed)
            .font(.pretendard(size: 14, weight: .regular))
            .foregroundColor(Color("white"))
            .tint(Color("white"))
            .tracking(-0.14)
            .lineSpacing(4)
            .multilineTextAlignment(.leading)   // 줄 내용은 좌측 정렬
            .fixedSize(horizontal: false, vertical: true)
            .frame(alignment: .center)          // 블록 자체는 화면 가운데
            .padding(.horizontal, 16)
    }
}

#Preview {
    LoginView(authService: AuthService())
        .environmentObject(DIContainer())
}
