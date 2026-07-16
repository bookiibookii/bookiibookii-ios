import Foundation

// MARK: - 닉네임 중복 검사 (안드로이드 NicknameValidationResponse 대응)

struct NicknameValidationResponse: Decodable {
    let isSuccess: Bool
    let code: String
    let message: String
    let result: NicknameValidationResult?
}

struct NicknameValidationResult: Decodable {
    let isAvailable: Bool
    let code: String  // "SUCCESS" | "DUPLICATE" | "BAD_WORD"
    let message: String
}

// MARK: - Presigned URL (안드로이드 PresignedUrlResponse 대응)

struct PresignedUrlResponse: Decodable {
    let isSuccess: Bool
    let code: String
    let message: String
    let result: PresignedUrlResult?
}

struct PresignedUrlResult: Decodable {
    let s3Key: String
    let presignedPutUrl: String
}

// MARK: - 온보딩 완료 (안드로이드 OnboardingRequest 대응)

struct OnboardingRequest: Encodable {
    let name: String          // 닉네임 (필수)
    let gender: String?       // "FEMALE" | "MALE" | "NONE" (필수)
    let birth: String?        // "yyyy-MM-dd" (필수)
    let tags: [String]        // 기록 방식: ["MEMO"], ["POSTIT"], ["PHOTO"], ["All_ROUNDER"], ["NO_IDEA"] 등 (최소 1)
    let s3Key: String?        // 프로필 이미지 S3 키 (선택)
    let userBooks: [OnboardingBook]  // 인생책 ISBN-13, 1~3권 (필수)
    let introduction: String  // 자기소개 (선택, 최대 50자)
}

struct OnboardingBook: Encodable {
    let isbn13: String
}

// MARK: - 마이페이지 (안드로이드 MypageResponse 대응)

struct MypageResponse: Decodable {
    let isSuccess: Bool
    let code: String
    let message: String
    let result: MypageResult?
}

struct MypageResult: Decodable {
    let userId: Int
    let profileImageUrl: String?
    let nickname: String
    let introduction: String?
    let gender: String?
    let birthDate: String?
    let userBooks: [MypageUserBook]?
    let bookReviewCount: Int?
    let recentBookReviews: [MypageBookReview]?
    let boomUpCount: Int?
    let recentReceivedReviews: [MypageReceivedReview]?
}

struct MypageUserBook: Decodable, Equatable, Identifiable {
    let title: String
    let auth: String
    let image: String?

    var id: String { "\(title)-\(auth)" }
}

struct MypageBookReview: Decodable, Equatable, Identifiable {
    let bookTitle: String
    let bookAuthor: String
    let tradeType: String
    let rating: Double
    let comment: String
    let reviewDate: String

    var id: String { "\(bookTitle)-\(reviewDate)" }

    private enum CodingKeys: String, CodingKey {
        case bookTitle, bookAuthor, tradeType, rating, comment, reviewDate
    }

    // 서버가 comment/reviewDate를 null로 내려도 디코딩이 실패하지 않도록 빈 문자열로 대체.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        bookTitle = try c.decode(String.self, forKey: .bookTitle)
        bookAuthor = try c.decode(String.self, forKey: .bookAuthor)
        tradeType = try c.decode(String.self, forKey: .tradeType)
        rating = try c.decode(Double.self, forKey: .rating)
        comment = try c.decodeIfPresent(String.self, forKey: .comment) ?? ""
        reviewDate = try c.decodeIfPresent(String.self, forKey: .reviewDate) ?? ""
    }
}

struct MypageReceivedReview: Decodable, Equatable, Identifiable {
    let reviewerNickname: String
    let reviewerProfileUrl: String?
    let reaction: String
    let comment: String
    let createdAt: String

    var id: String { "\(reviewerNickname)-\(createdAt)" }

    private enum CodingKeys: String, CodingKey {
        case reviewerNickname, reviewerProfileUrl, reaction, comment, createdAt
    }

    // 서버가 comment/createdAt를 null로 내려도 디코딩이 실패하지 않도록 빈 문자열로 대체.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        reviewerNickname = try c.decode(String.self, forKey: .reviewerNickname)
        reviewerProfileUrl = try c.decodeIfPresent(String.self, forKey: .reviewerProfileUrl)
        reaction = try c.decode(String.self, forKey: .reaction)
        comment = try c.decodeIfPresent(String.self, forKey: .comment) ?? ""
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
    }
}

struct MypageUpdateRequest: Encodable {
    let nickname: String
    let gender: String?
    let birth: String?
    let s3Key: String?
}

struct UpdateIntroductionRequest: Encodable {
    let introduction: String
}

// MARK: - 타 유저 프로필 (기존 스키마 유지)

struct MypageBadge: Decodable, Equatable {
    let userBadge: String
    let count: Int
}

struct MypageGroup: Decodable, Equatable, Identifiable {
    let groupId: Int
    let bookTitle: String?
    let auth: String?
    let genre: String?
    let groupStatus: String?
    let groupTags: [String]?

    var id: Int { groupId }

    enum CodingKeys: String, CodingKey {
        case groupId
        case bookTitle
        case auth
        case genre = "GENRE"
        case groupStatus = "group_status"
        case groupTags
    }
}

struct MypageBook: Decodable, Equatable {
    let bookTitle: String?
    let rating: Double?
}

// MARK: - 프로필 변경 (배송지/직접 교환 정보)

struct ProfileChangeInfoResponse: Decodable {
    let isSuccess: Bool
    let code: String
    let message: String
    let result: ProfileChangeInfoResult?
}

struct ProfileChangeInfoResult: Codable, Equatable {
    let recipientName: String?
    let phoneNumber: String?
    let zipCode: String?
    let address: String?
    let detailAddress: String?
    let exchangeRegion: String?
}

struct ProfileChangeUpdateRequest: Encodable {
    let recipientName: String?
    let phoneNumber: String?
    let zipCode: String?
    let address: String?
    let detailAddress: String?
    let exchangeRegion: String?
}

// MARK: - 타 유저 프로필 (안드로이드 OtherProfileResult 대응)

struct OtherProfileResponse: Decodable {
    let isSuccess: Bool
    let code: String
    let message: String
    let result: OtherProfileResult?
}

struct OtherProfileResult: Decodable {
    let userId: Int
    let profileImageUrl: String?
    let nickname: String
    let manner: Double
    let topTags: [String]?
    let completeBook: Int
    let readingGroup: Int       // 안드 @SerializedName("relayGroup")
    let togetherGroup: Int
    let userBadges: [MypageBadge]?
    let groups: [MypageGroup]?
    let books: [MypageBook]?

    enum CodingKeys: String, CodingKey {
        case userId
        case profileImageUrl
        case nickname
        case manner
        case topTags
        case completeBook
        case readingGroup = "relayGroup"
        case togetherGroup
        case userBadges
        case groups
        case books
    }
}

// MARK: - 프로필 공유 (POST /api/mypage/share-token)

struct ProfileShareTokenResult: Decodable {
    let shareToken: String
    let shareUrl: String
}

// MARK: - 공통 단순 응답

struct SimpleResponse: Decodable {
    let isSuccess: Bool
    let code: String
    let message: String
}
