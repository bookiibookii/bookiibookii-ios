import Foundation

// 안드로이드 TimeAgoFormatter.kt 포팅. ISO8601/LocalDateTime createdAt → "방금 전"/"N분 전"/"N시간 전"/"N일 전"/yyyy.MM.dd
enum TimeAgoFormatter {
    // ISO8601 (timezone 있는 케이스)
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

    /// LocalDateTime 스타일(타임존 없음). Spring Boot Jackson 기본 출력을 전부 커버.
    private static let localPatterns: [String] = [
        "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSSS",
        "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
        "yyyy-MM-dd'T'HH:mm:ss.SSS",
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd HH:mm:ss"
    ]

    private static let localFormatters: [DateFormatter] = localPatterns.map { pattern in
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        // 서버가 UTC LocalDateTime(타임존 표기 없음)을 내려주므로 UTC로 해석.
        // 표시용 displayFormatter는 시스템 기본(KST) 사용 → 자동으로 현지 날짜가 됨.
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = pattern
        return f
    }

    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy.MM.dd"
        return f
    }()

    static func format(_ createdAt: String?, now: Date = Date()) -> String {
        guard let createdAt, !createdAt.isEmpty else { return "" }
        guard let date = parse(createdAt) else {
            #if DEBUG
            print("[TimeAgoFormatter] parse failed:", createdAt)
            #endif
            return createdAt
        }

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
        for f in localFormatters {
            if let d = f.date(from: raw) { return d }
        }
        return nil
    }
}
