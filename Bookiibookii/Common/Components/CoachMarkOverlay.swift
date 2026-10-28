import SwiftUI

/// PreferenceKey 등 nonisolated 컨텍스트에서 딕셔너리 키로 쓰인다.
/// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` 환경에서도 Hashable이
/// main-actor isolated로 추론되지 않도록 ==/hash를 nonisolated로 둔다.
enum CoachMarkTarget: Sendable {
    case libraryBookmark
    case libraryShare
}

extension CoachMarkTarget: Equatable {
    nonisolated static func == (lhs: CoachMarkTarget, rhs: CoachMarkTarget) -> Bool {
        switch (lhs, rhs) {
        case (.libraryBookmark, .libraryBookmark),
             (.libraryShare, .libraryShare):
            return true
        default:
            return false
        }
    }
}

extension CoachMarkTarget: Hashable {
    nonisolated func hash(into hasher: inout Hasher) {
        switch self {
        case .libraryBookmark:
            hasher.combine(0)
        case .libraryShare:
            hasher.combine(1)
        }
    }
}

enum CoachMarkCoordinateSpace {
    static let libraryCardDetail = "library-card-detail"
}

struct CoachMarkFramePreferenceKey: PreferenceKey {
    static var defaultValue: [CoachMarkTarget: CGRect] = [:]

    static func reduce(
        value: inout [CoachMarkTarget: CGRect],
        nextValue: () -> [CoachMarkTarget: CGRect]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, latest in latest })
    }
}

/// 화면별 코치마크 완료 상태. 기기 단위로 한 번만 노출한다.
enum CoachMarkKind {
    case libraryCardDetail
    case trackerComment

    var storageKey: String {
        switch self {
        case .libraryCardDetail: return "coach_mark.library_card_detail.v1.completed"
        case .trackerComment: return "coach_mark.tracker_comment.v1.completed"
        }
    }

    var pageCount: Int {
        switch self {
        case .libraryCardDetail: return 4
        case .trackerComment: return 3
        }
    }
}

/// Figma LIB-03 / TRK 댓글 코치마크 공통 오버레이.
///
/// 완료 버튼을 누른 시점에만 저장한다. 따라서 앱 종료·뒤로가기로 중단한 경우에는
/// 다음 진입에서 다시 표시되어 사용자가 안내를 놓치지 않는다.
struct CoachMarkOverlay: View {
    let kind: CoachMarkKind
    let targetFrames: [CoachMarkTarget: CGRect]
    let onCompleted: () -> Void

    @State private var page = 0

