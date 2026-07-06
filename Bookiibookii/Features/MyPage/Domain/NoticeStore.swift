import Foundation

struct NoticeItem: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let summary: String
    let createdAt: Date
    let authorNickname: String?
    let authorProfileImageUrl: String?
    let isNew: Bool

    var listDateText: String {
        let seconds = max(0, Int(Date().timeIntervalSince(createdAt)))
        let minutes = seconds / 60
        let hours = seconds / 3600
        let days = seconds / 86400

        if days >= 7 {
            return Self.listAbsoluteDateFormatter.string(from: createdAt)
        }
        if minutes < 1 { return "방금 전" }
        if minutes < 60 { return "\(minutes)분 전" }
        if hours < 24 { return "\(hours)시간 전" }
        return "\(days)일 전"
    }

    var showsAuthorMeta: Bool {
        guard let authorNickname, !authorNickname.isEmpty else { return false }
        return true
    }

    private static let listAbsoluteDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy. MM. dd."
        return formatter
    }()

    static let detailDateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy. MM. dd."
        return formatter
    }()

    static let detailTimeOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

struct NoticeDetailItem: Equatable {
    let id: Int
    let title: String
    let content: String
    let createdAt: Date
    let authorNickname: String?
    let authorProfileImageUrl: String?

    var detailDateOnlyText: String {
        NoticeItem.detailDateOnlyFormatter.string(from: createdAt)
    }

    var detailTimeOnlyText: String {
        NoticeItem.detailTimeOnlyFormatter.string(from: createdAt)
    }

    var showsAuthorMeta: Bool {
        guard let authorNickname, !authorNickname.isEmpty else { return false }
        return true
    }
}

extension NoticeItem {
    init(dto: NoticeListItemDto) {
        self.id = dto.id
        self.title = dto.title
        self.summary = dto.summary
        self.createdAt = dto.createdAt
        self.authorNickname = dto.authorNickname
        self.authorProfileImageUrl = dto.authorProfileImageUrl
        self.isNew = dto.isNew ?? false
    }
}

extension NoticeDetailItem {
    init(dto: NoticeDetailDto) {
        self.id = dto.id
        self.title = dto.title
        self.content = dto.content
        self.createdAt = dto.createdAt
        self.authorNickname = dto.authorNickname
        self.authorProfileImageUrl = dto.authorProfileImageUrl
    }
}
