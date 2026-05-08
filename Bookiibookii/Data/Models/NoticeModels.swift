import Foundation

struct NoticeListItemDto: Decodable, Identifiable, Equatable {
    let id: Int
    let createdAt: Date
    let title: String
    let summary: String

    enum CodingKeys: String, CodingKey {
        case id, createdAt, title, summary
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = intId
        } else {
            let longId = try container.decode(Int64.self, forKey: .id)
            id = Int(longId)
        }
        title = try container.decode(String.self, forKey: .title)
        summary = try container.decode(String.self, forKey: .summary)
        createdAt = try Self.decodeDate(forKey: .createdAt, from: container)
    }
}

struct NoticeDetailDto: Decodable, Equatable {
    let id: Int
    let title: String
    let content: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, content, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = intId
        } else {
            let longId = try container.decode(Int64.self, forKey: .id)
            id = Int(longId)
        }
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        createdAt = try Self.decodeDate(forKey: .createdAt, from: container)
    }
}

private extension Decodable {
    static func decodeDate<K: CodingKey>(
        forKey key: K,
        from container: KeyedDecodingContainer<K>
    ) throws -> Date {
        if let value = try? container.decode(String.self, forKey: key) {
            if let parsed = NoticeDateParser.parse(value) { return parsed }
        }
        if let parts = try? container.decode([Int].self, forKey: key), parts.count >= 5 {
            let second = parts.count > 5 ? parts[5] : 0
            let nanosecond = parts.count > 6 ? parts[6] : 0
            var comps = DateComponents()
            comps.year = parts[0]
            comps.month = parts[1]
            comps.day = parts[2]
            comps.hour = parts[3]
            comps.minute = parts[4]
            comps.second = second
            comps.nanosecond = nanosecond
            comps.timeZone = TimeZone(identifier: "Asia/Seoul")
            if let date = Calendar(identifier: .gregorian).date(from: comps) {
                return date
            }
        }
        if let object = try? container.decode(NoticeDateObject.self, forKey: key) {
            var comps = DateComponents()
            comps.year = object.year
            comps.month = object.monthValue
            comps.day = object.dayOfMonth
            comps.hour = object.hour
            comps.minute = object.minute
            comps.second = object.second
            comps.nanosecond = object.nano
            comps.timeZone = TimeZone(identifier: "Asia/Seoul")
            if let date = Calendar(identifier: .gregorian).date(from: comps) {
                return date
            }
        }
        if let object = try? container.decode(NoticeDateObjectWithMonthName.self, forKey: key) {
            var comps = DateComponents()
            comps.year = object.year
            comps.month = MonthName(rawValue: object.month.uppercased())?.number
            comps.day = object.dayOfMonth
            comps.hour = object.hour
            comps.minute = object.minute
            comps.second = object.second
            comps.nanosecond = object.nano
            comps.timeZone = TimeZone(identifier: "Asia/Seoul")
            if let date = Calendar(identifier: .gregorian).date(from: comps) {
                return date
            }
        }
        // 서버 직렬화 포맷이 환경별로 바뀌더라도 화면이 깨지지 않도록 안전 fallback.
        return Date()
    }
}

private struct NoticeDateObject: Decodable {
    let year: Int
    let monthValue: Int
    let dayOfMonth: Int
    let hour: Int
    let minute: Int
    let second: Int
    let nano: Int
}

private struct NoticeDateObjectWithMonthName: Decodable {
    let year: Int
    let month: String
    let dayOfMonth: Int
    let hour: Int
    let minute: Int
    let second: Int
    let nano: Int
}

private enum MonthName: String {
    case january = "JANUARY"
    case february = "FEBRUARY"
    case march = "MARCH"
    case april = "APRIL"
    case may = "MAY"
    case june = "JUNE"
    case july = "JULY"
    case august = "AUGUST"
    case september = "SEPTEMBER"
    case october = "OCTOBER"
    case november = "NOVEMBER"
    case december = "DECEMBER"

    var number: Int {
        switch self {
        case .january: return 1
        case .february: return 2
        case .march: return 3
        case .april: return 4
        case .may: return 5
        case .june: return 6
        case .july: return 7
        case .august: return 8
        case .september: return 9
        case .october: return 10
        case .november: return 11
        case .december: return 12
        }
    }
}

enum NoticeDateParser {
    private static let dotFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter
    }()

    private static let iso: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter
    }()

    private static let isoNoFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter
    }()

    private static let fallbackFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    private static let fallbackFractionFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        return formatter
    }()

    private static let fallbackLongFractionFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSSS"
        return formatter
    }()

    private static let fallbackSpaceFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    static func parse(_ value: String) -> Date? {
        if let date = dotFormatter.date(from: value) { return date }
        if let date = iso.date(from: value) { return date }
        if let date = isoNoFraction.date(from: value) { return date }
        if let date = fallbackLongFractionFormatter.date(from: value) { return date }
        if let date = fallbackFractionFormatter.date(from: value) { return date }
        if let date = fallbackFormatter.date(from: value) { return date }
        if let date = fallbackSpaceFormatter.date(from: value) { return date }
        return nil
    }
}
