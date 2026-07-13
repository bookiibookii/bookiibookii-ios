import Foundation

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
