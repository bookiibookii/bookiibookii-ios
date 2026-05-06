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

    func fetchBookmarkedLibraryCards() async throws -> [LibraryCard] {
        let request = LibraryAPITarget.fetchBookmarkedCards.asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw LibraryServiceError.http(http.statusCode)
        }

        guard let response = try? JSONDecoder().decode(ApiResponseDTO<[GroupCardResponseDTO]>.self, from: data) else {
            throw LibraryServiceError.invalidResponse
        }
        guard response.isSuccess else {
            throw LibraryServiceError.server(response.message)
        }

        return (response.result ?? []).map { $0.toLibraryCard() }
    }

    func fetchLibraryCards(groupId: Int) async throws -> LibraryCardList {
        let request = LibraryAPITarget.fetchCards(groupId: groupId).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw LibraryServiceError.http(http.statusCode)
        }

        guard let response = try? JSONDecoder().decode(ApiResponseDTO<CardListResponseDTO>.self, from: data) else {
            throw LibraryServiceError.invalidResponse
        }
        guard response.isSuccess else {
            throw LibraryServiceError.server(response.message)
        }

        return (response.result ?? CardListResponseDTO(
            groupId: groupId,
            currentBookOwner: nil,
            myComment: nil,
            partnerComment: nil,
            togetherComments: nil,
            cards: []
        )).toDomain()
    }

    func toggleLibraryCardBookmark(cardId: Int) async throws -> Bool {
        let request = LibraryAPITarget.toggleCardBookmark(cardId: cardId).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw LibraryServiceError.http(http.statusCode)
        }

        guard let response = try? JSONDecoder().decode(ApiResponseDTO<CardBookmarkResponseDTO>.self, from: data) else {
            throw LibraryServiceError.invalidResponse
        }
        guard response.isSuccess else {
            throw LibraryServiceError.server(response.message)
        }
        guard let dto = response.result else {
            throw LibraryServiceError.invalidResponse
        }

        return dto.bookmarked
    }

    func fetchLibraryCardDetail(cardId: Int) async throws -> LibraryCardDetail {
        let request = LibraryAPITarget.fetchCardDetail(cardId: cardId).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw LibraryServiceError.http(http.statusCode)
        }

        guard let response = try? JSONDecoder().decode(ApiResponseDTO<GroupCardResponseDTO>.self, from: data) else {
            throw LibraryServiceError.invalidResponse
        }
        guard response.isSuccess, let result = response.result else {
            throw LibraryServiceError.server(response.message)
        }

        return result.toLibraryCardDetail()
    }

    func fetchLibraryCardComments(cardId: Int) async throws -> LibraryCardCommentList {
        let request = LibraryAPITarget.fetchCardComments(cardId: cardId).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw LibraryServiceError.http(http.statusCode)
        }

        guard let response = try? JSONDecoder().decode(ApiResponseDTO<CardCommentListResponseDTO>.self, from: data) else {
            throw LibraryServiceError.invalidResponse
        }
        guard response.isSuccess, let result = response.result else {
            throw LibraryServiceError.server(response.message)
        }

        return result.toDomain()
    }

    func createLibraryCardComment(cardId: Int, content: String) async throws {
        let body = CardCommentCreateRequestBody(content: content)
        let request = LibraryAPITarget.createCardComment(cardId: cardId, body: body).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw LibraryServiceError.http(http.statusCode)
        }

        guard let response = try? JSONDecoder().decode(ApiResponseDTO<CardCommentCreateResponseDTO>.self, from: data) else {
            throw LibraryServiceError.invalidResponse
        }
        guard response.isSuccess else {
            throw LibraryServiceError.server(response.message)
        }
    }

    /// POST `/api/cards/{userBookId}/presigned-url` — 신규 카드 등록 전 이미지 업로드. 응답의 `presignedPutUrl`로 PUT (Authorization 없음).
    func requestCardImagePresignedURL(userBookId: Int) async throws -> PresignedUrlResult {
        let request = LibraryAPITarget.cardPresignedPutURL(userBookId: userBookId).asURLRequest()
        return try await decodePresignedUrlResponse(await interceptor.request(request))
    }

    /// POST `/api/cards/{cardId}/images/presigned-url` — 기존 카드 이미지 교체 시 (카드 소유자만).
    func requestCardImagePresignedURLForUpdate(cardId: Int) async throws -> PresignedUrlResult {
        let request = LibraryAPITarget.cardPresignedPutURLForImageUpdate(cardId: cardId).asURLRequest()
        return try await decodePresignedUrlResponse(await interceptor.request(request))
    }

    private func decodePresignedUrlResponse(_ result: (Data, HTTPURLResponse)) throws -> PresignedUrlResult {
        let (data, http) = result
        guard (200...299).contains(http.statusCode) else {
            throw LibraryServiceError.http(http.statusCode)
        }

        guard let response = try? JSONDecoder().decode(ApiResponseDTO<PresignedUrlResult>.self, from: data) else {
            throw LibraryServiceError.invalidResponse
        }
        guard response.isSuccess, let urlResult = response.result else {
            throw LibraryServiceError.server(response.message)
        }
        return urlResult
    }

    func uploadCardImageToS3(presignedPutUrl: String, imageData: Data) async throws {
        guard let url = URL(string: presignedPutUrl) else {
            throw LibraryServiceError.invalidResponse
        }

        var putRequest = URLRequest(url: url)
        putRequest.httpMethod = "PUT"
        putRequest.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        putRequest.httpBody = imageData

        let (_, response) = try await URLSession.shared.data(for: putRequest)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw LibraryServiceError.http((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
    }

    func createLibraryCard(userBookId: Int, s3Key: String, page: Int, memo: String?) async throws -> CardCreateResponseDTO {
        let body = CardCreateRequestBody(s3Key: s3Key, page: page, memo: memo)
        let request = LibraryAPITarget.createCard(userBookId: userBookId, body: body).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw LibraryServiceError.http(http.statusCode)
        }

        guard let response = try? JSONDecoder().decode(ApiResponseDTO<CardCreateResponseDTO>.self, from: data) else {
            throw LibraryServiceError.invalidResponse
        }
        guard response.isSuccess, let result = response.result else {
            throw LibraryServiceError.server(response.message)
        }
        return result
    }

    /// PATCH `/api/cards/{cardId}` — 본문은 생성과 동일(`s3Key`, `page`, `memo`). 서버 스펙이 다르면 경로·메서드를 맞춰 주세요.
    func updateLibraryCard(cardId: Int, s3Key: String, page: Int, memo: String?) async throws {
        let body = CardCreateRequestBody(s3Key: s3Key, page: page, memo: memo)
        let request = LibraryAPITarget.updateCard(cardId: cardId, body: body).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw LibraryServiceError.http(http.statusCode)
        }

        guard let response = try? JSONDecoder().decode(ApiResponseDTO<GroupCardResponseDTO>.self, from: data) else {
            throw LibraryServiceError.invalidResponse
        }
        guard response.isSuccess else {
            throw LibraryServiceError.server(response.message)
        }
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
