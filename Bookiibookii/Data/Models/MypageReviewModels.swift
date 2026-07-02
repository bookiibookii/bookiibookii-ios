import Foundation

enum MyReviewTab: String, Hashable {
    case written
    case received

    var title: String {
        switch self {
        case .written: return "작성한 후기"
        case .received: return "받은 후기"
        }
    }
}

// MARK: - GET /api/mypage/reviews/written

struct WrittenReviewsResult: Decodable {
    let totalCount: Int
    let content: [WrittenReviewItem]
    let pageInfo: ReviewPageInfo
}

struct WrittenReviewItem: Decodable, Identifiable, Equatable {
    let reviewId: Int
    let bookId: Int
    let bookTitle: String
    let author: String
    let rating: Double
    let content: String
    let exchangeType: String?
    let exchangeTypeLabel: String?
    let reviewedAt: String

    var id: Int { reviewId }
}

// MARK: - GET /api/mypage/reviews/received

struct ReceivedReviewsResult: Decodable {
    let positiveCount: Int
    let content: [ReceivedReviewItem]
    let pageInfo: ReviewPageInfo
}

struct ReceivedReviewItem: Decodable, Identifiable, Equatable {
    let reviewId: Int
    let reviewerId: Int
    let reviewerNickname: String
    let reviewerProfileImageUrl: String?
    let partnerReviewType: String?
    let partnerReviewLabel: String?
    let comment: String?
    let reviewedAt: String

    var id: Int { reviewId }

    var isBoomUp: Bool {
        partnerReviewType?.uppercased() == "BOOM_UP"
    }
}

struct ReviewPageInfo: Decodable, Equatable {
    let page: Int
    let size: Int
    let totalPages: Int
    let hasNext: Bool
}
