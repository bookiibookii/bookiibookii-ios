import Foundation
import Combine

// 트래커 1:1 댓글 VM.
// 그룹 댓글과 동일한 groupId/API(GroupService)를 사용한다. 조회는 트리 그대로 보여주되,
// 작성은 공개 댓글만(parentId=nil, secret=false).
// 에러는 toast로 표출(그룹 VM과 동일 패턴).
@MainActor
final class TrackerCommentViewModel: ObservableObject {
    @Published private(set) var state = TrackerCommentState()
    @Published var toast: ToastMessage?

    private let groupId: Int
    private let service: GroupService

    private static let maxContentLen = 250

    // 본인 댓글 판별용 — 안드는 Route에서 내려주지만 iOS는 VM에서 TokenManager 직접 조회.
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

    // 아래→위 당김 새로고침 — 같은 조회 API 재호출. 진행 표시는 isRefreshing으로만.
    // 뷰 태스크 취소(-999)에 영향받지 않도록 VM 소유 Task로 실행.
    func refresh() {
        if state.isRefreshing { return }
        state.isRefreshing = true
        Task {
            do {
                let list = try await service.fetchComments(groupId: groupId)
                state.comments = list
                state.error = nil
            } catch {
                toast = .failure("댓글을 불러오지 못했어요")
            }
            state.isRefreshing = false
        }
    }

    // MARK: - 입력 필드 (250자, 멘션 없음)

    func onDraftChange(_ text: String) {
        state.draft = text.count > Self.maxContentLen ? String(text.prefix(Self.maxContentLen)) : text
    }

    // MARK: - 댓글 작성

    func submit() {
        let content = state.draft.trimmingCharacters(in: .whitespacesAndNewlines)
        if content.isEmpty || state.submitting { return }

        state.submitting = true
        Task {
            do {
                let created = try await service.postComment(
                    groupId: groupId,
                    content: content,
                    parentId: nil,
                    secret: false
                )
                addLocally(Self.toCommentItem(created))
            } catch {
                toast = .failure("댓글 작성에 실패했어요")
                state.submitting = false
            }
        }
    }

    // 작성한 최상위 댓글을 리스트 끝에 append + 입력 상태 리셋
    private func addLocally(_ item: CommentItem) {
        state.comments.append(item)
        state.draft = ""
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

    // POST 응답 → 화면용 CommentItem (공개 최상위 댓글)
    private static func toCommentItem(_ res: CommentCreateResponse) -> CommentItem {
        CommentItem(
            id: res.commentId,
            deleted: false,
            secret: false,
            content: res.content,
            parentId: res.parentId,
            writer: res.writer,
            createdAt: res.createdAt,
            children: nil
        )
    }
}
