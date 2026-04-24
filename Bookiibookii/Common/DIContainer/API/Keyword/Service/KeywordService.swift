import Foundation

// 안드로이드 KeywordRepository + KeywordViewModel 호출부 대응.
final class KeywordService {
    private let interceptor: AuthInterceptor

    init(interceptor: AuthInterceptor) { self.interceptor = interceptor }

    /// GET /api/keywords?sort=LATEST|ALPHABETICAL
    func fetchKeywords(sort: KeywordSort) async throws -> KeywordListResultDto {
        let request = KeywordAPITarget.list(sort: sort).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw KeywordServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<KeywordListResultDto>.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw KeywordServiceError.server(response.message)
        }
        return result
    }

    /// POST /api/keywords — body: { content }
    @discardableResult
    func createKeyword(content: String) async throws -> KeywordCreateResultDto {
        let request = KeywordAPITarget.create(KeywordCreateRequest(content: content)).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            if let msg = (try? JSONDecoder().decode(APIErrorResponseDTO.self, from: data))?.message {
                throw KeywordServiceError.server(msg)
            }
            throw KeywordServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<KeywordCreateResultDto>.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw KeywordServiceError.server(response.message)
        }
        return result
    }

    /// DELETE /api/keywords/{keywordId}
    func deleteKeyword(keywordId: Int) async throws {
        let request = KeywordAPITarget.delete(keywordId: keywordId).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            if let msg = (try? JSONDecoder().decode(APIErrorResponseDTO.self, from: data))?.message {
                throw KeywordServiceError.server(msg)
            }
            throw KeywordServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<String?>.self, from: data)
        guard response.isSuccess else {
            throw KeywordServiceError.server(response.message)
        }
    }
}

enum KeywordServiceError: LocalizedError {
    case http(Int)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .http(let code): return "서버 오류 (\(code))"
        case .server(let msg): return msg
        }
    }
}
