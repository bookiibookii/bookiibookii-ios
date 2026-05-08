import Foundation

struct InquiryCreateRequestDto: Encodable {
    let title: String
    let content: String
}

struct InquiryListItemDto: Decodable, Equatable, Identifiable {
    let inquiryId: Int
    let userId: Int
    let nickname: String
    let createdAt: Date
    let title: String
    let content: String
    let supportStatus: String
    let adminReply: String?
    let resolvedAt: Date?

    var id: Int { inquiryId }

    enum CodingKeys: String, CodingKey {
        case inquiryId, userId, nickname, createdAt, title, content, supportStatus, adminReply, resolvedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        inquiryId = try Self.decodeInt(container, key: .inquiryId)
        userId = try Self.decodeInt(container, key: .userId)
        nickname = try container.decode(String.self, forKey: .nickname)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        supportStatus = try container.decode(String.self, forKey: .supportStatus)
        adminReply = try? container.decodeIfPresent(String.self, forKey: .adminReply)
        createdAt = Self.decodeDateSafely(container, key: .createdAt)
        resolvedAt = Self.decodeOptionalDateSafely(container, key: .resolvedAt)
    }
}

private extension InquiryListItemDto {
    static func decodeInt(_ container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) throws -> Int {
        if let value = try? container.decode(Int.self, forKey: key) { return value }
        let value = try container.decode(Int64.self, forKey: key)
        return Int(value)
    }

    static func decodeDateSafely(_ container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Date {
        if let value = try? container.decode(String.self, forKey: key),
           let parsed = InquiryDateParser.parse(value) {
            return parsed
        }
        if let array = try? container.decode([Int].self, forKey: key),
           let parsed = InquiryDateParser.parse(array: array) {
            return parsed
        }
        if let object = try? container.decode(InquiryDateObject.self, forKey: key),
           let parsed = InquiryDateParser.parse(object: object) {
            return parsed
        }
        return Date()
    }

    static func decodeOptionalDateSafely(_ container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Date? {
        if (try? container.decodeNil(forKey: key)) == true { return nil }
        if let value = try? container.decode(String.self, forKey: key) {
            return InquiryDateParser.parse(value)
        }
        if let array = try? container.decode([Int].self, forKey: key) {
            return InquiryDateParser.parse(array: array)
        }
        if let object = try? container.decode(InquiryDateObject.self, forKey: key) {
            return InquiryDateParser.parse(object: object)
        }
        return nil
    }
}

private struct InquiryDateObject: Decodable {
    let year: Int
    let monthValue: Int?
    let month: String?
    let dayOfMonth: Int
    let hour: Int
    let minute: Int
    let second: Int
    let nano: Int
}

private enum InquiryDateParser {
    static func parse(_ value: String) -> Date? {
        if let date = dotFormatter.date(from: value) { return date }
        if let date = iso.date(from: value) { return date }
        if let date = isoNoFraction.date(from: value) { return date }
        if let date = fallbackSpace.date(from: value) { return date }
        if let date = fallbackT.date(from: value) { return date }
        return nil
    }

    static func parse(array: [Int]) -> Date? {
        guard array.count >= 5 else { return nil }
        let month = array[1]
        return makeDate(
            year: array[0],
            month: month,
            day: array[2],
            hour: array[3],
            minute: array[4],
            second: array.count > 5 ? array[5] : 0,
            nano: array.count > 6 ? array[6] : 0
        )
    }

    static func parse(object: InquiryDateObject) -> Date? {
        let monthNumber: Int? = {
            if let monthValue = object.monthValue { return monthValue }
            if let month = object.month?.uppercased() {
                return monthNameToNumber[month]
            }
            return nil
        }()
        guard let monthNumber else { return nil }
        return makeDate(
            year: object.year,
            month: monthNumber,
            day: object.dayOfMonth,
            hour: object.hour,
            minute: object.minute,
            second: object.second,
            nano: object.nano
        )
    }

    private static func makeDate(
        year: Int, month: Int, day: Int,
        hour: Int, minute: Int, second: Int, nano: Int
    ) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        components.nanosecond = nano
        components.timeZone = TimeZone(identifier: "Asia/Seoul")
        return Calendar(identifier: .gregorian).date(from: components)
    }

    private static let dotFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()

    private static let iso: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoNoFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let fallbackSpace: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    private static let fallbackT: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    private static let monthNameToNumber: [String: Int] = [
        "JANUARY": 1, "FEBRUARY": 2, "MARCH": 3, "APRIL": 4,
        "MAY": 5, "JUNE": 6, "JULY": 7, "AUGUST": 8,
        "SEPTEMBER": 9, "OCTOBER": 10, "NOVEMBER": 11, "DECEMBER": 12
    ]
}
