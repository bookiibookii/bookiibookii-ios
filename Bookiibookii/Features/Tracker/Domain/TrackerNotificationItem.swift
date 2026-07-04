import Foundation

// 안드 tracker/model/TrackerNotificationItem.kt 대응 (상단 배너 표시 모델).
struct TrackerNotificationItem: Identifiable {
    let id = UUID()
    let groupId: Int
    let dDay: String
    let template: String
    let nickname: String
    let bookTitle: String
    let remainingSeconds: Int
    let subText: String
}
