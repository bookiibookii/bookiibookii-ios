import Foundation

/// 안드로이드 NotificationRedirect + NotificationRedirectRouter 대응.
struct NotificationRedirect: Equatable {
    let redirectType: String
    let groupId: Int?
    let cardId: Int?
    let title: String?
}

enum NotificationRedirectRouter {
    static let keyRedirectType = "redirectType"
    static let keyGroupId = "groupId"
    static let keyCardId = "cardId"
    static let keyTitle = "title"

    static func fromPayload(_ payload: NotificationPayload?) -> NotificationRedirect? {
        guard let payload,
              let redirectType = payload.redirectType,
              !redirectType.isEmpty else { return nil }
        return NotificationRedirect(
            redirectType: redirectType,
            groupId: payload.groupId,
            cardId: payload.cardId,
            title: payload.title
        )
    }

    /// FCM / APNs userInfo (모두 String 값일 수 있음)
    static func fromUserInfo(_ userInfo: [AnyHashable: Any]?) -> NotificationRedirect? {
        guard let userInfo else { return nil }
        let map = userInfo.reduce(into: [String: Any]()) { result, entry in
            guard let key = entry.key as? String else { return }
            result[key] = entry.value
        }
        guard let redirectType = stringValue(map[keyRedirectType]), !redirectType.isEmpty else {
            return nil
        }
        return NotificationRedirect(
            redirectType: redirectType,
            groupId: intValue(map[keyGroupId]),
            cardId: intValue(map[keyCardId]),
            title: stringValue(map[keyTitle])
        )
    }

    private static func stringValue(_ value: Any?) -> String? {
        switch value {
        case let s as String:
            return s.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        case let n as NSNumber:
            return n.stringValue
        default:
            return nil
        }
    }

    private static func intValue(_ value: Any?) -> Int? {
        switch value {
        case let i as Int:
            return i
        case let n as NSNumber:
            return n.intValue
        case let s as String:
            return Int(s)
        default:
            return nil
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
