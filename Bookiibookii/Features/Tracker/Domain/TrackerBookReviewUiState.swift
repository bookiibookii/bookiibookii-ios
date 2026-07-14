import Foundation

struct TrackerBookReviewUiState {
    var bookTitle: String = ""
    var bookImageUrl: String? = nil
    // 수정 모드 프리필용 — 기존 후기 별점(0~5)·내용. 작성 모드면 기본값 유지.
    var initialStar: Double = 0
    var initialComment: String = ""
    var loading: Bool = false
    // 후기 제출 진행 중 — 더블탭으로 중복 제출/중복 네비 방지용
    var submitting: Bool = false
    var error: String? = nil
}
