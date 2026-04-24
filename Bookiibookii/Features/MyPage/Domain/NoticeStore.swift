import Foundation

struct NoticeItem: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let content: String
    let createdAt: Date
    let isUnread: Bool

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

    private static let detailFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy. MM. dd. HH:mm"
        return formatter
    }()
}

protocol NoticeStore {
    func fetchNotices() async throws -> [NoticeItem]
}

actor LocalNoticeStore: NoticeStore {
    static let shared = LocalNoticeStore()
    private let key = "mypage_notice_items_v1"

    func fetchNotices() async throws -> [NoticeItem] {
        if let cached = loadFromDisk() {
            return cached.sorted(by: { $0.createdAt > $1.createdAt })
        }

        let seeded = seedItems()
        saveToDisk(seeded)
        return seeded
    }

    private func loadFromDisk() -> [NoticeItem]? {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([NoticeItem].self, from: data)
        else { return nil }
        return decoded
    }

    private func saveToDisk(_ notices: [NoticeItem]) {
        guard let data = try? JSONEncoder().encode(notices) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func seedItems() -> [NoticeItem] {
        let now = Date()
        return [
            NoticeItem(
                id: UUID().uuidString,
                title: "12월 업데이트 안내",
                content: "새로운 기능이 추가되었습니다! 독서 카드 꾸미기 기능을 확인해보세요.",
                createdAt: now.addingTimeInterval(-5 * 60),
                isUnread: true
            ),
            NoticeItem(
                id: UUID().uuidString,
                title: "베스트 부키 메이트 시스템 오픈",
                content: "이번 달부터 베스트 부키 메이트 랭킹을 확인할 수 있어요.",
                createdAt: now.addingTimeInterval(-15 * 60),
                isUnread: true
            ),
            NoticeItem(
                id: UUID().uuidString,
                title: "서비스 점검 완료 안내",
                content: "11월 25일 새벽 2시~4시 진행된 서비스 점검이 완료되었습니다.",
                createdAt: now.addingTimeInterval(-30 * 60),
                isUnread: false
            )
        ]
    }
}
