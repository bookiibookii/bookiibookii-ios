import SwiftUI

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
    let onCompleted: () -> Void

    @State private var page = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.76)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 28)

                coachContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                pageIndicator
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
            VStack(spacing: 12) {
                coachMessage(
                    "가장 가까운 반응으로\n독서카드에 ",
                    emphasis: "공감",
                    suffix: "해보세요."
                )
                HStack(spacing: 12) {
                    coachReactionIcon("ic_heart", selected: true)
                    coachReactionIcon("ic_star")
                    coachReactionIcon("ic_shine")
                    coachReactionIcon("ic_book")
                    coachReactionIcon("ic_hand_thumbs_up")
                    coachReactionIcon("ic_smile")
                }
            }
            .padding(.top, 510)

        case 1:
            VStack(alignment: .trailing, spacing: 8) {
                Image("ic_bookmark_fill")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color("main200"))
                    .frame(width: 24, height: 24)
                    .padding(10)
                    .background(Color.white)
                    .clipShape(Circle())

                coachMessage(
                    "모아서 보고 싶은\n독서카드를 ",
                    emphasis: "북마크",
                    suffix: "해요.",
                    trailing: true
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, 100)
            .padding(.trailing, 20)

        case 2:
            VStack(alignment: .trailing, spacing: 12) {
                Image("ic_share")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .padding(4)
                    .background(Color.white)
                    .clipShape(Circle())

                coachMessage(
                    "마음에 든 독서카드는\n",
                    emphasis: "공유",
                    suffix: "하거나 ",
                    trailingEmphasis: "저장",
                    trailingSuffix: "할 수 있어요.",
                    trailing: true
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, 12)
            .padding(.trailing, 16)

        default:
            VStack(spacing: 8) {
                Image(systemName: "hand.point.up.left.fill")
                    .font(.system(size: 52, weight: .regular))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(-20))

                coachMessage(
                    "옆으로 스와이프해\n다른 독서카드를 ",
                    emphasis: "넘겨 볼",
                    suffix: " 수 있어요."
                )
            }
        }
    }

    @ViewBuilder
    private var trackerCommentContent: some View {
        switch page {
        case 0:
            VStack(spacing: 24) {
                pointerMessage(
                    "댓글을 탭하여 ",
                    emphasis: "답장",
                    suffix: "하고,"
                )
                pointerMessage(
                    "꾹 눌러 ",
                    emphasis: "삭제",
                    suffix: "하세요."
                )
            }

        case 1:
            VStack(spacing: 24) {
                arrowMessage(
                    symbol: "chevron.up",
                    prefix: "위 버튼은 ",
                    emphasis: "오래된 댓글",
                    suffix: "로,"
                )
                arrowMessage(
                    symbol: "chevron.down",
                    prefix: "아래 버튼은 ",
                    emphasis: "최신 댓글",
                    suffix: "로 이동해요."
                )
            }

        default:
            VStack(spacing: 8) {
                Image(systemName: "hand.point.up.left.fill")
                    .font(.system(size: 52, weight: .regular))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(180))

                coachMessage(
                    "위로 당기면\n",
                    emphasis: "최신 댓글",
                    suffix: "을 불러와요."
                )
            }
        }
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

    private func coachReactionIcon(_ imageName: String, selected: Bool = false) -> some View {
        Image(imageName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundColor(selected ? .white : Color("main200"))
            .frame(width: 24, height: 24)
            .padding(10)
            .background(selected ? Color("main200") : Color.white)
            .clipShape(Circle())
    }

    private func pointerMessage(_ prefix: String, emphasis: String, suffix: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "hand.point.up.left.fill")
                .font(.system(size: 48, weight: .regular))
                .foregroundColor(.white)
            coachMessage(prefix, emphasis: emphasis, suffix: suffix)
        }
    }

    private func arrowMessage(
        symbol: String,
        prefix: String,
        emphasis: String,
        suffix: String
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(Color("grey700"))
                .frame(width: 52, height: 52)
                .background(Color.white)
                .clipShape(Circle())
            coachMessage(prefix, emphasis: emphasis, suffix: suffix)
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
