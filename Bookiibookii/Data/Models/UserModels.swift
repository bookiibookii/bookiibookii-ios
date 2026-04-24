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
