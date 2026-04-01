import SwiftUI

// 안드로이드 SplashActivity 대응
struct SplashView: View {
    let onFinish: () -> Void

    // MARK: - 배경색: @color/pre_main = #FF7618
    private let backgroundColor = Color(red: 0xFF/255, green: 0x76/255, blue: 0x18/255)

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // 중앙 로고 + 타이틀 (verticalBias=0.42 대응 → 중앙보다 살짝 위)
                logoSection

                // 230dp 간격 (안드로이드 layout_marginTop="230dp" 대응)
                Spacer().frame(height: 230)

                // 로딩 인디케이터 + 상태 텍스트
                loadingSection

                Spacer()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                onFinish()
            }
        }
    }

    // MARK: - 로고 영역 (logoContainer)
    private var logoSection: some View {
        VStack(spacing: 20) {
            // 심볼 로고: ic_bookii_logo_white, 82dp x 82dp
            Image("ic_splash_logo")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 82, height: 82)
                .foregroundColor(.white)

            // 타이틀 이미지: ic_home_logo, 204dp x 21.79dp, tint=white
            Image("ic_splash_title")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 204, height: 22)
                .foregroundColor(.white)
        }
    }

    // MARK: - 로딩 영역 (progressLoading + txtStatus)
    private var loadingSection: some View {
        VStack(spacing: 20) {
            // ProgressBar (indeterminate) 대응
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.8)
                .tint(.white)
                .frame(width: 69, height: 69)

            // splash_loading = "로그인 중입니다..."
            Text("로그인 중입니다...")
                .font(.system(size: 14))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    SplashView(onFinish: {})
}
