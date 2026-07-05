import SwiftUI
import UIKit
import Kingfisher

// 안드 GroupCommentBottomSheet.kt 대응 — 하위 컴포넌트(행/헤더/칩). 최상위 시트는 아래 Task 7에서 추가.

// 드래그 핸들 (44×4, grey200)
struct CommentDragHandle: View {
    var body: some View {
        HStack {
            Spacer()
            Capsule()
                .fill(Color("grey200"))
                .frame(width: 44, height: 4)
            Spacer()
        }
    }
}

// "댓글 N" 헤더 — N>0이면 main, else grey500
struct CommentSheetHeader: View {
    let count: Int
    var body: some View {
        HStack(spacing: 8) {
            Text("댓글")
                .pretendardText(size: 20, weight: .semibold)
                .foregroundColor(Color("grey900"))
            Text("\(count)")
                .pretendardText(size: 16)
                .foregroundColor(count > 0 ? Color("main200") : Color("grey500"))
            Spacer()
        }
        .padding(.bottom, 12)
    }
}

// 최상위 댓글 + 답글들 (2단 트리 고정)
struct CommentRow: View {
    let comment: CommentItem
    let currentUserId: Int?
    let onStartReply: (_ parentId: Int, _ nickname: String) -> Void
    let onDelete: (_ commentId: Int) -> Void
    let openDeleteId: Int?
    let onLongPress: (_ commentId: Int) -> Void
    let onDismissDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CommentItemRow(
                comment: comment,
                isMine: isMine(currentUserId, comment.writer.userId),
                profileSize: 36,
                indentStart: 0,
                isDeleteOpen: openDeleteId == comment.id,
                onTap: { onStartReply(comment.id, comment.writer.name) },
                onDelete: { onDelete(comment.id) },
                onLongPress: { onLongPress(comment.id) },
                onDismissDelete: onDismissDelete
            )
            ForEach(comment.children ?? []) { reply in
                CommentItemRow(
                    comment: reply,
                    isMine: isMine(currentUserId, reply.writer.userId),
                    profileSize: 28,
                    indentStart: 52,
                    isDeleteOpen: openDeleteId == reply.id,
                    // 답글 탭도 부모에 답글 (멘션은 탭한 대상 닉네임)
                    onTap: { onStartReply(comment.id, reply.writer.name) },
                    onDelete: { onDelete(reply.id) },
                    onLongPress: { onLongPress(reply.id) },
                    onDismissDelete: onDismissDelete
                )
            }
        }
    }

    private func isMine(_ currentUserId: Int?, _ writerId: Int) -> Bool {
        currentUserId != nil && writerId == currentUserId
    }
}

// 댓글 한 줄 — 프로필 + 메타/본문, 본인만 롱프레스 삭제 팝오버
struct CommentItemRow: View {
    let comment: CommentItem
    let isMine: Bool
    let profileSize: CGFloat
    let indentStart: CGFloat
    let isDeleteOpen: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let onLongPress: () -> Void
    let onDismissDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            KFImage(comment.writer.profileImage.flatMap(URL.init(string:)))
                .placeholder { Color("grey300") }
                .retry(maxCount: 2)
                .cancelOnDisappear(true)
                .resizable()
                .scaledToFill()
                .frame(width: profileSize, height: profileSize)
                .clipShape(Circle())
            CommentMetaAndBody(
                nickname: comment.writer.name,
                nicknameColor: comment.writer.role == "HOST" ? Color("main200") : Color("grey900"),
                createdAt: comment.createdAt,
                secret: comment.secret,
                content: comment.content
            )
            Spacer(minLength: 0)
        }
        .padding(4)
        .padding(.leading, indentStart)
        .contentShape(Rectangle())
        .onTapGesture {
            // 팝오버가 열려 있으면 어느 행을 탭하든 먼저 닫는다 (바깥 탭 dismiss)
            onDismissDelete()
            if !isDeleteOpen { onTap() }
        }
        .onLongPressGesture {
            if isMine { onLongPress() }
        }
        .overlay(alignment: .topTrailing) {
            if isDeleteOpen {
                DeletePopover(onDelete: {
                    onDismissDelete()
                    onDelete()
                })
                .offset(y: profileSize)
            }
        }
    }
}

// 닉네임 + 시간 + (secret) 잠금 + 본문
struct CommentMetaAndBody: View {
    let nickname: String
    let nicknameColor: Color
    let createdAt: String
    let secret: Bool
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(nickname)
                    .pretendardText(size: 14)
                    .foregroundColor(nicknameColor)
                HStack(spacing: 2) {
                    Text(TimeAgoFormatter.format(createdAt))
                        .pretendardText(size: 12)
                        .foregroundColor(Color("grey500"))
                    if secret {
                        Image("ic_lock")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundColor(Color("grey500"))
                    }
                }
            }
            Text(content)
                .pretendardText(size: 15)
                .foregroundColor(Color("grey700"))
        }
    }
}

