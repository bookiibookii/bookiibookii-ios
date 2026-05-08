import Foundation

final class InquiryService {
    private let interceptor: AuthInterceptor

    init(interceptor: AuthInterceptor) {
        self.interceptor = interceptor
    }

    func fetchInquiryList() async throws -> [InquiryListItemDto] {
        let request = InquiryAPITarget.list.asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw InquiryServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<[InquiryListItemDto]>.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw InquiryServiceError.server(response.message)
        }
        return result
    }

    func createInquiry(_ payload: InquiryCreateRequestDto) async throws {
        let request = InquiryAPITarget.create(payload).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw InquiryServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<EmptyDTO>.self, from: data)
        guard response.isSuccess else {
            throw InquiryServiceError.server(response.message)
        }
    }
}

enum InquiryServiceError: LocalizedError {
    case http(Int)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .http(let code): return "서버 오류 (\(code))"
        case .server(let message): return message
        }
    }
}
