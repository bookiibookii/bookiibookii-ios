import Foundation

/// 안드 DirectHost/DirectGuest Activity 의 isMeetingPassed / parseMeetingInstant 대응.
/// SHIPPING_TO_GUEST · SHIPPING_TO_HOST 시 약속 시간 경과 여부로 sheet 분기.
enum DirectMeetingClock {
    static func isPassed(_ meetingTime: String?, now: Date = Date()) -> Bool {
        guard let date = parse(meetingTime) else { return false }
        return date < now
    }

    /// 안드 parseMeetingInstant 와 동일 우선순위:
    /// 1) ISO 8601 with offset (OffsetDateTime)
    /// 2) ISO_LOCAL_DATE_TIME → KST(Asia/Seoul)
    /// 3) "uuuu.MM.dd.HH:mm" → KST
    static func parse(_ raw: String?) -> Date? {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }

        if let date = isoOffsetFormatter.date(from: raw) { return date }
        if let date = isoLocalDateTimeKST.date(from: raw) { return date }
        if let date = dotPatternKST.date(from: raw) { return date }
        return nil
    }

    private static let kstTimeZone: TimeZone = TimeZone(identifier: "Asia/Seoul") ?? .current

    private static let isoOffsetFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoLocalDateTimeKST: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = kstTimeZone
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f
    }()

    private static let dotPatternKST: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = kstTimeZone
        f.dateFormat = "yyyy.MM.dd.HH:mm"
        return f
    }()
}
