import Foundation

// 공용 날짜 유틸(안드 common.DateUtils 대응). 현재는 약속(meeting) 관련 변환만 제공.
enum DateUtils {
    private static let kst = TimeZone(identifier: "Asia/Seoul") ?? .current

    // 오프셋(+09:00)·UTC(Z) 모두 파싱
    private static func parseDate(_ iso: String?) -> Date? {
        guard let iso, !iso.isEmpty else { return nil }
        let withFrac = ISO8601DateFormatter()
        withFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = withFrac.date(from: iso) { return d }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: iso)
    }

    // KST 선택값 → +09:00 오프셋 ISO (예: 2026-05-20T14:30:00+09:00)
    static func meetingAtFromKst(year: Int, month: Int, day: Int, hour24: Int, minute: Int) -> String {
        String(format: "%04d-%02d-%02dT%02d:%02d:00+09:00", year, month, day, hour24, minute)
    }

    // 서버 시각 → KST "yyyy. MM. dd. HH:mm" (파싱 실패 시 원본 그대로)
    static func formatKstDateTime(_ iso: String?) -> String {
        guard let iso else { return "" }
        guard let date = parseDate(iso) else { return iso }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = kst
        f.dateFormat = "yyyy. MM. dd. HH:mm"
        return f.string(from: date)
    }

    // 기존 일시 → KST 캘린더 구성요소(수정 진입 프리필용)
    static func parseKstDateTime(_ iso: String?) -> DateComponents? {
        guard let date = parseDate(iso) else { return nil }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = kst
        return cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    }

    // 현재 기준 약속까지 12시간 이상 남았는지(파싱 실패 시 false)
    static func isMeetingEditable(_ iso: String?) -> Bool {
        guard let date = parseDate(iso) else { return false }
        return date.timeIntervalSinceNow >= 12 * 60 * 60
    }
}
