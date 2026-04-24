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
    /// 서버가 내려주는 payload JSON. 유형별 필요한 필드만 lazy 추출.
    let payload: NotificationPayload?
}

struct NotificationListResultDto: Decodable, Equatable {
    let items: [NotificationItemDto]
    let nextCursor: String?
    let hasNext: Bool
}

/// payload를 [String: AnyJSONValue]로 받아두고 필요한 키만 조회.
struct NotificationPayload: Decodable, Equatable {
    private let storage: [String: AnyJSONValue]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        storage = (try? container.decode([String: AnyJSONValue].self)) ?? [:]
    }

    /// groupId / group_id / targetGroupId / target_group_id 순.
    var groupId: Int? {
        for key in ["groupId", "group_id", "targetGroupId", "target_group_id"] {
            if let v = storage[key]?.asInt { return v }
        }
        return nil
    }
}

enum AnyJSONValue: Decodable, Equatable {
    case int(Int)
    case double(Double)
    case string(String)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null; return }
        if let v = try? c.decode(Int.self) { self = .int(v); return }
        if let v = try? c.decode(Double.self) { self = .double(v); return }
        if let v = try? c.decode(Bool.self) { self = .bool(v); return }
        if let v = try? c.decode(String.self) { self = .string(v); return }
        self = .null
    }

    var asInt: Int? {
        switch self {
        case .int(let v): return v
        case .double(let v): return Int(v)
        case .string(let s): return Int(s)
        default: return nil
        }
    }
}
