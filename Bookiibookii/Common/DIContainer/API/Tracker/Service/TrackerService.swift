import Foundation

// 안드로이드 TrkMainViewModel.loadHostTrackers / loadGuestTrackers 대응.
// ApiResponseDTO<[Dto]> 디코딩 후 도메인 모델(TrackerItem)로 매핑해서 반환.
final class TrackerService {
    private let interceptor: AuthInterceptor

    init(interceptor: AuthInterceptor) { self.interceptor = interceptor }

    /// GET /api/groups/me/trackers/host
    func fetchHostTrackers() async throws -> [TrackerItem] {
        let request = TrackerAPITarget.hostList.asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw TrackerServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<[HostTrackerListItemDto]>.self, from: data)
        guard response.isSuccess else {
            throw TrackerServiceError.server(response.message)
        }
        return (response.result ?? []).map { $0.toTrackerItem() }
    }

    /// GET /api/groups/me/trackers/guest
    func fetchGuestTrackers() async throws -> [TrackerItem] {
        let request = TrackerAPITarget.guestList.asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw TrackerServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<[GuestTrackerListItemDto]>.self, from: data)
        guard response.isSuccess else {
            throw TrackerServiceError.server(response.message)
        }
        return (response.result ?? []).map { $0.toTrackerItem() }
    }

    // MARK: - 택배 교환 단순 액션

    /// GET /api/groups/{groupId}/tracker
    func fetchDetail(groupId: Int) async throws -> TrackerDetailResponse {
        try await requestDetail(target: .detail(groupId: groupId))
    }

    /// PATCH /api/groups/{groupId}/tracker/reading
    func startReading(groupId: Int) async throws -> TrackerDetailResponse {
        try await requestDetail(target: .startReading(groupId: groupId))
    }

    /// PATCH /api/groups/{groupId}/tracker/extension?days=
    func requestExtension(groupId: Int, days: Int = 3) async throws -> TrackerDetailResponse {
        try await requestDetail(target: .requestExtension(groupId: groupId, days: days))
    }

    /// PATCH /api/groups/{groupId}/tracker/done
    func markDone(groupId: Int) async throws -> TrackerDetailResponse {
        try await requestDetail(target: .markDone(groupId: groupId))
    }

    /// PATCH /api/groups/{groupId}/tracker/reception/verification
    func verifyReception(groupId: Int) async throws -> TrackerDetailResponse {
        try await requestDetail(target: .verifyReception(groupId: groupId))
    }

    // MARK: - 공통 디코딩 헬퍼

    private func requestDetail(target: TrackerAPITarget) async throws -> TrackerDetailResponse {
        let (data, http) = try await interceptor.request(target.asURLRequest())
        guard (200...299).contains(http.statusCode) else {
            throw TrackerServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<TrackerDetailResponse>.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw TrackerServiceError.server(response.message)
        }
        return result
    }
}

enum TrackerServiceError: LocalizedError {
    case http(Int)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .http(let code): return "서버 오류 (\(code))"
        case .server(let msg): return msg
        }
    }
}
