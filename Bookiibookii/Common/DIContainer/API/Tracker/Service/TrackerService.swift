import Foundation

// 안드로이드 TrkApi 호출부 대응 (신규 트래커 구조).
final class TrackerService {
    private let interceptor: AuthInterceptor

    init(interceptor: AuthInterceptor) {
        self.interceptor = interceptor
    }

    // MARK: - 목록 / 상세

    /// GET /api/me/trackers
    func fetchMyTrackers() async throws -> TrackerListResDTO {
        try await request(target: .myTrackers)
    }

    /// GET /api/trackers/{groupId}/tracker
    func fetchDetail(groupId: Int) async throws -> TrackerDetailResDTO {
        try await request(target: .detail(groupId: groupId))
    }

    // MARK: - 독서 진행률 / 기간

    /// PATCH /api/trackers/{groupId}/reading-progress
    func updateReadingProgress(groupId: Int, currentPage: Int) async throws -> ReadingProgressResDTO {
        try await request(target: .readingProgress(groupId: groupId, body: .init(currentPage: currentPage)))
    }

    /// PATCH /api/trackers/{groupId}/reading-period — 호스트 전용
    func updateReadingPeriod(groupId: Int, newEndDate: String) async throws -> ReadingPeriodUpdateResDTO {
        try await request(target: .readingPeriod(groupId: groupId, body: .init(newEndDate: newEndDate)))
    }

    // MARK: - 책 후기

    /// GET /api/groups/{groupId}/reviews/book/me
    func fetchMyBookReviews(groupId: Int) async throws -> MyBookReviewsResDTO {
        try await request(target: .myBookReviews(groupId: groupId))
    }

    /// POST /api/groups/{groupId}/reviews
    func createBookReview(groupId: Int, star: Double, comment: String?) async throws -> BookReviewResDTO {
        try await request(target: .postBookReview(groupId: groupId, body: .init(star: star, comment: comment)))
    }

    /// PATCH /api/groups/{groupId}/reviews/book/{reviewId}
    func updateBookReview(groupId: Int, reviewId: Int, star: Double, comment: String?) async throws -> BookReviewResDTO {
        try await request(target: .patchBookReview(groupId: groupId, reviewId: reviewId, body: .init(star: star, comment: comment)))
    }

    /// POST /api/groups/{groupId}/member-reviews
    func createMemberReview(groupId: Int, reaction: String?, comment: String) async throws -> MemberReviewResDTO {
        try await request(target: .postMemberReview(groupId: groupId, body: .init(reaction: reaction, comment: comment)))
    }

    // MARK: - 배송 / 약속

    /// POST /api/groups/{groupId}/deliveries
    func registerDelivery(groupId: Int, deliveryCompany: String, trackingNumber: String) async throws {
        try await requestStatusOnly(target: .registerDelivery(groupId: groupId, body: .init(deliveryCompany: deliveryCompany, trackingNumber: trackingNumber)))
    }

    /// POST /api/groups/{groupId}/meetings
    func registerMeeting(groupId: Int, body: MeetingRegisterReqDTO) async throws -> MeetingResDTO {
        try await request(target: .registerMeeting(groupId: groupId, body: body))
    }

    /// GET /api/groups/{groupId}/meetings
    func fetchMeeting(groupId: Int) async throws -> MeetingResDTO {
        try await request(target: .fetchMeeting(groupId: groupId))
    }

    /// PATCH /api/groups/{groupId}/meetings
    func updateMeeting(groupId: Int, body: MeetingRegisterReqDTO) async throws -> MeetingResDTO {
        try await request(target: .updateMeeting(groupId: groupId, body: body))
    }

    /// PATCH /api/groups/{groupId}/meetings/completion
    func completeMeeting(groupId: Int) async throws -> MeetingResDTO {
        try await request(target: .completeMeeting(groupId: groupId))
    }

    // MARK: - 배송지

    /// GET /api/groups/{groupId}/deliveries/address
    func fetchDeliveryAddress(groupId: Int) async throws -> DeliveryAddressResDTO {
        try await request(target: .deliveryAddress(groupId: groupId))
    }

    /// PUT /api/groups/{groupId}/deliveries/address/me/saved
    func updateDeliveryAddressSaved(groupId: Int, userDeliveryId: Int) async throws -> DeliveryAddressResDTO {
        try await request(target: .updateDeliveryAddressSaved(groupId: groupId, body: .init(userDeliveryId: userDeliveryId)))
    }

    /// PUT /api/groups/{groupId}/deliveries/address/me/direct
    func updateDeliveryAddressDirect(groupId: Int, body: DeliveryAddressDirectUpdateReqDTO) async throws -> DeliveryAddressResDTO {
        try await request(target: .updateDeliveryAddressDirect(groupId: groupId, body: body))
    }

    /// GET /api/groups/{groupId}/deliveries/partner
    func fetchPartnerDelivery(groupId: Int) async throws -> PartnerDeliveryResponseDTO {
        try await request(target: .partnerDelivery(groupId: groupId))
    }

    /// PATCH /api/groups/{groupId}/deliveries/partner/receive
    func confirmPartnerReceive(groupId: Int) async throws {
        try await requestStatusOnly(target: .confirmPartnerReceive(groupId: groupId))
    }

    // MARK: - Library 호환용 임시 stub
    // 구 트래커 API(독서율 출처)를 신규 구조로 재연동하기 전까지 빈 맵을 반환합니다.
    // Library 함께읽기 게이지는 라이브러리 응답/로컬 캐시 폴백을 사용합니다.

    struct TogetherReadingRateSnapshot {
        let myReadingRate: Int
        let groupReadingRate: Int
    }

    /// TODO: 신규 TrackerListResDTO 기반으로 함께읽기 독서율 재연동.
    func fetchTogetherReadingRates() async throws -> [Int: TogetherReadingRateSnapshot] {
        return [:]
    }

    // MARK: - 공통 헬퍼

    private func request<T: Decodable>(target: TrackerAPITarget) async throws -> T {
        let (data, http) = try await interceptor.request(target.asURLRequest())
        guard (200...299).contains(http.statusCode) else {
            throw TrackerServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<T>.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw TrackerServiceError.server(response.message)
        }
        return result
    }

    private func requestStatusOnly(target: TrackerAPITarget) async throws {
        let (data, http) = try await interceptor.request(target.asURLRequest())
        guard (200...299).contains(http.statusCode) else {
            if let msg = (try? JSONDecoder().decode(ApiResponseDTO<String>.self, from: data))?.message {
                throw TrackerServiceError.server(msg)
            }
            throw TrackerServiceError.http(http.statusCode)
        }
    }
}

enum TrackerServiceError: LocalizedError {
    case http(Int)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .http(let code):  return "서버 오류 (\(code))"
        case .server(let msg): return msg
        }
    }
}
