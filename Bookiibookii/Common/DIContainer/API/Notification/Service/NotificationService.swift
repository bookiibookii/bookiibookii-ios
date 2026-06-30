import Foundation

// 안드로이드 NotificationRepository + NotificationViewModel 호출부 대응.
final class NotificationService {
    private let interceptor: AuthInterceptor

    init(interceptor: AuthInterceptor) { self.interceptor = interceptor }

    /// GET /api/notifications?category=SYSTEM|KEYWORD&cursor=&size=
    func fetchNotifications(
        category: NotificationCategory,
        cursor: String?,
        size: Int
    ) async throws -> NotificationListResultDto {
        let request = NotificationAPITarget
            .list(category: category.rawValue, cursor: cursor, size: size)
            .asURLRequest()

        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw NotificationServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<NotificationListResultDto>.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw NotificationServiceError.server(response.message)
        }
        return result
    }

    /// PATCH /api/notifications/{id}/read
    @discardableResult
    func markAsRead(notificationId: Int) async throws -> NotificationItemDto {
        let request = NotificationAPITarget.read(notificationId: notificationId).asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw NotificationServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<NotificationItemDto>.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw NotificationServiceError.server(response.message)
        }
        return result
    }

    /// POST /api/device-tokens — FCM/APNs 기기 토큰 등록
    func registerDeviceToken(token: String) async throws {
        let request = NotificationAPITarget
            .registerDeviceToken(DeviceTokenRegisterRequest(token: token))
            .asURLRequest()
        let (_, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw NotificationServiceError.http(http.statusCode)
        }
    }

    /// DELETE /api/device-tokens (body 포함) — 기기 토큰 등록 해제
    func deactivateDeviceToken(token: String) async throws {
        let request = NotificationAPITarget
            .deactivateDeviceToken(DeviceTokenDeactivateRequest(token: token))
            .asURLRequest()
        let (_, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw NotificationServiceError.http(http.statusCode)
        }
    }
}

enum NotificationServiceError: LocalizedError {
    case http(Int)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .http(let code): return "서버 오류 (\(code))"
        case .server(let msg): return msg
        }
    }
}
