import Foundation

// 안드로이드 LoginRequest 대응
struct LoginRequest: Encodable {
    let socialType: String
    let token: String
    // 애플 로그인 전용 — 서버가 회원탈퇴 시 revoke에 사용한다 (카카오·구글은 nil이라 키가 빠짐)
    let authorizationCode: String?
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
    let refreshToken: String
    let userId: Int
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
    let onboardingStatus: String   // "COMPLETED" | "SPLASH_DONE" | 기타
    let role: String

    // 안드로이드 LoginActivity 분기 대응: COMPLETED 또는 SPLASH_DONE이면 온보딩 완료로 간주
    var isOnboardingDone: Bool {
        onboardingStatus == "COMPLETED" || onboardingStatus == "SPLASH_DONE"
    }
}
