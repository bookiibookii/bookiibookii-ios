import Foundation

// 안드 tracker/ui/detail/component/TrackerStepList.kt의 단계 모델부.
enum TrackerStepStatus: Equatable {
    case completed
    case inProgress(chipText: String)
}

struct TrackerStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let status: TrackerStepStatus
}
