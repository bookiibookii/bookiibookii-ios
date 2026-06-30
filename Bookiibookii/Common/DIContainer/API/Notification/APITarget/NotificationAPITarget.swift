import Foundation

enum NotificationAPITarget: APITargetType {
    case list(category: String, cursor: String?, size: Int)
    case read(notificationId: Int)
    case registerDeviceToken(DeviceTokenRegisterRequest)
    case deactivateDeviceToken(DeviceTokenDeactivateRequest)

    var path: String {
        switch self {
        case .list:
            return API.Path.notifications
        case .read(let notificationId):
            return API.Path.notifications + "/\(notificationId)/read"
        case .registerDeviceToken, .deactivateDeviceToken:
            return API.Path.deviceTokens
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list: return .get
        case .read: return .patch
        case .registerDeviceToken: return .post
        case .deactivateDeviceToken: return .delete
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .list(let category, let cursor, let size):
            var items = [
                URLQueryItem(name: "category", value: category),
                URLQueryItem(name: "size", value: String(size))
            ]
            if let cursor, !cursor.isEmpty {
                items.append(URLQueryItem(name: "cursor", value: cursor))
            }
            return items
        default:
            return []
        }
    }

    var body: Data? {
        switch self {
        case .registerDeviceToken(let request):
            return try? JSONEncoder().encode(request)
        case .deactivateDeviceToken(let request):
            return try? JSONEncoder().encode(request)
        default:
            return nil
        }
    }

    var headers: [String: String] {
        switch self {
        case .registerDeviceToken, .deactivateDeviceToken:
            return ["Content-Type": "application/json"]
        default:
            return [:]
        }
    }
}
