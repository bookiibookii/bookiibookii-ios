import Foundation

final class LibraryService {
    private let interceptor: AuthInterceptor

    init(interceptor: AuthInterceptor) {
        self.interceptor = interceptor
    }

    func fetchLibraryBooks() async throws -> [LibraryBook] {
        let request = LibraryAPITarget.fetchBooks.asURLRequest()
        return try await requestBooks(request)
    }

    func searchLibraryBooks(keyword: String) async throws -> [LibraryBook] {
        let request = LibraryAPITarget.searchBooks(keyword: keyword).asURLRequest()
        return try await requestBooks(request)
    }

    private func requestBooks(_ request: URLRequest) async throws -> [LibraryBook] {
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw LibraryServiceError.http(http.statusCode)
        }

        if let response = try? JSONDecoder().decode(ApiResponseDTO<[LibraryBookResponseDTO]>.self, from: data) {
            guard response.isSuccess else { throw LibraryServiceError.server(response.message) }
            return (response.result ?? []).map { $0.toDomain() }
        }

        if let response = try? JSONDecoder().decode(ApiResponseDTO<LibraryBooksResultDTO>.self, from: data) {
            guard response.isSuccess else { throw LibraryServiceError.server(response.message) }
            let list = response.result?.resolveBooks() ?? []
            return list.map { $0.toDomain() }
        }

        throw LibraryServiceError.invalidResponse
    }
}

enum LibraryServiceError: LocalizedError {
    case http(Int)
    case server(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .http(let code): return "서버 오류 (\(code))"
        case .server(let message): return message
        case .invalidResponse: return "서재 데이터를 해석하지 못했습니다."
        }
    }
}