    init(
        kind: CoachMarkKind,
        targetFrames: [CoachMarkTarget: CGRect] = [:],
        onCompleted: @escaping () -> Void
    ) {
        self.kind = kind
        self.targetFrames = targetFrames
        self.onCompleted = onCompleted
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.76)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 28)

                coachContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                pageIndicator
                    .padding(.top, 16)
                    .padding(.bottom, 36)

                Button(action: advance) {
                    Text(page == kind.pageCount - 1 ? "확인" : "다음")
                        .pretendardText(size: 16, weight: .regular)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color("main200"))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
        .accessibilityAddTraits(.isModal)
    }

    @ViewBuilder
    private var coachContent: some View {
        switch kind {
        case .libraryCardDetail:
            libraryCardContent
        case .trackerComment:
            trackerCommentContent
        }
    }

    @ViewBuilder
    private var libraryCardContent: some View {
        switch page {
        case 0:
            LibraryCoachReactionStep(
                message: coachMessage(
                    "가장 가까운 반응으로\n독서카드에 ",
                    emphasis: "공감",
                    suffix: "해보세요."
                )
            )
            .transition(coachStepTransition)

        case 1:
            LibraryCoachHighlightStep(
                targetFrame: targetFrames[.libraryBookmark],
                size: 32,
                pulseColor: Color("main200"),
                pulseOpacity: 0.6,
                highlight: Image("ic_bookmark_fill")
                    .renderingMode(.template)
                    .resizable()
                    .foregroundColor(Color("main200"))
                    .frame(width: 20, height: 20)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color("main100")))
                    .overlay(Circle().stroke(Color("main200"), lineWidth: 0.5)),
                message: coachMessage(
                    "모아서 보고 싶은\n독서카드를 ",
                    emphasis: "북마크",
                    suffix: "해요.",
                    trailing: true
                )
            )
            .transition(coachStepTransition)

        case 2:
            LibraryCoachHighlightStep(
                targetFrame: targetFrames[.libraryShare],
                size: 40,
                pulseColor: .white,
                pulseOpacity: 0.5,
                highlight: Image("ic_share")
                    .renderingMode(.template)
                    .resizable()
                    .foregroundColor(Color("grey900"))
                    .frame(width: 32, height: 32)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white)),
                message: coachMessage(
                    "마음에 든 독서카드는\n",
                    emphasis: "공유",
                    suffix: "하거나 ",
                    trailingEmphasis: "저장",
                    trailingSuffix: "할 수 있어요.",
                    trailing: true
                )
            )
            .transition(coachStepTransition)

        default:
            LibraryCoachSwipeStep(
                message: coachMessage(
                    "옆으로 스와이프해\n다른 독서카드를 ",
                    emphasis: "넘겨 볼",
                    suffix: " 수 있어요."
                )
            )
            .transition(coachStepTransition)
        }
    }

    @ViewBuilder
    private var trackerCommentContent: some View {
        // 단계마다 별도 뷰로 두어, 페이지를 넘기면 애니메이션이 처음부터 다시 시작되고
        // 페이지를 떠나면 반복 Task가 취소된다.
        switch page {
        case 0:
            TrackerCoachTapLongPressStep(
                tapMessage: coachMessage(
                    "댓글을 탭하여 ",
                    emphasis: "답장",
                    suffix: "하고,"
                ),
                longPressMessage: coachMessage(
                    "꾹 눌러 ",
                    emphasis: "삭제",
                    suffix: "하세요."
                )
            )
            .transition(coachStepTransition)

        case 1:
            TrackerCoachScrollButtonStep(
                upMessage: coachMessage(
                    "위 버튼은 ",
                    emphasis: "오래된 댓글",
                    suffix: "로,"
                ),
                downMessage: coachMessage(
                    "아래 버튼은 ",
                    emphasis: "최신 댓글",
                    suffix: "로 이동해요."
                )
            )
            .transition(coachStepTransition)

        default:
            TrackerCoachPullUpStep(
                message: coachMessage(
                    "위로 당기면\n",
                    emphasis: "최신 댓글",
                    suffix: "을 불러와요."
                )
            )
            .transition(coachStepTransition)
        }
    }

    private var coachStepTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.animation(.coachFastOutSlowIn(duration: 0.3)),
            removal: .opacity.animation(.coachFastOutSlowIn(duration: 0.2))
        )
    }

    private var pageIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<kind.pageCount, id: \.self) { index in
                Capsule()
                    .fill(Color.white.opacity(index == page ? 0.5 : 0.2))
                    .frame(width: index == page ? 8 : 20, height: 8)
            }
        }
    }

    private func coachMessage(
        _ prefix: String,
        emphasis: String,
        suffix: String,
        trailingEmphasis: String = "",
        trailingSuffix: String = "",
        trailing: Bool = false
    ) -> some View {
        (
            Text(prefix)
                .foregroundColor(.white)
            + Text(emphasis)
                .foregroundColor(Color("main200"))
            + Text(suffix)
                .foregroundColor(.white)
            + Text(trailingEmphasis)
                .foregroundColor(Color("main200"))
            + Text(trailingSuffix)
                .foregroundColor(.white)
        )
        .pretendardText(size: 18, weight: .medium)
        .multilineTextAlignment(trailing ? .trailing : .center)
        .lineSpacing(2)
        .frame(maxWidth: .infinity, alignment: trailing ? .trailing : .center)
    }

    private func advance() {
        if page == kind.pageCount - 1 {
            onCompleted()
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                page += 1
            }
        }
    }
}

// MARK: - 코치마크 단계 공통

extension Animation {
    /// Material FastOutSlowIn 곡선.
    static func coachFastOutSlowIn(duration: Double) -> Animation {
        .timingCurve(0.4, 0, 0.2, 1, duration: duration)
    }

    /// 살짝 튀는 팝인 스프링 (dampingRatio 0.5, stiffness 1500).
    static let coachPopIn: Animation = .interpolatingSpring(
        mass: 1,
        stiffness: 1500,
        damping: 2 * 0.5 * 1500.squareRoot()
    )
}

private func coachSleep(milliseconds: UInt64) async throws {
    try await Task.sleep(nanoseconds: milliseconds * 1_000_000)
}

/// 오버레이 콘텐츠 영역은 상단 여백과 하단 버튼을 뺀 영역이다.
/// 단계 콘텐츠는 화면 전체 기준으로 배치해야 하므로 전역 좌표로 보정한다.
private struct CoachScreenLayout<Content: View>: View {
    @ViewBuilder let content: (_ screen: CGSize, _ safeTop: CGFloat, _ origin: CGPoint) -> Content

