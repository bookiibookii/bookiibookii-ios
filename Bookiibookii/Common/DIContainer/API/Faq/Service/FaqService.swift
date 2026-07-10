import Foundation

final class FaqService {
    private let interceptor: AuthInterceptor

    init(interceptor: AuthInterceptor) {
        self.interceptor = interceptor
    }

    func fetchFaqList() async throws -> [FaqItemDto] {
        let request = FaqAPITarget.list.asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw FaqServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<[FaqItemDto]>.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw FaqServiceError.server(response.message)
        }
        return result
    }
}

enum FaqServiceError: LocalizedError {
    case http(Int)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .http(let code): return "서버 오류 (\(code))"
        case .server(let message): return message.isEmpty ? "FAQ를 불러오지 못했습니다." : message
        }
    }
}
