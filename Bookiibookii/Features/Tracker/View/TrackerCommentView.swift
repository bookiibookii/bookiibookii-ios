import SwiftUI
import UIKit

// 트래커 1:1 댓글 화면(풀스크린).
// 리스트는 그룹 댓글과 동일하게 트리(children) + 비밀(secret) + 역할별 닉네임 색으로 렌더한다(CommentRow 재사용).
// 입력은 축소 — 비밀토글/멘션 없이 최상위·공개 댓글만 작성. 본인 댓글 롱프레스 삭제.
// 리스트를 아래에서 위로 당기면 새로고침된다.
struct TrackerCommentView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: TrackerCommentViewModel

    // 헤더 타이틀(트래커명)
    private let title: String

    // 롱프레스로 열린 삭제 팝오버 대상 (그룹 시트와 동일 패턴)
    @State private var openDeleteId: Int?

    // 아래→위 당김 새로고침 상태
    @State private var pull: CGFloat = 0        // 현재 하단 오버스크롤량
    @State private var peakPull: CGFloat = 0    // 드래그 중 최대 오버스크롤량
    @State private var dragging = false
    @State private var spinAngle: Double = 0    // 새로고침 중 무한 회전 각도

    // 스크롤 칩 명령
    @State private var scrollCommand: ScrollCommand?

    // 당김 임계치 / 새로고침 중 유지할 gap / 당기는 동안 gap 최대치 (안드 상수 이식)
    private let refreshThreshold: CGFloat = 72
    private let refreshingGap: CGFloat = 64
    private let maxPull: CGFloat = 96

    private enum ScrollCommand { case top, bottom }

    init(groupId: Int, title: String, service: GroupService) {
        self.title = title
        _viewModel = StateObject(wrappedValue: TrackerCommentViewModel(groupId: groupId, service: service))
    }

    var body: some View {
        VStack(spacing: 0) {
            CustomNavigationBar(title: title, onBack: { container.navigationRouter.pop() })
            Rectangle().fill(Color("grey200")).frame(height: 1)

            if viewModel.state.comments.isEmpty {
                EmptyCommentCard()
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                ZStack(alignment: .bottomTrailing) {
                    commentList
                    scrollChips
                }
                .padding(16)
            }

            inputBar
        }
        .background(Color("uiBg"))
        .toast($viewModel.toast)
        .task { await viewModel.load() }
    }

    // MARK: - 리스트 카드 + 당김 새로고침

    private var commentList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.state.comments.enumerated()), id: \.element.id) { index, comment in
                        CommentRow(
                            comment: comment,
                            currentUserId: viewModel.currentUserId,
                            onStartReply: { _, _ in },          // 1:1이라 답글 모드 없음
                            onDelete: { viewModel.delete(commentId: $0) },
                            onProfileTap: { _ in },             // 프로필 이동 없음
                            openDeleteId: openDeleteId,
                            onLongPress: { openDeleteId = $0 },
                            onDismissDelete: { openDeleteId = nil }
                        )
                        .id(comment.id)

                        // 댓글마다 하단 divider — 마지막 댓글은 제외
                        if index < viewModel.state.comments.count - 1 {
                            Rectangle().fill(Color("grey100"))
                                .frame(height: 1)
                                .padding(.vertical, 12)
                        }
                    }
                    // 새로고침 중엔 하단에 gap을 유지해 스피너가 앉을 공간을 확보
                    Color.clear.frame(height: viewModel.state.isRefreshing ? refreshingGap : 0)
                }
                .padding(12)
            }
            // 하단 오버스크롤량 추적.
            // 콘텐츠가 화면보다 짧으면 contentSize < containerSize라 가만히 있어도 값이 양수가 되므로,
            // 스크롤 가능 높이를 컨테이너 높이로 하한 처리한다.
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                let scrollableHeight = max(geo.contentSize.height, geo.containerSize.height)
                return max(0, geo.contentOffset.y + geo.containerSize.height - scrollableHeight)
            } action: { _, value in
                pull = value
                if dragging { peakPull = max(peakPull, value) }
            }
            // 드래그 시작/종료 감지 → 손 뗀 순간 임계치를 넘겼으면 새로고침
            .onScrollPhaseChange { _, newPhase in
                switch newPhase {
                case .tracking, .interacting:
                    dragging = true
                default:
                    if dragging {
                        dragging = false
                        if peakPull >= refreshThreshold { viewModel.refresh() }
                        peakPull = 0
                    }
                }
            }
            // 새로고침 완료(true→false) 시 맨 아래로 스크롤
            .onChange(of: viewModel.state.isRefreshing) { _, refreshing in
                updateSpin(refreshing)
                if !refreshing, let last = viewModel.state.comments.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            // 스크롤 칩 명령 처리 (proxy 접근용)
            .background(
                Color.clear.onChange(of: scrollCommand) { _, cmd in
                    guard let cmd else { return }
                    switch cmd {
                    case .top:
                        if let first = viewModel.state.comments.first {
                            withAnimation { proxy.scrollTo(first.id, anchor: .top) }
                        }
                    case .bottom:
                        if let last = viewModel.state.comments.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                    scrollCommand = nil
                }
            )
        }
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        // 벌어진 하단 공간 안의 새로고침 인디케이터
        .overlay(alignment: .bottom) { reloadIndicator }
    }

    // MARK: - 새로고침 인디케이터
    // 당기는 동안 진행률만큼 회전, 새로고침 중엔 무한 회전

    @ViewBuilder
    private var reloadIndicator: some View {
        let gap = viewModel.state.isRefreshing ? refreshingGap : min(pull, maxPull)
        if gap > 0 {
            let rotation = viewModel.state.isRefreshing
                ? spinAngle
                : Double(min(pull / refreshThreshold, 1)) * 360
            Image("ic_reload")
                .renderingMode(.template)
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundColor(Color("grey400"))
                .rotationEffect(.degrees(rotation))
                .frame(height: gap)
        }
    }

    private func updateSpin(_ refreshing: Bool) {
        if refreshing {
            spinAngle = 0
            withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) { spinAngle = 360 }
        } else {
            withAnimation(.linear(duration: 0.2)) { spinAngle = 0 }
        }
    }

    // MARK: - 우하단 스크롤 칩

    private var scrollChips: some View {
        VStack(spacing: 8) {
            ScrollChip(rotation: 90) { scrollCommand = .top }
            ScrollChip(rotation: -90) { scrollCommand = .bottom }
        }
        .padding(.trailing, 16)
        .padding(.bottom, 16)
    }

    // MARK: - 입력바 — 잠금칩/멘션 없음

    private var inputBar: some View {
        let trimmed = viewModel.state.draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let canSubmit = !trimmed.isEmpty && !viewModel.state.submitting
        return HStack(spacing: 8) {
            ZStack(alignment: .leading) {
                if viewModel.state.draft.isEmpty {
                    Text("메시지를 남겨주세요")
                        .pretendardText(size: 15)
                        .foregroundColor(Color("grey500"))
                }
                TextField("", text: draftBinding, axis: .vertical)
                    .lineLimit(1...4)
                    .pretendardText(size: 15)
                    .foregroundColor(Color("grey900"))
                    .tint(Color("main200"))
            }
            .padding(.leading, 12)

            CommentUploadChip(enabled: canSubmit, onClick: { submit(canSubmit) })
        }
        .padding(4)
        .frame(minHeight: 48)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("white"))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("grey300"), lineWidth: 1))
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(Color("white"))
    }

    private var draftBinding: Binding<String> {
        Binding(get: { viewModel.state.draft }, set: { viewModel.onDraftChange($0) })
    }

    // 제출 시 키보드 즉시 내림
    private func submit(_ canSubmit: Bool) {
        guard canSubmit else { return }
        viewModel.submit()
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// 빈 상태 카드
private struct EmptyCommentCard: View {
    var body: some View {
        Text("댓글이 없어요.")
            .pretendardText(size: 16)
            .foregroundColor(Color("grey600"))
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color("white")))
    }
}

// 우측 플로팅 스크롤 칩 — ic_chevron(좌향)을 회전시켜 위/아래 표시
private struct ScrollChip: View {
    let rotation: Double
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            Image("ic_chevron")
                .renderingMode(.template)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(Color("grey900"))
                .rotationEffect(.degrees(rotation))
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(Color("white"))
                        .overlay(Circle().stroke(Color("grey200"), lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
    }
}
