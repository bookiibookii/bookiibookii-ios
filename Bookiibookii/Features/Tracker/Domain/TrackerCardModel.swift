import Foundation

// 안드 tracker/model/TrackerCardModel.kt 대응.
struct TrackerProfileItem {
    var nickname: String
    var bookTitle: String
    var bookCoverUrl: String?
    var profileImageUrl: String?
    var progressPercent: Int
    var isOwnerBook: Bool
    var totalPages: Int = 0
    // 진행률 텍스트를 "%" 대신 다른 라벨로 표시할 때 사용
    var progressLabelOverride: String? = nil
}

struct TrackerCardModel: Identifiable {
    let groupId: Int
    let groupName: String
    // 헤더 "제목 · 상태" 표시용
    let displayBookTitle: String
    let bookTitle: String
    let progressLabel: String
    let dDay: String
    let left: TrackerProfileItem
    let right: TrackerProfileItem
    var primaryAction: TrackerAction = .none
    var secondaryAction: TrackerAction = .none
    var primaryEnabled: Bool = true
    var secondaryEnabled: Bool = true
    var showReadingProgress: Bool = true
    var isHost: Bool = false

    var id: Int { groupId }
}
