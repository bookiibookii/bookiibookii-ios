import Foundation

// 안드로이드 ApiService의 유저/온보딩 관련 엔드포인트 대응
final class UserService {
    private let interceptor: AuthInterceptor

    init(interceptor: AuthInterceptor) {
        self.interceptor = interceptor
    }

    // POST /api/users/name-validation?nickname=xxx
    func checkNickname(_ nickname: String) async throws -> NicknameValidationResult {
        let target = UserAPITarget.checkNickname(nickname)
        let request = target.asURLRequest()

        let (data, _) = try await interceptor.request(request)
        let response = try JSONDecoder().decode(NicknameValidationResponse.self, from: data)

        guard response.isSuccess, let result = response.result else {
            throw UserError.nicknameFailed(response.message)
        }
        return result
    }

    // POST /api/users/me/image/presigned-url
    func getPresignedUrl() async throws -> PresignedUrlResult {
        let target = UserAPITarget.presignedURL
        let request = target.asURLRequest()

        let (data, _) = try await interceptor.request(request)
        let response = try JSONDecoder().decode(PresignedUrlResponse.self, from: data)

        guard response.isSuccess, let result = response.result else {
            throw UserError.uploadFailed
        }
        return result
    }

    // PUT presignedPutUrl (S3 직접 업로드, Authorization 헤더 없음)
    func uploadImageToS3(presignedUrl: String, imageData: Data) async throws {
        guard let url = URL(string: presignedUrl) else { throw UserError.uploadFailed }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw UserError.uploadFailed
        }
    }

    // POST /api/onboarding
    func completeOnboarding(_ body: OnboardingRequest) async throws {
        let target = UserAPITarget.completeOnboarding(body)
        let request = target.asURLRequest()

        let (data, _) = try await interceptor.request(request)
        let response = try JSONDecoder().decode(SimpleResponse.self, from: data)

        guard response.isSuccess else {
            throw UserError.onboardingFailed(response.message)
        }
        TokenManager.shared.isOnboardingDone = true
    }

    // GET /api/mypage
    func getMypage() async throws -> MypageResult {
        let target = UserAPITarget.mypage
        let request = target.asURLRequest()

        let (data, _) = try await interceptor.request(request)
        let response = try JSONDecoder().decode(MypageResponse.self, from: data)

        guard response.isSuccess, let result = response.result else {
            throw UserError.profileFailed
        }
        return result
    }
}

enum UserError: LocalizedError {
    case nicknameFailed(String)
    case uploadFailed
    case onboardingFailed(String)
    case profileFailed

    var errorDescription: String? {
        switch self {
        case .nicknameFailed(let msg): return msg
        case .uploadFailed: return "이미지 업로드에 실패했습니다."
        case .onboardingFailed(let msg): return msg
        case .profileFailed: return "프로필을 불러오지 못했습니다."
        }
    }
}
