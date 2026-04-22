import Foundation

// 안드로이드 ApiService의 유저/온보딩 관련 엔드포인트 대응
final class UserService {
    private let baseURL = URL(string: "https://bookii.gyeonseo.com/")!
    private let interceptor: AuthInterceptor

    init(interceptor: AuthInterceptor) {
        self.interceptor = interceptor
    }

    // POST /api/users/name-validation?nickname=xxx
    func checkNickname(_ nickname: String) async throws -> NicknameValidationResult {
        var components = URLComponents(url: baseURL.appendingPathComponent("api/users/name-validation"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "nickname", value: nickname)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"

        let (data, _) = try await interceptor.request(request)
        let response = try JSONDecoder().decode(NicknameValidationResponse.self, from: data)

        guard response.isSuccess, let result = response.result else {
            throw UserError.nicknameFailed(response.message)
        }
        return result
    }

    // POST /api/users/me/image/presigned-url
    func getPresignedUrl() async throws -> PresignedUrlResult {
        let url = baseURL.appendingPathComponent("api/users/me/image/presigned-url")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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
        let url = baseURL.appendingPathComponent("api/onboarding")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await interceptor.request(request)
        let response = try JSONDecoder().decode(SimpleResponse.self, from: data)

        guard response.isSuccess else {
            throw UserError.onboardingFailed(response.message)
        }
        TokenManager.shared.isOnboardingDone = true
    }

    // GET /api/mypage
    func getMypage() async throws -> MypageResult {
        let url = baseURL.appendingPathComponent("api/mypage")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

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