    var body: some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .global)
            let safeTop = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.windows.first?.safeAreaInsets.top ?? 0
            content(UIScreen.main.bounds.size, safeTop, frame.origin)
        }
    }
}

/// 화면 전체를 기준으로 alignment에 맞춰 두되, 아래쪽을 bottomPadding만큼 비운다.
private struct CoachScreenAligned<Content: View>: View {
    var alignment: Alignment = .center
    let bottomPadding: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        CoachScreenLayout { screen, _, origin in
            content
                .padding(.bottom, bottomPadding)
                .frame(width: screen.width, height: screen.height, alignment: alignment)
                .offset(x: -origin.x, y: -origin.y)
        }
    }
}

// MARK: - 독서카드 상세 코치마크 단계

private let libraryCoachReactionIcons = ["ic_empathy", "ic_good", "ic_fun", "ic_sad", "ic_angry"]

/// 1단계: 공감. 반응 아이콘이 차례로 팝인한다.
private struct LibraryCoachReactionStep<Message: View>: View {
    let message: Message

    @State private var iconScales: [CGFloat] = Array(repeating: 0, count: libraryCoachReactionIcons.count)

    var body: some View {
        CoachScreenAligned(alignment: .bottom, bottomPadding: 140) {
            VStack(spacing: 12) {
                message
                HStack(spacing: 12) {
                    ForEach(libraryCoachReactionIcons.indices, id: \.self) { index in
                        Image(libraryCoachReactionIcons[index])
                            .resizable()
                            .frame(width: 32, height: 32)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.white))
                            .scaleEffect(iconScales[index])
                    }
                }
            }
        }
        .task {
            for index in iconScales.indices {
                if index > 0 {
                    try? await coachSleep(milliseconds: 70)
                    guard !Task.isCancelled else { return }
                }
                withAnimation(.coachPopIn) { iconScales[index] = 1 }
            }
        }
    }
}

/// 2·3단계: 실제 버튼 위치에 하이라이트를 두고, 뒤에서 펄스가 퍼지게 한다.
/// 문구는 하이라이트 아래에 화면 오른쪽 16 안쪽으로 정렬한다.
private struct LibraryCoachHighlightStep<Highlight: View, Message: View>: View {
    let targetFrame: CGRect?
    let size: CGFloat
    let pulseColor: Color
    let pulseOpacity: Double
    let highlight: Highlight
    let message: Message

    @State private var isPulsing = false

