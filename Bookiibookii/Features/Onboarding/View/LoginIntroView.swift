import SwiftUI

// 안드로이드 LoginIntroAnimActivity 대응
struct LoginIntroView: View {
    @EnvironmentObject private var container: DIContainer

    // MARK: - 텍스트 내용
    private let initialDesc = "독서 취향 기반 교환독서\n부키부키"
    private let cardImages = ["img_anim_01", "img_anim_02", "img_anim_03"]
    private let descByCard = [
        "안심할 수 있는 비대면 교환독서",
        "서로의 문장을\n공유하며 넓어지는 우리만의 서재",
        "소중한 후기로 가꾸는\n나에게 꼭 맞는 독서 파트너와의 만남"
    ]

    // MARK: - 레이아웃 상태
    @State private var isReady = false
    @State private var hasStarted = false
    @State private var logoY: CGFloat = 0
    @State private var descY: CGFloat = 0
    @State private var pagerY: CGFloat = 0

    // MARK: - 애니메이션 상태
    @State private var descOpacity: Double = 0
    @State private var pagerOpacity: Double = 0
    @State private var descText: String = "독서 취향 기반 교환독서\n부키부키"
    @State private var currentPage: Int = 0
    @State private var showStartButton = false
    @State private var startBtnOpacity: Double = 0
    @State private var startBtnOffset: CGFloat = 8
    @State private var hasNavigated = false

    // MARK: - Body
    // GeometryReader를 최상위에 두어야 NavigationStack에서 safeAreaInsets를 올바르게 받음
    // ZStack으로 감싸면 geo.safeAreaInsets.top = 0 이 되어 카메라 영역과 겹치는 버그 발생
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 상태바 영역까지 흰 배경 확장 (상태바와 배경색 공유)
                Color.white.ignoresSafeArea()

                if isReady {
                    let W = geo.size.width

                    // 1. 타이틀 로고 (중앙 → 상단으로 이동)
                    Image("ic_bookii_text")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 204, height: 22)
                        .foregroundColor(Color("main200"))
                        .position(x: W / 2, y: logoY)