// 입력 필드 좌측 잠금 칩 — secret 토글
struct CommentLockChip: View {
    let active: Bool
    let onClick: () -> Void
    var body: some View {
        Button(action: onClick) {
            Image("ic_lock")
                .renderingMode(.template)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(active ? Color("main200") : Color("grey500"))
                .frame(width: 40, height: 40)
                .background(RoundedRectangle(cornerRadius: 16).fill(active ? Color("main100") : Color("grey200")))
        }
        .buttonStyle(.plain)
    }
}

// 입력 필드 우측 업로드 칩 — 제출 가능 시 main
struct CommentUploadChip: View {
    let enabled: Bool
    let onClick: () -> Void
    var body: some View {
        Button(action: onClick) {
            Image("ic_up")
                .renderingMode(.template)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(Color("white"))
                .frame(width: 40, height: 40)
                .background(Circle().fill(enabled ? Color("main200") : Color("grey400")))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

// MARK: - 최상위 시트 (안드 GroupCommentBottomSheetContent 대응)

struct GroupCommentSheet: View {
    @ObservedObject var viewModel: GroupCommentViewModel
    let expanded: Bool
    let keyboardHeight: CGFloat
    let onExpand: () -> Void

    @State private var openDeleteId: Int? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 10) {
                VStack(spacing: 20) {
                    CommentDragHandle()
                    CommentSheetHeader(count: viewModel.state.totalCount)
                }
                if expanded {
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 10) {
                                ForEach(viewModel.state.comments) { comment in
                                    CommentRow(
                                        comment: comment,
                                        currentUserId: viewModel.currentUserId,
                                        onStartReply: viewModel.startReply,
                                        onDelete: viewModel.delete,
                                        openDeleteId: openDeleteId,
                                        onLongPress: { openDeleteId = $0 },
                                        onDismissDelete: { openDeleteId = nil }
                                    )
                                    .id(comment.id)
                                }
                            }
                            .padding(.bottom, 56 + keyboardHeight)
                        }
                        // 답글 진입 시 대상 부모 댓글로 스크롤 (안드 animateScrollToItem)
                        .onChange(of: viewModel.state.replyRequestId) { _, _ in
                            if let target = viewModel.state.replyTargetId {
                                withAnimation { proxy.scrollTo(target, anchor: .center) }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)

            // 입력 필드 오버레이 — 키보드 위
            CommentInputField(viewModel: viewModel, expanded: expanded, onInputClick: onExpand)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .background(Color("white"))
                .padding(.bottom, keyboardHeight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color("white")
                .clipShape(.rect(topLeadingRadius: 20, topTrailingRadius: 20))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: -2)
        )
    }
}

// 입력 필드 — 멘션 UITextView + 잠금/업로드 칩. peek 모드면 탭 시 expand만.
private struct CommentInputField: View {
    @ObservedObject var viewModel: GroupCommentViewModel
    let expanded: Bool
    let onInputClick: () -> Void

    @State private var contentHeight: CGFloat = 48

    private var effectiveContent: String {
        let draft = viewModel.state.draft
        if let nickname = viewModel.state.mentionNickname {
            return draft
                .replacingOccurrences(of: "@\(nickname) ", with: "", options: [.anchored])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        !effectiveContent.isEmpty && !viewModel.state.submitting
    }

    var body: some View {
        ZStack {
            HStack(spacing: 8) {
                CommentLockChip(active: viewModel.state.draftSecret, onClick: viewModel.toggleSecret)
                CommentInputTextView(
                    text: viewModel.state.draft,
                    mentionNickname: viewModel.state.mentionNickname,
                    focusTrigger: viewModel.state.replyRequestId,
                    onChange: viewModel.onDraftChange,
                    onSubmit: { if canSubmit { viewModel.submit(); dismissKeyboard() } },
                    contentHeight: $contentHeight
                )
                .frame(height: max(40, contentHeight))
                CommentUploadChip(enabled: canSubmit, onClick: { if canSubmit { viewModel.submit(); dismissKeyboard() } })
            }
            .padding(4)
            .frame(minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("white"))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("grey300"), lineWidth: 1))
            )

            // peek 상태에선 입력 영역 전체 탭 → expand만 트리거
            if !expanded {
                Color.black.opacity(0.001)
                    .contentShape(Rectangle())
                    .onTapGesture { onInputClick() }
            }
        }
    }

    // 제출 시 키보드 즉시 내림 (안드 submitAndHide의 keyboard.hide() 대응)
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