    var body: some View {
        GeometryReader { proxy in
            if let targetFrame {
                let origin = proxy.frame(in: .named(CoachMarkCoordinateSpace.libraryCardDetail)).origin
                let screenWidth = UIScreen.main.bounds.width

                ZStack {
                    Circle()
                        .fill(pulseColor)
                        .scaleEffect(isPulsing ? 2 : 1)
                        .opacity(isPulsing ? 0 : pulseOpacity)
                    highlight
                }
                .frame(width: size, height: size)
                .offset(x: targetFrame.minX - origin.x, y: targetFrame.minY - origin.y)

                message
                    .frame(width: screenWidth - 16, alignment: .trailing)
                    .offset(x: -origin.x, y: targetFrame.minY + size + 8 - origin.y)
            }
        }
        .onAppear {
            withAnimation(.coachFastOutSlowIn(duration: 0.9).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

/// 4단계: 스와이프. 화살표는 고정하고 손이 왼쪽으로 밀었다 돌아오기를 반복한다.
private struct LibraryCoachSwipeStep<Message: View>: View {
    let message: Message

    @State private var handOffsetX: CGFloat = 0

    var body: some View {
        CoachScreenAligned(bottomPadding: 80) {
            VStack(spacing: 20) {
                ZStack {
                    Image("ic_swipe_gesture")
                        .resizable()
                    Image("ic_touch_hand")
                        .resizable()
                        .offset(x: handOffsetX)
                }
                .frame(width: 72, height: 72)
                message
            }
        }
        .task { try? await animate() }
    }

    private func animate() async throws {
        try await coachSleep(milliseconds: 400)
        while true {
            withAnimation(.coachFastOutSlowIn(duration: 0.55)) { handOffsetX = -18 }
            try await coachSleep(milliseconds: 550 + 120)
            withAnimation(.coachFastOutSlowIn(duration: 0.3)) { handOffsetX = 0 }
            try await coachSleep(milliseconds: 300 + 700)
        }
    }
}

// MARK: - 트래커 댓글 코치마크 단계

/// 1단계: 탭하여 답장 / 꾹 눌러 삭제.
/// 두 아이콘이 차례로 팝인한 뒤, 2.6초 주기로 탭·꾹 누르기 애니메이션을 동시에 반복한다.
private struct TrackerCoachTapLongPressStep<TapMessage: View, LongPressMessage: View>: View {
    let tapMessage: TapMessage
    let longPressMessage: LongPressMessage

    @State private var iconScales: [CGFloat] = [0, 0]
    @State private var tapHandOffsetY: CGFloat = 0
    @State private var tapRingScale: CGFloat = 1
    @State private var tapRingOpacity: Double = 1
    @State private var longPressHandOffsetY: CGFloat = 0
    @State private var longPressRingScale: CGFloat = 1
    @State private var longPressRingOpacity: Double = 1

    var body: some View {
        CoachScreenAligned(bottomPadding: 160) {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    touchIcon(
                        ring: "ic_touch_tap_ring",
                        ringScale: tapRingScale,
                        ringOpacity: tapRingOpacity,
                        handOffsetY: tapHandOffsetY
                    )
                    .scaleEffect(iconScales[0])
                    tapMessage
                }
                VStack(spacing: 8) {
                    touchIcon(
                        ring: "ic_touch_longpress_rings",
                        ringScale: longPressRingScale,
                        ringOpacity: longPressRingOpacity,
                        handOffsetY: longPressHandOffsetY
                    )
                    .scaleEffect(iconScales[1])
                    longPressMessage
                }
            }
        }
        .task { try? await animate() }
    }

    private func touchIcon(
        ring: String,
        ringScale: CGFloat,
        ringOpacity: Double,
        handOffsetY: CGFloat
    ) -> some View {
        ZStack {
            Image(ring)
                .resizable()
                .scaleEffect(ringScale)
                .opacity(ringOpacity)
            Image("ic_touch_hand")
                .resizable()
                .offset(y: handOffsetY)
        }
        .frame(width: 72, height: 72)
    }

    private func animate() async throws {
        withAnimation(.coachPopIn) { iconScales[0] = 1 }
        try await coachSleep(milliseconds: 150)
        withAnimation(.coachPopIn) { iconScales[1] = 1 }
        try await coachSleep(milliseconds: 750)

        while true {
            // 탭: 손이 올라가며 링이 퍼졌다가(150ms), 80ms 뒤 함께 돌아온다(200ms).
            withAnimation(.coachFastOutSlowIn(duration: 0.15)) {
                tapHandOffsetY = -6
                tapRingScale = 1.25
                tapRingOpacity = 0.35
            }
            // 꾹 누르기: 500ms 동안 누르고 1100ms 유지한 뒤 400ms 동안 돌아온다.
            withAnimation(.coachFastOutSlowIn(duration: 0.5)) {
                longPressHandOffsetY = -6
                longPressRingScale = 1.3
                longPressRingOpacity = 0.3
            }
            try await coachSleep(milliseconds: 230)
            withAnimation(.coachFastOutSlowIn(duration: 0.2)) {
                tapHandOffsetY = 0
                tapRingScale = 1
                tapRingOpacity = 1
            }
            try await coachSleep(milliseconds: 1370)
            withAnimation(.coachFastOutSlowIn(duration: 0.4)) {
                longPressHandOffsetY = 0
                longPressRingScale = 1
                longPressRingOpacity = 1
            }
            // 꾹 누르기 한 사이클(2000ms) + 여유(600ms) = 2600ms 주기
            try await coachSleep(milliseconds: 1000)
        }
    }
}

/// 2단계: 위/아래 버튼 안내. 두 버튼이 차례로 팝인한다.
private struct TrackerCoachScrollButtonStep<UpMessage: View, DownMessage: View>: View {
    let upMessage: UpMessage
    let downMessage: DownMessage

    @State private var buttonScales: [CGFloat] = [0, 0]

    var body: some View {
        CoachScreenAligned(bottomPadding: 160) {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    // ic_chevron은 왼쪽을 가리키므로 90° 회전하면 위쪽이 된다.
                    scrollButton(rotation: 90)
                        .scaleEffect(buttonScales[0])
                    upMessage
                }
                VStack(spacing: 8) {
                    scrollButton(rotation: -90)
                        .scaleEffect(buttonScales[1])
                    downMessage
                }
            }
        }
        .task {
            withAnimation(.coachPopIn) { buttonScales[0] = 1 }
            try? await coachSleep(milliseconds: 150)
            guard !Task.isCancelled else { return }
            withAnimation(.coachPopIn) { buttonScales[1] = 1 }
        }
    }

    private func scrollButton(rotation: Double) -> some View {
        Image("ic_chevron")
            .renderingMode(.template)
            .resizable()
            .foregroundColor(Color("grey900"))
            .frame(width: 32, height: 32)
            .rotationEffect(.degrees(rotation))
            .frame(width: 44, height: 44)
            .background(Circle().fill(Color.white))
            .overlay(Circle().stroke(Color("grey200"), lineWidth: 1))
    }
}

