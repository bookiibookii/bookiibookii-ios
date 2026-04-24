import Foundation

enum NotificationAPITarget: APITargetType {
    case list(category: String, cursor: String?, size: Int)
    case read(notificationId: Int)

    var path: String {
        switch self {
        case .list:
            return API.Path.notifications
        case .read(let notificationId):
            return API.Path.notifications + "/\(notificationId)/read"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list: return .get
        case .read: return .patch
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
        case .read:
            return []
        }
    }
}
