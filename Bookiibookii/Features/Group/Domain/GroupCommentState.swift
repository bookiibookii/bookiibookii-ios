import Foundation

// 그룹 상세 댓글 바텀시트 UI 상태 — 안드 GroupCommentUiState.kt 대응.
struct GroupCommentState {
    // GET 응답
    var comments: [CommentItem] = []
    // 헤더 "댓글 N" 표시값. sumOf(1 + children) 계산
    var totalCount: Int = 0

    var loading: Bool = false
    var error: String? = nil

    // 입력 필드 상태
    var draft: String = ""
    // 비밀 댓글 토글
    var draftSecret: Bool = false
    // nil이면 일반 댓글 모드, 값 있으면 그 댓글에 대한 답글 모드
    var replyTargetId: Int? = nil
    // 답글 멘션에 표시할 닉네임
    var mentionNickname: String? = nil
    // startReply 호출마다 증가하는 토큰. 같은 댓글 재클릭에도 focus/키보드 재요청 트리거
    var replyRequestId: Int = 0

    // POST 진행 중
    var submitting: Bool = false
    // 삭제 진행 중인 댓글 id들
    var deletingIds: Set<Int> = []

    var isReplyMode: Bool { replyTargetId != nil }
}
