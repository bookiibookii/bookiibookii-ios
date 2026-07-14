import Foundation

struct TrackerPartnerReviewUiState {
    var groupName: String = ""
    var myNickname: String = ""
    var myBookTitle: String = ""
    var myBookCoverUrl: String? = nil
    var myProfileImageUrl: String? = nil
    var partnerNickname: String = ""
    var partnerBookTitle: String = ""
    var partnerBookCoverUrl: String? = nil
    var partnerProfileImageUrl: String? = nil
    var loading: Bool = false
    // 후기 제출 진행 중 — 더블탭으로 중복 제출/중복 네비 방지용
    var submitting: Bool = false
    var error: String? = nil
}