                    // 2. 소개 문구 (중앙 → 위로 이동)
                    Text(descText)
                        .font(.system(size: 23, weight: .medium))
                        .foregroundColor(Color("main200"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(width: W - 40)
                        .opacity(descOpacity)
                        .position(x: W / 2, y: descY)

                    // 3. 카드 캐러셀 (아래에서 등장)
                    carouselView(width: W)
                        .frame(height: 270)
                        .opacity(pagerOpacity)
                        .position(x: W / 2, y: pagerY)
                        .allowsHitTesting(false)

                    // 4. 시작하기 버튼 (마지막 카드에서 등장)
                    if showStartButton {
                        Button(action: navigateToLogin) {
                            Text("시작하기")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 72)
                                .background(Color("grey900"))
                                .cornerRadius(20)
                        }
                        .frame(width: W - 40)
                        .opacity(startBtnOpacity)
                        .offset(y: startBtnOffset)
                        .position(
                            x: W / 2,
                            y: geo.size.height - Self.safeAreaBottom - 28 - 36
                        )
                    }
                }
            }
            .onAppear {
                guard !hasStarted else { return }
                hasStarted = true

                // geo.safeAreaInsets는 .ignoresSafeArea() 안에서 0을 반환하는 SwiftUI 버그로
                // UIKit에서 직접 읽어야 정확한 값을 얻을 수 있음
                let H = geo.size.height
                let safeT = Self.safeAreaTop

                logoY = H * 0.5
                descY = H * 0.5 + 18
                pagerY = H * 0.5 + 43

                isReady = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) {
                    runAnimation(H: H, safeT: safeT)
                }
            }
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - 캐러셀 (scale/alpha 트랜스폼 포함)
    // Android sidePadding=40dp 대응: 모든 슬롯 340pt 통일 → 양 옆 25pt peek
    // portrait 카드(img_anim_02)가 현재일 때 양 옆 landscape 카드가 흐리게 보임
    private func carouselView(width: CGFloat) -> some View {
        let slotWidth: CGFloat = 340
        let maxH: CGFloat = 270

        return ZStack {
            ForEach(0..<cardImages.count, id: \.self) { i in
                let dist = CGFloat(i - currentPage)
                let absPos = min(abs(dist), 1.0)

                Image(cardImages[i])
                    .resizable()
                    .scaledToFit()
                    .frame(width: slotWidth, height: maxH)
                    .scaleEffect(0.94 + (1.0 - absPos) * 0.06)
                    .opacity(0.4 + (1.0 - absPos) * 0.6)
                    .offset(x: dist * slotWidth)
                    .animation(.easeInOut(duration: 0.4), value: currentPage)
            }
        }
        .frame(width: width, height: maxH)
    }

    // MARK: - 애니메이션 시퀀스
    // 안드로이드 onCreate 타이밍 그대로 재현
    private func runAnimation(H: CGFloat, safeT: CGFloat) {
        let logoFinalY  = safeT + 24 + 11   // 타이틀 상단이 safeTop+36 위치
        let descFinalY  = H * 0.5 - 180     // 중앙에서 180pt 위
        let pagerFinalY = H * 0.5 + 23      // 중앙에서 23pt 아래

        // Step 1: 로고 위로 (t=0, 700ms)
        withAnimation(.easeInOut(duration: 0.7)) {
            logoY = logoFinalY
        }

        // Step 2: 문구 페이드인 (t=650ms, 350ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation(.easeOut(duration: 0.35)) {
                descOpacity = 1
                descY = H * 0.5  // 18pt 슬라이드업
            }
        }

        // Step 3: 문구 위로 (t=1200ms, 400ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 0.4)) {
                descY = descFinalY
            }
        }

        // Step 4: 카드 등장 + 첫 카드 문구 + 오토슬라이드 (t=1600ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            animateDescChange(to: descByCard[0])

            withAnimation(.easeOut(duration: 0.4)) {
                pagerOpacity = 1
                pagerY = pagerFinalY
            }

            // 첫 슬라이드: 2200ms 후 (안드로이드 FIRST_SLIDE_DELAY_MS=2200)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                slideNext()
            }
        }
    }

    // MARK: - 오토슬라이드 (안드로이드 startAutoSlide 대응)
    private func slideNext() {
        let next = currentPage + 1
        guard next < cardImages.count else { return }

        withAnimation(.easeInOut(duration: 0.4)) {
            currentPage = next
        }
        animateDescChange(to: descByCard[next])

        if next == cardImages.count - 1 {
            // 마지막 카드: 350ms 후 시작 버튼 노출
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                showStartButton = true
                withAnimation(.easeOut(duration: 0.25)) {
                    startBtnOpacity = 1
                    startBtnOffset = 0
                }
            }
        } else {
            // 다음 슬라이드: 2000ms 후
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                slideNext()
            }
        }
    }

    // MARK: - 문구 페이드 전환 (안드로이드 animateDescChange 대응)
    private func animateDescChange(to newText: String) {
        withAnimation(.easeOut(duration: 0.12)) {
            descOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            descText = newText
            withAnimation(.easeIn(duration: 0.18)) {
                descOpacity = 1
            }
        }
    }

    // MARK: - Safe Area (UIKit 직접 조회)
    // geo.safeAreaInsets는 .ignoresSafeArea() 컨텍스트에서 0 반환하는 SwiftUI 버그 존재
    private static var safeAreaTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 44
    }

    private static var safeAreaBottom: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 34
    }

    private func navigateToLogin() {
        guard !hasNavigated else { return }
        hasNavigated = true
        container.navigationRouter.hardReset(to: .login)
    }
}

#Preview {
    LoginIntroView()
        .environmentObject(DIContainer())
}
