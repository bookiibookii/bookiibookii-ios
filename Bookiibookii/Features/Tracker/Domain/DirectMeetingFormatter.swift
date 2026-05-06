import Foundation

/// 직접교환 약속 시간 표시용 포맷터.
/// 서버의 ISO 또는 "yyyy.MM.dd.HH:mm" raw 문자열을 사람이 읽는 형태로 변환.
enum DirectMeetingFormatter {
    /// raw → "M월 d일 HH:mm " (안드 appointmentEdit/Status 시트 상단 큰 제목용).
    /// 파싱 실패 시 "미정 " (뒤 공백 포함 — 안드 시각/내용 분리 텍스트와 합쳐질 때 자연스럽도록).
    static func titleDateTime(_ raw: String?) -> String {
        guard let date = DirectMeetingClock.parse(raw) else { return "미정 " }
        return titleFormatter.string(from: date)
    }

    /// raw → "yyyy. MM. dd. HH:mm " (안드 약속 카드 datetime 영역).
    static func cardDateTime(_ raw: String?) -> String {
        guard let date = DirectMeetingClock.parse(raw) else { return "미정 " }
        return cardFormatter.string(from: date)
    }

    /// 폼 입력 표시용 "yyyy. MM. dd. HH:mm" (set/edit 다이얼로그).
    static func formDateTime(_ raw: String?) -> String {
        guard let date = DirectMeetingClock.parse(raw) else { return "" }
        return formFormatter.string(from: date)
    }

    private static let kstTimeZone: TimeZone = TimeZone(identifier: "Asia/Seoul") ?? .current

    private static let titleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = kstTimeZone
        f.dateFormat = "M월 d일 HH:mm "
        return f
    }()

    private static let cardFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = kstTimeZone
        f.dateFormat = "yyyy. MM. dd. HH:mm "
        return f
    }()

    private static let formFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = kstTimeZone
        f.dateFormat = "yyyy. MM. dd. HH:mm"
        return f
    }()
}
