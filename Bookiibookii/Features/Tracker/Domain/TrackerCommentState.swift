import Foundation

// 트래커 1:1 댓글 화면 UI 상태.
// 그룹 댓글과 API/스레드를 공유하므로 조회는 트리(children)·비밀(secret) 그대로 렌더하되,
// 새로 작성하는 건 최상위·공개 댓글만이라 멘션/답글/비밀 관련 상태는 두지 않는다.
struct TrackerCommentState {
    // GET 응답 — 그룹과 동일한 트리 구조(children 포함)
    var comments: [CommentItem] = []

    var loading: Bool = false
    // 아래→위 당김 새로고침 진행 중
    var isRefreshing: Bool = false
    var error: String? = nil

    // 입력 필드
    var draft: String = ""
    // POST 진행 중
    var submitting: Bool = false
    // 삭제 진행 중인 댓글 id들
    var deletingIds: Set<Int> = []
}
