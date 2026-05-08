import Foundation
import Combine

@MainActor
final class MyPageViewModel: ObservableObject {
    @Published var profile: MypageResult?
    @Published var isLoading = false
    @Published var isGroupExpanded = true

    private let userService: UserService

    init(userService: UserService) {
        self.userService = userService
    }

    func loadProfile() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await userService.getMypage()
            self.profile = result
        } catch {
            print("프로필 로드 실패: \(error)")
        }
    }

    func toggleGroupSection() {
        isGroupExpanded.toggle()
    }

    /// 받은 후기: 서버에 안 온 배지는 0으로 보충해서 8종 모두 노출.
    var reviewBadges: [ReviewBadgeItem] {
        let counts = Dictionary(
            uniqueKeysWithValues: (profile?.userBadges ?? []).map { ($0.userBadge, $0.count) }
        )
        return BadgeKind.allCases.map {
            ReviewBadgeItem(kind: $0, count: counts[$0.rawValue] ?? 0)
        }
    }

    var topTags: [String] {
        profile?.topTags ?? []
    }

    var completeBook: Int { profile?.completeBook ?? 0 }
    var relayGroup: Int { profile?.relayGroup ?? 0 }
    var togetherGroup: Int { profile?.togetherGroup ?? 0 }
    var manner: Double { profile?.manner ?? 36.5 }

    var groups: [MypageGroup] { profile?.groups ?? [] }
    var recentBooks: [MypageBook] { profile?.books ?? [] }
}

// MARK: - 배지 종류 (서버 Badge enum과 매핑)

enum BadgeKind: String, CaseIterable {
    case kindness = "KINDNESS"
    case goodHandwriting = "GOOD_HANDWRITING"
    case sweetComment = "SWEET_COMMENT"
    case insightful = "INSIGHTFUL"
    case fastShipping = "FAST_SHIPPING"
    case funny = "FUNNY"
    case cleanCondition = "CLEAN_CONDITION"
    case punctual = "PUNCTUAL"

    var label: String {
        switch self {
        case .kindness:        return "친절하고 매너가 좋아요"
        case .goodHandwriting: return "글씨가 예뻐요"
        case .sweetComment:    return "코멘트가 다정해요"
        case .insightful:      return "책에 대한 인사이트가 넘쳐요"
        case .fastShipping:    return "책을 빠르게 보내줬어요"
        case .funny:           return "코멘트가 재미있어요"
        case .cleanCondition:  return "책을 깨끗하고 깔끔하게 읽어요"
        case .punctual:        return "약속을 잘 지켜요"
        }
    }
}

struct ReviewBadgeItem: Identifiable, Equatable {
    let kind: BadgeKind
    let count: Int

    var id: String { kind.rawValue }
    var label: String { kind.label }
}
