import Foundation

// 안드로이드 TimeAgoFormatter.kt 포팅. ISO8601 createdAt → "5분 전" / "3시간 전" / "yyyy.MM.dd".
enum TimeAgoFormatter {
    private static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoNoFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let fallbackFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f
    }()

    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy.MM.dd"
        return f
    }()

    static func format(_ createdAt: String?, now: Date = Date()) -> String {
        guard let createdAt, !createdAt.isEmpty else { return "" }
        guard let date = parse(createdAt) else { return createdAt }

        let seconds = max(0, Int(now.timeIntervalSince(date)))
        let minutes = seconds / 60
        let hours = seconds / 3600
        let days = seconds / 86400

        switch true {
        case minutes < 1: return "방금 전"
        case minutes < 60: return "\(minutes)분 전"
        case hours < 24: return "\(hours)시간 전"
        case days < 7: return "\(days)일 전"
        default: return displayFormatter.string(from: date)
        }
    }

    private static func parse(_ raw: String) -> Date? {
        if let d = iso.date(from: raw) { return d }
        if let d = isoNoFraction.date(from: raw) { return d }
        return fallbackFormatter.date(from: raw)
    }
}
