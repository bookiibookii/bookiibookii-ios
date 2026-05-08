import Foundation

struct NoticeItem: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let summary: String
    let createdAt: Date

    var relativeDateText: String {
        let seconds = max(0, Int(Date().timeIntervalSince(createdAt)))
        let minutes = seconds / 60
        if minutes < 1 { return "방금 전" }
        if minutes < 60 { return "\(minutes)분 전" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)시간 전" }
        let days = hours / 24
        return "\(days)일 전"
    }

    var detailDateText: String {
        Self.detailFormatter.string(from: createdAt)
    }

    static let detailFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy. MM. dd. HH:mm"
        return formatter
    }()
}

struct NoticeDetailItem: Equatable {
    let id: Int
    let title: String
    let content: String
    let createdAt: Date

    var detailDateText: String {
        NoticeItem.detailFormatter.string(from: createdAt)
    }
}

extension NoticeItem {
    init(dto: NoticeListItemDto) {
        self.id = dto.id
        self.title = dto.title
        self.summary = dto.summary
        self.createdAt = dto.createdAt
    }
}

extension NoticeDetailItem {
    init(dto: NoticeDetailDto) {
        self.id = dto.id
        self.title = dto.title
        self.content = dto.content
        self.createdAt = dto.createdAt
    }
}
