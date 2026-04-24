import Foundation

// 안드로이드 HomeFragment.loadRecommendedGroups 대응. GET /api/recommendations/groups.
final class RecommendationService {
    private let interceptor: AuthInterceptor

    init(interceptor: AuthInterceptor) { self.interceptor = interceptor }

    /// GET /api/recommendations/groups?refresh=...
    /// 서버는 최대 3개의 추천 그룹을 반환한다.
    func fetchRecommendedGroups(refresh: Bool) async throws -> [RecommendedGroupDto] {
        let request = RecommendationAPITarget.recommendedGroups(refresh: refresh).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw RecommendationServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<[RecommendedGroupDto]>.self, from: data)
        guard response.isSuccess else {
            throw RecommendationServiceError.server(response.message)
        }
        return response.result ?? []
    }

    /// GET /api/recommendations/bookmates
    /// 서버는 최대 5명의 추천 메이트를 반환한다. 사용자 태그가 없으면 `USERTAG404`를 내려주는데,
    /// 안드로이드와 동일하게 정상 빈 리스트로 취급한다.
    func fetchRecommendedBookmates() async throws -> [RecommendedBookmateDto] {
        let request = RecommendationAPITarget.recommendedBookmates.asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw RecommendationServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<[RecommendedBookmateDto]>.self, from: data)
        if response.isSuccess {
            return response.result ?? []
        }
        if response.code == "USERTAG404" {
            return []
        }
        throw RecommendationServiceError.server(response.message)
    }
}

enum RecommendationServiceError: LocalizedError {
    case http(Int)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .http(let code): return "서버 오류 (\(code))"
        case .server(let msg): return msg
        }
    }
}
