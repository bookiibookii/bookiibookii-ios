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

    func fetchGroupReviews(groupId: Int) async throws -> LibraryGroupReviewsResponseDTO {
        let request = LibraryAPITarget.fetchGroupReviews(groupId: groupId).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw LibraryServiceError.http(http.statusCode)
        }

        guard let response = try? JSONDecoder().decode(
            ApiResponseDTO<LibraryGroupReviewsResponseDTO>.self,
            from: data
        ) else {
            throw LibraryServiceError.invalidResponse
        }
        guard response.isSuccess else {
            throw LibraryServiceError.server(response.message)
        }
        guard let result = response.result else {
            throw LibraryServiceError.invalidResponse
        }
        return result
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

    func toggleLibraryCardReaction(
        cardId: Int,
        reaction: LibraryCardReaction
    ) async throws -> Bool {
        let request = LibraryAPITarget.toggleCardReaction(
            cardId: cardId,
            body: CardReactionToggleRequestBody(reaction: reaction)
        ).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw LibraryServiceError.http(http.statusCode)
        }

        guard let response = try? JSONDecoder().decode(
            ApiResponseDTO<CardReactionToggleResponseDTO>.self,
            from: data
        ) else {
            throw LibraryServiceError.invalidResponse
        }
        guard response.isSuccess, let result = response.result else {
            throw LibraryServiceError.server(response.message)
        }
        return result.active
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

    /// POST `/api/member-books/{userBookId}/cards/presigned-url` — 카드 이미지 업로드 URL 발급.
    func requestCardImagePresignedURL(userBookId: Int) async throws -> PresignedUrlResult {
        let request = LibraryAPITarget.cardPresignedPutURL(userBookId: userBookId).asURLRequest()
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

    func createLibraryCard(
        userBookId: Int,
        cardType: LibraryCardType,
        s3Key: String?,
        quotation: String?,
        page: Int,
        memo: String?
    ) async throws -> CardCreateResponseDTO {
        let body = CardCreateRequestBody(
            cardType: cardType == .image ? "IMAGE" : "TEXT",
            quotation: quotation,
            s3Key: s3Key,
            page: page,
            memo: memo
        )
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

    /// PATCH `/api/member-books/cards/{cardId}` — 전달한 필드만 수정.
    func updateLibraryCard(
        cardId: Int,
        s3Key: String?,
        page: Int,
        memo: String?,
        quotation: String?
    ) async throws {
        let body = CardUpdateRequestBody(s3Key: s3Key, page: page, memo: memo, quotation: quotation)
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

    /// DELETE `/api/library/memberbooks/{memberBookId}`
    /// - `MemberBook.removedAt` 설정(소프트 삭제). 본인 서재 목록에서만 제거됩니다.
    func deleteLibraryMemberBook(memberBookId: Int) async throws {
        let request = LibraryAPITarget.deleteMemberBook(memberBookId: memberBookId).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            if let response = try? JSONDecoder().decode(ApiResponseDTO<EmptyResult>.self, from: data) {
                throw LibraryServiceError.server(
                    Self.mapDeleteMemberBookErrorMessage(code: response.code, message: response.message)
                )
            }
            throw LibraryServiceError.http(http.statusCode)
        }

        guard let response = try? JSONDecoder().decode(ApiResponseDTO<EmptyResult>.self, from: data) else {
            throw LibraryServiceError.invalidResponse
        }
        guard response.isSuccess else {
            throw LibraryServiceError.server(
                Self.mapDeleteMemberBookErrorMessage(code: response.code, message: response.message)
            )
        }
    }

    /// DELETE `/api/member-books/cards/{cardId}`
    /// - 비소유자: MemberCard.hidden=true (내 화면에서만 숨김)
    /// - 소유자: 서버는 Cards.deletedAt 설정(그룹 전체 제거). 앱에서는 동일 API 호출.
    func deleteLibraryCard(cardId: Int) async throws {
        let request = LibraryAPITarget.deleteCard(cardId: cardId).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            if let response = try? JSONDecoder().decode(ApiResponseDTO<EmptyResult>.self, from: data) {
                throw LibraryServiceError.server(
                    Self.mapDeleteCardErrorMessage(code: response.code, message: response.message)
                )
            }
            throw LibraryServiceError.http(http.statusCode)
        }

        guard let response = try? JSONDecoder().decode(ApiResponseDTO<EmptyResult>.self, from: data) else {
            throw LibraryServiceError.invalidResponse
        }
        guard response.isSuccess else {
            throw LibraryServiceError.server(
                Self.mapDeleteCardErrorMessage(code: response.code, message: response.message)
            )
        }
    }

    private static func mapDeleteMemberBookErrorMessage(code: String, message: String) -> String {
        switch code {
        case "MB404_1":
            return "해당 서재를 찾을 수 없어요."
        default:
            return message.isEmpty ? "서재를 삭제할 수 없어요." : message
        }
    }

    private static func mapDeleteCardErrorMessage(code: String, message: String) -> String {
        switch code {
        case "MB400_8":
            return "북마크된 독서카드는 삭제할 수 없어요."
        case "MB404_3", "MB404_2":
            return "해당 독서카드를 찾을 수 없어요."
        case "MB409_1":
            return "일시적인 오류가 발생했어요. 잠시 후 다시 시도해 주세요."
        default:
            return message.isEmpty ? "독서카드를 삭제할 수 없어요." : message
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
