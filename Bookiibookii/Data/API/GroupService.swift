import Foundation

// 안드로이드 GroupFragment.loadGroupData 대응. GET /api/groups 한 엔드포인트.
final class GroupService {
    private let baseURL = URL(string: "https://bookii.gyeonseo.com/")!
    private let interceptor: AuthInterceptor

    init(interceptor: AuthInterceptor) { self.interceptor = interceptor }

    /// GET /api/groups
    /// - Parameters는 nil이면 해당 필터 미적용(전체).
    func fetchGroups(
        groupTypes: [String]?,
        tradeTypes: [String]?,
        meetPlace: [String]?,
        categories: [String]?,
        sort: GroupSort,
        page: Int,
        size: Int = 20
    ) async throws -> GroupPageResult {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("api/groups"),
            resolvingAgainstBaseURL: false
        )!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "sort", value: sort.rawValue),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size))
        ]
        groupTypes?.forEach { items.append(URLQueryItem(name: "groupTypes", value: $0)) }
        tradeTypes?.forEach { items.append(URLQueryItem(name: "tradeTypes", value: $0)) }
        meetPlace?.forEach  { items.append(URLQueryItem(name: "meetPlace",  value: $0)) }
        categories?.forEach { items.append(URLQueryItem(name: "categories", value: $0)) }
        components.queryItems = items

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"

        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw GroupServiceError.http(http.statusCode)
        }

        let response = try JSONDecoder().decode(GroupListResponse.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw GroupServiceError.server(response.message)
        }
        return result
    }
}

enum GroupServiceError: LocalizedError {
    case http(Int)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .http(let code): return "서버 오류 (\(code))"
        case .server(let msg): return msg
        }
    }
}
