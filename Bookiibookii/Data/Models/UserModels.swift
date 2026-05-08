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
    let name: String
    let tags: [OnboardingTag]
    let s3Key: String?
}

struct OnboardingTag: Encodable {
    let type: String
    let value: [String]
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
    let manner: Double?
    let topTags: [String]?
    let completeBook: Int?
    let relayGroup: Int?
    let togetherGroup: Int?
    let userBadges: [MypageBadge]?
    let groups: [MypageGroup]?
    let books: [MypageBook]?
    let receiverName: String?
    let phone: String?
    let zipCode: String?
    let address: String?
    let addressDetail: String?
    let region: String?
    let meetPlace: String?
}

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

struct MypageUpdateRequest: Encodable {
    let nickname: String
    let s3Key: String?
    let receiverName: String
    let phone: String
    let zipCode: String
    let address: String
    let addressDetail: String
    let meetPlace: String?
    let region: String?
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

// MARK: - 공통 단순 응답

struct SimpleResponse: Decodable {
    let isSuccess: Bool
    let code: String
    let message: String
}
