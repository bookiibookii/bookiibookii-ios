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
        print("[TRACKER/HOST] url=\(request.url?.absoluteString ?? "") status=\(http.statusCode)")
        print("[TRACKER/HOST] body=\(String(data: data, encoding: .utf8)?.prefix(800) ?? "<non-utf8>")")
        guard (200...299).contains(http.statusCode) else {
            throw TrackerServiceError.http(http.statusCode)
        }
        do {
            let response = try JSONDecoder().decode(ApiResponseDTO<[HostTrackerListItemDto]>.self, from: data)
            guard response.isSuccess else {
                throw TrackerServiceError.server(response.message)
            }
            return (response.result ?? []).map { $0.toTrackerItem() }
        } catch let DecodingError.keyNotFound(key, ctx) {
            print("[TRACKER/HOST] decode keyNotFound: \(key.stringValue) path=\(ctx.codingPath.map { $0.stringValue }.joined(separator: "."))")
            throw TrackerServiceError.server("응답 구조 불일치 (key: \(key.stringValue))")
        } catch let DecodingError.typeMismatch(type, ctx) {
            print("[TRACKER/HOST] decode typeMismatch: \(type) path=\(ctx.codingPath.map { $0.stringValue }.joined(separator: "."))")
            throw TrackerServiceError.server("응답 타입 불일치 (\(type))")
        } catch let DecodingError.valueNotFound(type, ctx) {
            print("[TRACKER/HOST] decode valueNotFound: \(type) path=\(ctx.codingPath.map { $0.stringValue }.joined(separator: "."))")
            throw TrackerServiceError.server("응답 값 누락 (\(type))")
        }
    }

    /// GET /api/groups/me/trackers/guest
    func fetchGuestTrackers() async throws -> [TrackerItem] {
        let request = TrackerAPITarget.guestList.asURLRequest()
        let (data, http) = try await interceptor.request(request)
        print("[TRACKER/GUEST] url=\(request.url?.absoluteString ?? "") status=\(http.statusCode)")
        print("[TRACKER/GUEST] body=\(String(data: data, encoding: .utf8)?.prefix(800) ?? "<non-utf8>")")
        guard (200...299).contains(http.statusCode) else {
            throw TrackerServiceError.http(http.statusCode)
        }
        do {
            let response = try JSONDecoder().decode(ApiResponseDTO<[GuestTrackerListItemDto]>.self, from: data)
            guard response.isSuccess else {
                throw TrackerServiceError.server(response.message)
            }
            return (response.result ?? []).map { $0.toTrackerItem() }
        } catch let DecodingError.keyNotFound(key, ctx) {
            print("[TRACKER/GUEST] decode keyNotFound: \(key.stringValue) path=\(ctx.codingPath.map { $0.stringValue }.joined(separator: "."))")
            throw TrackerServiceError.server("응답 구조 불일치 (key: \(key.stringValue))")
        } catch let DecodingError.typeMismatch(type, ctx) {
            print("[TRACKER/GUEST] decode typeMismatch: \(type) path=\(ctx.codingPath.map { $0.stringValue }.joined(separator: "."))")
            throw TrackerServiceError.server("응답 타입 불일치 (\(type))")
        } catch let DecodingError.valueNotFound(type, ctx) {
            print("[TRACKER/GUEST] decode valueNotFound: \(type) path=\(ctx.codingPath.map { $0.stringValue }.joined(separator: "."))")
            throw TrackerServiceError.server("응답 값 누락 (\(type))")
        }
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