/// 3단계: 위로 당기면 최신 댓글.
/// 손이 내려가는 동안 예시 댓글 카드가 위에서 내려오고, 함께 원위치로 돌아가기를 반복한다.
private struct TrackerCoachPullUpStep<Message: View>: View {
    let message: Message

    @State private var handOffsetY: CGFloat = 0
    @State private var cardOffsetY: CGFloat = -600

    var body: some View {
        ZStack {
            // 카드는 아이콘·문구 뒤에 그린다.
            CoachScreenLayout { screen, safeTop, origin in
                TrackerCoachExampleCommentCard()
                    .padding(.horizontal, 16)
                    .frame(width: screen.width)
                    .offset(x: -origin.x, y: safeTop + 68 - origin.y + cardOffsetY)
            }

            CoachScreenAligned(bottomPadding: 140) {
                VStack(spacing: 8) {
                    ZStack {
                        Image("ic_touch_pullup_arrow")
                            .resizable()
                        Image("ic_touch_hand")
                            .resizable()
                            .offset(y: handOffsetY)
                    }
                    .frame(width: 72, height: 72)
                    message
                }
            }
        }
        .task { try? await animate() }
    }

    private func animate() async throws {
        try await coachSleep(milliseconds: 400)
        while true {
            withAnimation(.coachFastOutSlowIn(duration: 0.9)) { cardOffsetY = -230 }
            withAnimation(.coachFastOutSlowIn(duration: 0.7)) { handOffsetY = 18 }
            try await coachSleep(milliseconds: 700 + 900)
            withAnimation(.coachFastOutSlowIn(duration: 0.5)) { cardOffsetY = -600 }
            withAnimation(.coachFastOutSlowIn(duration: 0.4)) { handOffsetY = 0 }
            try await coachSleep(milliseconds: 400 + 600)
        }
    }
}

private struct TrackerCoachExampleComment {
    let nickname: String
    let isHost: Bool
    let time: String
    let text: String
    let profileImage: String
}

private let trackerCoachExampleComments: [TrackerCoachExampleComment] = [
    TrackerCoachExampleComment(nickname: "sayo", isHost: false, time: "55분 전", text: "질문이 있습니다!", profileImage: "img_coach_profile_kanghunshim"),
    TrackerCoachExampleComment(nickname: "sayo", isHost: false, time: "55분 전", text: "저는 이번 교환독서에서\n'스릴러' 장르를 읽고 싶어요. 참고 부탁드려요!", profileImage: "img_coach_profile_sayo"),
    TrackerCoachExampleComment(nickname: "sayo", isHost: false, time: "55분 전", text: "이번 교환독서는\n포스트잇을 적극적으로 활용해주세요", profileImage: "img_coach_profile_sayo"),
    TrackerCoachExampleComment(nickname: "Kanghunshim", isHost: false, time: "55분 전", text: "만나서 반갑습니다!", profileImage: "img_coach_profile_kanghunshim"),
    TrackerCoachExampleComment(nickname: "noshel", isHost: true, time: "방금", text: "우리 즐거운 교환독서해요!", profileImage: "img_coach_profile_noshel"),
]

private struct TrackerCoachExampleCommentCard: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(trackerCoachExampleComments.indices, id: \.self) { index in
                commentRow(trackerCoachExampleComments[index])
                if index < trackerCoachExampleComments.count - 1 {
                    Rectangle()
                        .fill(Color("grey100"))
                        .frame(height: 1)
                        .padding(.vertical, 12)
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func commentRow(_ comment: TrackerCoachExampleComment) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(comment.profileImage)
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(ProfileSquircle())
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(comment.nickname)
                        .pretendardText(size: 14, weight: .regular)
                        .foregroundColor(Color(comment.isHost ? "main200" : "sub200"))
                    Text(comment.time)
                        .pretendardText(size: 12, weight: .regular)
                        .foregroundColor(Color("grey500"))
                }
                Text(comment.text)
                    .pretendardText(size: 15, weight: .regular)
                    .foregroundColor(Color("grey700"))
            }
            Spacer(minLength: 0)
        }
        .padding(4)
    }
}

extension View {
    func coachMarkTargetFrame(
        _ target: CoachMarkTarget,
        in coordinateSpace: String
    ) -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: CoachMarkFramePreferenceKey.self,
                    value: [target: proxy.frame(in: .named(coordinateSpace))]
                )
            }
        }
    }
}
