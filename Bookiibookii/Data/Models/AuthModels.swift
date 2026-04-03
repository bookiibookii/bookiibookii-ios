import Foundation

// 안드로이드 LoginRequest 대응
struct LoginRequest: Encodable {
    let socialType: String
    let token: String
}

// 안드로이드 RefreshTokenRequest 대응
struct RefreshRequest: Encodable {
    let refreshToken: String
}

struct RefreshResponse: Decodable {
    let isSuccess: Bool
    let code: String
    let message: String
    let result: RefreshResult?
}

struct RefreshResult: Decodable {
    let accessToken: String
}

// 안드로이드 LoginResponse 대응
struct LoginResponse: Decodable {
    let isSuccess: Bool
    let code: String
    let message: String
    let result: LoginResult?
}

struct LoginResult: Decodable {
    let accessToken: String
    let refreshToken: String
    let userId: Int
    let onboardingDone: Bool
}
