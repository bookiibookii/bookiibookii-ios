import SwiftUI

// 프레임은 자동으로만 전환되며(페이드 인/아웃), 수동 스와이프는 지원하지 않는다.
// 프레임 1~3 = 스플래시(모두 노출), 4~7 = 인트로(미로그인 시에만, 마지막 "시작" → onFinish).
struct SplashView: View {
    /// 인트로(4~7)까지 보여줄지 여부. 보통 `!TokenManager.shared.hasAccessToken`.
    var showsIntro: Bool = true
    let onFinish: () -> Void

    @State private var page = 0

    private var frameCount: Int { showsIntro ? 7 : 3 }
    private var lastIndex: Int { frameCount - 1 }

    var body: some View {
        ZStack {
            Color("uiBg").ignoresSafeArea()

            frameView(page)
                .id(page)
                .transition(.opacity)
        }
        .task(id: page) {
            guard let duration = autoAdvanceDuration(for: page) else { return }
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            if page < lastIndex {
                withAnimation(.easeInOut(duration: 0.5)) { page += 1 }
            } else {
                onFinish()   // 스플래시 마지막 프레임(토큰 경로)은 자동 종료
            }
        }
    }

    /// nil이면 자동 전환하지 않고 사용자 동작(시작 버튼)을 기다린다.
    private func autoAdvanceDuration(for index: Int) -> Double? {
        // 인트로 마지막 프레임(7)은 "시작" 버튼 대기
        if showsIntro && index == lastIndex { return nil }
        return index <= 2 ? 1.6 : 2.6   // 스플래시는 빠르게, 인트로는 여유있게
    }

    // MARK: - 프레임 라우팅
    @ViewBuilder
    private func frameView(_ index: Int) -> some View {
        switch index {
        case 0: frame1
        case 1: introTextFrame(title: "읽고, 교환하고, 기록해요.", emphasis: "부키부키")
        case 2: introTextFrame(title: "부키부키에서", emphasis: "교환독서 파트너를 찾아보세요!")
        case 3: featureFrame(heading: "오늘은 누구와\n어떤 책으로 만나볼까요?") { GroupPreviewCard() }
        case 4: featureFrame(heading: "책을 교환하는 모든 순간을\n단계별로 관리해요.") { TrackerPreviewCard() }
        case 5: featureFrame(heading: "서로의 문장을 공유하며\n넓어지는 우리만의 서재") { LibraryPreviewCard() }
        case 6: featureFrame(heading: "지금 부키부키에서\n나와 꼭 맞는 독서 파트너를 찾아보세요!", showsStart: true) { ReviewPreviewCard() }
        default: EmptyView()
        }
    }

    // MARK: - 상단 워드마크 헤더 (프레임 2~7)
    private var wordmarkHeader: some View {
        Image("ic_bookii_text")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 204, height: 22)
            .foregroundColor(Color("main200"))
            .frame(height: 68)
    }

    // MARK: - 프레임 1: 중앙 대형 워드마크
    private var frame1: some View {
        Image("ic_bookii_text")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 300, height: 32)
            .foregroundColor(Color("main200"))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 프레임 2~3: 상단 워드마크 + 화면 정중앙 주황 태그라인
    private func introTextFrame(title: String, emphasis: String) -> some View {
        ZStack {
            // 태그라인은 화면 정중앙 (피그마 top 1/2)
            VStack(spacing: 4) {
                Text(title)
                    .font(.pretendard(size: 24, weight: .medium))
                Text(emphasis)
                    .font(.pretendard(size: 24, weight: .bold))
            }
            .foregroundColor(Color("main200"))
            .tracking(-0.24)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 워드마크는 상단 헤더
            VStack(spacing: 0) {
                wordmarkHeader
                Spacer()
            }
        }
    }

    // MARK: - 프레임 4~7: 상단 워드마크 + 검정 헤드라인 + 기능 미리보기 카드
    private func featureFrame<Preview: View>(
        heading: String,
        showsStart: Bool = false,
        @ViewBuilder preview: () -> Preview
    ) -> some View {
        // 화면 크기 베이스 + overlay(.top)로 콘텐츠 상단을 확실히 고정한다.
        // (ZStack/frame은 화면보다 큰 콘텐츠를 가운데 정렬해 헤더를 위로 밀어 잘리게 함)
        Color("uiBg")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // 콘텐츠: 상단 고정 → 카드가 길면 화면 하단에서만 잘림(크롭)
            .overlay(alignment: .top) {
                VStack(spacing: 0) {
                    wordmarkHeader

                    Text(heading)
                        .font(.pretendard(size: 20, weight: .semibold))
                        .foregroundColor(Color("grey900"))
                        .tracking(-0.2)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)   // 카드가 길어도 헤드라인 압축 방지
                        .padding(.top, 32)

                    Spacer().frame(height: 28)

                    preview()
                }
                .frame(maxWidth: .infinity)
            }
            // 하단 영역을 배경색으로 덮어 카드를 깔끔히 크롭 (피그마 footer 대응)
            .overlay(alignment: .bottom) {
                if showsStart {
                    // 프레임 7: 하단 고정 "시작" 버튼
                    FooterButton(text: "시작", style: .dark, action: onFinish)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 16)
                        .frame(maxWidth: .infinity)
                        .background(Color("uiBg"))
                } else {
                    // 프레임 4~6: 카드 하단을 가리는 배경 푸터 (프레임7 "시작" 버튼 영역과 동일 높이: 72+12+16)
                    Color("uiBg").frame(maxWidth: .infinity).frame(height: 100)
                }
            }
            .clipped()
    }
}

#Preview {
    SplashView(showsIntro: true, onFinish: {})
}
