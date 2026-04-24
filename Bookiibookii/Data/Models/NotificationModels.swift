import Foundation

// 안드로이드 NotificationModel.kt + NotificationType.kt 대응.

enum NotificationCategory: String, CaseIterable {
    case system = "SYSTEM"
    case keyword = "KEYWORD"
}

struct NotificationItemDto: Decodable, Identifiable, Equatable {
    let id: Int
    let type: String
    let title: String
    let message: String
    let isRead: Bool
    let createdAt: String
    let readAt: String?
}

struct NotificationListResultDto: Decodable, Equatable {
    let items: [NotificationItemDto]
    let nextCursor: String?
    let hasNext: Bool
}
