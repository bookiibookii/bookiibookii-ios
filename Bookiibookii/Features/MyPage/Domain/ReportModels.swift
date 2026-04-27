import Foundation

enum ReportReason: CaseIterable {
    case abusiveLanguage
    case spam
    case noShow
    case bookDamage
    case etc

    var displayText: String {
        switch self {
        case .abusiveLanguage: return "욕설/비방"
        case .spam: return "스팸/광고"
        case .noShow: return "책 미발송/노쇼/연락두절"
        case .bookDamage: return "책 파손/낙서"
        case .etc: return "기타"
        }
    }
}

struct ReportGroup: Identifiable {
    let id: UUID
    let hostName: String
    let bookTitle: String
    let isMyGroup: Bool
    let members: [ReportMember]

    var displayTitle: String {
        "[\(hostName)] \(bookTitle)"
    }

    static let preview: [ReportGroup] = [
        ReportGroup(
            id: UUID(),
            hostName: "noshel",
            bookTitle: "참을 수 없는 존재의 가벼움",
            isMyGroup: true,
            members: [
                ReportMember(id: UUID(), name: "noshel"),
                ReportMember(id: UUID(), name: "mimi")
            ]
        ),
        ReportGroup(
            id: UUID(),
            hostName: "pooh",
            bookTitle: "괴테는 모든 것을 말했다",
            isMyGroup: false,
            members: [
                ReportMember(id: UUID(), name: "pooh"),
                ReportMember(id: UUID(), name: "alfred")
            ]
        )
    ]
}

struct ReportMember: Identifiable {
    let id: UUID
    let name: String
}

struct ReportSubmitDraft {
    let groupTitle: String
    let reason: ReportReason
    let content: String
}
