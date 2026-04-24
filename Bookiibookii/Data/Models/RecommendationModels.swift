import Foundation

// 안드로이드 RecommendationMoel.kt 대응. /api/recommendations/groups 응답.
struct RecommendedGroupDto: Decodable, Identifiable, Equatable {
    let groupId: Int
    let bookTitle: String?
    let bookImageUrl: String?

    var id: Int { groupId }

    var displayTitle: String { bookTitle ?? "제목 없음" }
}

// /api/recommendations/bookmates 응답.
struct RecommendedBookmateDto: Decodable, Identifiable, Equatable {
    let userId: Int
    let nickname: String
    let profileImageUrl: String?
    let matchedTags: [String]?
    let recentBookTitle: String?

    var id: Int { userId }

    var displayRecentBook: String { recentBookTitle ?? "최근 완독한 책이 없어요" }
}
