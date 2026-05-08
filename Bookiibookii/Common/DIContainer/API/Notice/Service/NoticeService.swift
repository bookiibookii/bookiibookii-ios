import Foundation

final class NoticeService {
    private let interceptor: AuthInterceptor

    init(interceptor: AuthInterceptor) {
        self.interceptor = interceptor
    }

    func fetchNoticeList() async throws -> [NoticeListItemDto] {
        let request = NoticeAPITarget.list.asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw NoticeServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<[NoticeListItemDto]>.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw NoticeServiceError.server(response.message)
        }
        return result
    }

    func fetchNoticeDetail(noticeId: Int) async throws -> NoticeDetailDto {
        let request = NoticeAPITarget.detail(noticeId: noticeId).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw NoticeServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<NoticeDetailDto>.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw NoticeServiceError.server(response.message)
        }
        return result
    }
}

enum NoticeServiceError: LocalizedError {
    case http(Int)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .http(let code): return "서버 오류 (\(code))"
        case .server(let message): return message
        }
    }
}
