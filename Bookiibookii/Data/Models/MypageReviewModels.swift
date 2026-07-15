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

    private enum CodingKeys: String, CodingKey {
        case reviewId, bookId, bookTitle, author, rating, content, exchangeType, exchangeTypeLabel, reviewedAt
    }

    // 서버가 bookTitle/author/content/reviewedAt을 null로 내려도 디코딩이 실패하지 않도록 빈 문자열로 대체.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        reviewId = try c.decode(Int.self, forKey: .reviewId)
        bookId = try c.decode(Int.self, forKey: .bookId)
        bookTitle = try c.decodeIfPresent(String.self, forKey: .bookTitle) ?? ""
        author = try c.decodeIfPresent(String.self, forKey: .author) ?? ""
        rating = try c.decode(Double.self, forKey: .rating)
        content = try c.decodeIfPresent(String.self, forKey: .content) ?? ""
        exchangeType = try c.decodeIfPresent(String.self, forKey: .exchangeType)
        exchangeTypeLabel = try c.decodeIfPresent(String.self, forKey: .exchangeTypeLabel)
        reviewedAt = try c.decodeIfPresent(String.self, forKey: .reviewedAt) ?? ""
    }
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

    private enum CodingKeys: String, CodingKey {
        case reviewId, reviewerId, reviewerNickname, reviewerProfileImageUrl, partnerReviewType, partnerReviewLabel, comment, reviewedAt
    }

    // 서버가 reviewerNickname/reviewedAt을 null로 내려도 디코딩이 실패하지 않도록 빈 문자열로 대체.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        reviewId = try c.decode(Int.self, forKey: .reviewId)
        reviewerId = try c.decode(Int.self, forKey: .reviewerId)
        reviewerNickname = try c.decodeIfPresent(String.self, forKey: .reviewerNickname) ?? ""
        reviewerProfileImageUrl = try c.decodeIfPresent(String.self, forKey: .reviewerProfileImageUrl)
        partnerReviewType = try c.decodeIfPresent(String.self, forKey: .partnerReviewType)
        partnerReviewLabel = try c.decodeIfPresent(String.self, forKey: .partnerReviewLabel)
        comment = try c.decodeIfPresent(String.self, forKey: .comment)
        reviewedAt = try c.decodeIfPresent(String.self, forKey: .reviewedAt) ?? ""
    }
}

struct ReviewPageInfo: Decodable, Equatable {
    let page: Int
    let size: Int
    let totalPages: Int
    let hasNext: Bool
}
