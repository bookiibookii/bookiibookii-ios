import Foundation

/// 안드로이드 trkHost.TrackerDateUtil 대응.
/// 서버의 "yyyy-MM-dd[Thh:mm:ss...]" raw 문자열을 "yyyy.MM.dd" 표시 포맷으로 변환.
enum TrackerDateFormatter {
    private static let parser: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        return f
    }()

    private static let output: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        return f
    }()

    /// raw → "yyyy.MM.dd". 파싱 실패 시 "미정".
    static func prettyDate(_ raw: String?) -> String {
        guard let raw, raw.count >= 10,
              let date = parser.date(from: String(raw.prefix(10))) else {
            return "미정"
        }
        return output.string(from: date)
    }

    /// endDate raw에 days를 더한 결과를 "yyyy.MM.dd" 포맷으로 반환.
    /// 음수 days는 0으로 클램프. 파싱 실패 시 "미정".
    static func extendedEndDateText(endRaw: String?, days: Int) -> String {
        guard let endRaw, endRaw.count >= 10,
              let base = parser.date(from: String(endRaw.prefix(10))) else {
            return "미정"
        }
        let safeDays = max(0, days)
        let extended = Calendar.current.date(byAdding: .day, value: safeDays, to: base) ?? base
        return output.string(from: extended)
    }
}
