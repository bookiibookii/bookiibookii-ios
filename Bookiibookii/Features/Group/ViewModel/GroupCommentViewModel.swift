import Foundation
import Combine

// 그룹 상세 댓글 VM — 안드 GroupCommentViewModel.kt 대응.
// 단일 state struct를 @Published로 노출(안드 StateFlow<UiState> 대응). 에러는 toast로 표출(안드 eventFlow.ShowError).
@MainActor
final class GroupCommentViewModel: ObservableObject {
    @Published private(set) var state = GroupCommentState()
    // 안드 eventFlow.ShowError → iOS .toast()
    @Published var toast: ToastMessage?

    private let groupId: Int
    private let service: GroupService

    private static let maxContentLen = 250

    // 안드는 currentUserId를 Route에서 내려주지만 iOS는 VM에서 TokenManager 직접 조회.
    var currentUserId: Int? { TokenManager.shared.userId }

    init(groupId: Int, service: GroupService) {
        self.groupId = groupId
        self.service = service
    }

    // MARK: - 데이터 로드

    func load() async {
        state.loading = true
        state.error = nil
        do {
            let list = try await service.fetchComments(groupId: groupId)
            state.comments = list
            state.totalCount = Self.countAll(list)
            state.loading = false
            state.error = nil
        } catch {
            state.error = "댓글을 불러오지 못했어요"
            state.loading = false
        }
    }

    func retry() {
        Task { await load() }
    }

    // MARK: - 입력 필드

    // 250자 cap + 답글 모드 멘션 prefix atomicity
    // "한 글자라도 지우면 멘션 전체 삭제 + 답글 해제"
    func onDraftChange(_ text: String) {
        if let nickname = state.mentionNickname {
            let prefix = Self.mentionPrefix(nickname)
            if !text.hasPrefix(prefix) {
                state.draft = ""
                state.replyTargetId = nil
                state.mentionNickname = nil
                state.draftSecret = false
                return
            }
        }
        state.draft = text.count > Self.maxContentLen ? String(text.prefix(Self.maxContentLen)) : text
    }

    func toggleSecret() {
        state.draftSecret.toggle()
    }

    // 답글 모드 진입. replyRequestId를 증가시켜 같은 댓글 재클릭에도 focus/키보드 재요청.
    func startReply(parentId: Int, nickname: String) {
        state.replyTargetId = parentId
        state.mentionNickname = nickname
        state.draft = Self.mentionPrefix(nickname)
        state.replyRequestId += 1
    }

    // MARK: - 댓글 작성

    func submit() {
        let content: String
        if let nickname = state.mentionNickname {
            content = state.draft
                .replacingOccurrences(of: Self.mentionPrefix(nickname), with: "", options: [.anchored])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            content = state.draft.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if content.isEmpty || state.submitting { return }

        let secret = state.draftSecret
        let parentId = state.replyTargetId

        state.submitting = true
        Task {
            do {
                let created = try await service.postComment(
                    groupId: groupId,
                    content: content,
                    parentId: parentId,
                    secret: secret
                )
                let newItem = Self.toCommentItem(created, secret: secret)
                addLocally(newItem)
            } catch {
                toast = .failure("댓글 작성에 실패했어요")
                state.submitting = false
            }
        }
    }

    // 응답 댓글을 트리에 낙관적 추가 + 입력 상태 리셋
    private func addLocally(_ item: CommentItem) {
        if item.parentId == nil {
            // 일반 댓글 — 시간순이라 맨 뒤 append
            state.comments.append(item)
        } else {
            // 대댓글 — 부모 찾아 children 끝에 append (struct라 새 인스턴스로 교체)
            state.comments = state.comments.map { parent in
                guard parent.id == item.parentId else { return parent }
                let newChildren = (parent.children ?? []) + [item]
                return CommentItem(
                    id: parent.id,
                    deleted: parent.deleted,
                    secret: parent.secret,
                    content: parent.content,
                    parentId: parent.parentId,
                    writer: parent.writer,
                    createdAt: parent.createdAt,
                    children: newChildren
                )
            }
        }
        state.totalCount = Self.countAll(state.comments)
        state.draft = ""
        state.draftSecret = false
        state.replyTargetId = nil
        state.mentionNickname = nil
        state.submitting = false
    }

    // MARK: - 댓글 삭제 (성공 시 reload)

    func delete(commentId: Int) {
        if state.deletingIds.contains(commentId) { return }
        state.deletingIds.insert(commentId)
        Task {
            do {
                try await service.deleteComment(groupId: groupId, commentId: commentId)
                await load()
            } catch {
                toast = .failure("댓글 삭제에 실패했어요")
            }
            state.deletingIds.remove(commentId)
        }
    }

    // MARK: - Helpers

    // "@{닉네임} " (뒤 공백 1)
    private static func mentionPrefix(_ nickname: String) -> String { "@\(nickname) " }

    // 부모 + 답글 합산
    private static func countAll(_ comments: [CommentItem]) -> Int {
        comments.reduce(0) { $0 + 1 + ($1.children?.count ?? 0) }
    }

    // POST 응답 → 화면용 CommentItem
    private static func toCommentItem(_ res: CommentCreateResponse, secret: Bool) -> CommentItem {
        CommentItem(
            id: res.commentId,
            deleted: false,
            secret: secret,
            content: res.content,
            parentId: res.parentId,
            writer: res.writer,
            createdAt: res.createdAt,
            children: nil
        )
    }
}
