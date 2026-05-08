import Foundation

// 안드로이드 GroupFragment.loadGroupData 대응. GET /api/groups 한 엔드포인트.
final class GroupService {
    private let baseURL = URL(string: API.baseURL + "/")!
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
        let target = GroupAPITarget.fetchGroups(
            groupTypes: groupTypes,
            tradeTypes: tradeTypes,
            meetPlace: meetPlace,
            categories: categories,
            sort: sort,
            page: page,
            size: size
        )
        let request = target.asURLRequest()

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

    /// GET /api/groups/popular-keywords
    func fetchPopularKeywords() async throws -> [String] {
        let target = GroupAPITarget.popularKeywords
        let request = target.asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw GroupServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(PopularKeywordsResponse.self, from: data)
        guard response.isSuccess else {
            throw GroupServiceError.server("인기 검색어를 불러오지 못했습니다")
        }
        return response.result
    }

    /// GET /api/groups/search?keyword=&sort=&page=&size=
    /// sort: .latest("LATEST") 또는 .popular("POPULAR") 만 사용
    func searchGroups(keyword: String, sort: GroupSort, page: Int, size: Int = 20) async throws -> GroupSearchResult {
        let target = GroupAPITarget.searchGroups(keyword: keyword, sort: sort, page: page, size: size)
        let request = target.asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw GroupServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(GroupSearchResponse.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw GroupServiceError.server(response.message)
        }
        return result
    }

    /// GET /api/books/search?keyword=&page=&size=
    func searchBooks(keyword: String, page: Int = 1, size: Int = 10) async throws -> [BookItem] {
        let target = GroupAPITarget.searchBooks(keyword: keyword, page: page, size: size)
        let request = target.asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw GroupServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(BookSearchAPIResponse.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw GroupServiceError.server(response.message)
        }
        return result.books
    }

    /// POST /api/groups
    func createGroup(_ body: GroupCreateRequest) async throws {
        let target = GroupAPITarget.createGroup(body)
        let request = target.asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            if let msg = (try? JSONDecoder().decode(APIErrorMessage.self, from: data))?.message {
                throw GroupServiceError.server(msg)
            }
            throw GroupServiceError.http(http.statusCode)
        }
    }

    /// GET /api/groups/{groupId}
    func fetchGroupDetail(groupId: Int) async throws -> GroupDetailDto {
        let request = GroupAPITarget.fetchGroupDetail(groupId: groupId).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw GroupServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(GroupDetailResponse.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw GroupServiceError.server(response.message)
        }
        return result
    }

    /// POST /api/groups/{groupId}/apply
    func applyGroup(groupId: Int, applyMsg: String) async throws {
        let request = GroupAPITarget.applyGroup(groupId: groupId, body: GroupApplyRequest(applyMsg: applyMsg)).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            if let msg = (try? JSONDecoder().decode(APIErrorMessage.self, from: data))?.message {
                throw GroupServiceError.server(msg)
            }
            throw GroupServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(GroupApplyResultWrapper.self, from: data)
        guard response.isSuccess else { throw GroupServiceError.server(response.message) }
    }

    /// DELETE /api/groups/{groupId}/apply
    func cancelApply(groupId: Int) async throws {
        let request = GroupAPITarget.cancelApply(groupId: groupId).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            if let msg = (try? JSONDecoder().decode(APIErrorMessage.self, from: data))?.message {
                throw GroupServiceError.server(msg)
            }
            throw GroupServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(GroupCancelResultWrapper.self, from: data)
        guard response.isSuccess else { throw GroupServiceError.server(response.message) }
    }

    /// GET /api/groups/{groupId}/applylist
    func fetchApplicants(groupId: Int) async throws -> [GroupApplicantDto] {
        let request = GroupAPITarget.fetchApplicants(groupId: groupId).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw GroupServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(GroupApplicantListResponse.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw GroupServiceError.server(response.message)
        }
        return result.applicationList
    }

    /// PATCH /api/groups/apply/{applyId}
    func updateApplicant(applicationId: Int, status: String) async throws {
        let request = GroupAPITarget.updateApplicant(applicationId: applicationId, body: GroupAppStatusRequest(status: status)).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            if let msg = (try? JSONDecoder().decode(APIErrorMessage.self, from: data))?.message {
                throw GroupServiceError.server(msg)
            }
            throw GroupServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(GroupAppStatusResponse.self, from: data)
        guard response.isSuccess else { throw GroupServiceError.server(response.message) }
    }

    /// PATCH /api/groups/{groupId}
    func modifyGroup(groupId: Int, body: GroupModifyRequest) async throws {
        let request = GroupAPITarget.modifyGroup(groupId: groupId, body: body).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            if let msg = (try? JSONDecoder().decode(APIErrorMessage.self, from: data))?.message {
                throw GroupServiceError.server(msg)
            }
            throw GroupServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(GroupModifyResultWrapper.self, from: data)
        guard response.isSuccess else { throw GroupServiceError.server(response.message) }
    }

    /// PATCH /api/groups/{groupId}/together/members/me/complete
    func completeTogetherReading(groupId: Int) async throws -> TogetherCompleteReadingResultDTO {
        let request = GroupAPITarget.completeTogetherReading(groupId: groupId).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            if let msg = (try? JSONDecoder().decode(APIErrorMessage.self, from: data))?.message {
                throw GroupServiceError.server(msg)
            }
            throw GroupServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<TogetherCompleteReadingResultDTO>.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw GroupServiceError.server(response.message)
        }
        return result
    }

    /// POST /api/reviews/together/{userBookId}
    func createTogetherReview(userBookId: Int, rating: Double, comment: String?) async throws {
        let trimmed = comment?.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = TogetherReviewCreateRequest(
            rating: rating,
            comment: (trimmed?.isEmpty == true) ? nil : trimmed
        )
        let request = GroupAPITarget.createTogetherReview(userBookId: userBookId, body: body).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            if let msg = (try? JSONDecoder().decode(APIErrorMessage.self, from: data))?.message {
                throw GroupServiceError.server(msg)
            }
            throw GroupServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<EmptyResult>.self, from: data)
        guard response.isSuccess else {
            throw GroupServiceError.server(response.message)
        }
    }

    /// DELETE /api/groups/{groupId}
    func deleteGroup(groupId: Int) async throws {
        let request = GroupAPITarget.deleteGroup(groupId: groupId).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            if let msg = (try? JSONDecoder().decode(APIErrorMessage.self, from: data))?.message {
                throw GroupServiceError.server(msg)
            }
            throw GroupServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(GroupDeleteResultWrapper.self, from: data)
        guard response.isSuccess else { throw GroupServiceError.server(response.message) }
    }

    private struct APIErrorMessage: Decodable { let message: String }
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
