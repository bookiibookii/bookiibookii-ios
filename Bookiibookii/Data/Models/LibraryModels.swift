import Foundation

struct LibraryBookResponseDTO: Decodable {
    let userBookId: Int?
    let groupId: Int?
    let bookId: Int?
    let bookTitle: String?
    let bookImage: String?
    let hostNickname: String?
    let hostNickName: String?
    let hostId: Int?
    let hostProfileImageUrl: String?
    let groupType: String?
    let author: String?
    let startDate: String?
    let endDate: String?
    let duration: Int?
    let groupStatus: String?
    let rating: Double?
    let comment: String?
    /// 함께읽기: 서재 책 목록 응답에 포함될 때만 (스펙별 키 별칭은 디코더에서 처리).
    let myReadingRate: Int?
    let groupReadingRate: Int?
    let togetherReadingCompletedAt: String?

    private enum CodingKeys: String, CodingKey {
        case userBookId
        case groupId
        case bookId
        case bookTitle
        case title
        case bookImage
        case image
        case bookImageUrl
        case imageUrl
        case hostNickname
        case hostNickName
        case hostId
        case hostProfileImageUrl
        case groupType
        case nickname
        case author
        case startDate
        case endDate
        case duration
        case groupStatus
        case rating
        case comment
        case myReadingRate
        case groupReadingRate
        case togetherReadingCompletedAt
        case readingCompletedAt
        case myTogetherReadingCompletedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userBookId = try container.decodeIfPresent(Int.self, forKey: .userBookId)
        groupId = try container.decodeIfPresent(Int.self, forKey: .groupId)
        bookId = try container.decodeIfPresent(Int.self, forKey: .bookId)
        bookTitle =
            try container.decodeIfPresent(String.self, forKey: .bookTitle)
            ?? container.decodeIfPresent(String.self, forKey: .title)
        bookImage =
            try container.decodeIfPresent(String.self, forKey: .bookImage)
            ?? container.decodeIfPresent(String.self, forKey: .image)
            ?? container.decodeIfPresent(String.self, forKey: .bookImageUrl)
            ?? container.decodeIfPresent(String.self, forKey: .imageUrl)
        hostNickname =
            try container.decodeIfPresent(String.self, forKey: .hostNickname)
            ?? container.decodeIfPresent(String.self, forKey: .hostNickName)
            ?? container.decodeIfPresent(String.self, forKey: .nickname)
        hostNickName = try container.decodeIfPresent(String.self, forKey: .hostNickName)
        hostId = try container.decodeIfPresent(Int.self, forKey: .hostId)
        hostProfileImageUrl = try container.decodeIfPresent(String.self, forKey: .hostProfileImageUrl)
        groupType = try container.decodeIfPresent(String.self, forKey: .groupType)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        startDate = try container.decodeIfPresent(String.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(String.self, forKey: .endDate)
        duration = try container.decodeIfPresent(Int.self, forKey: .duration)
        groupStatus = try container.decodeIfPresent(String.self, forKey: .groupStatus)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        myReadingRate = try container.decodeIfPresent(Int.self, forKey: .myReadingRate)
        groupReadingRate = try container.decodeIfPresent(Int.self, forKey: .groupReadingRate)
        togetherReadingCompletedAt =
            try container.decodeIfPresent(String.self, forKey: .togetherReadingCompletedAt)
            ?? (try container.decodeIfPresent(String.self, forKey: .readingCompletedAt))
            ?? (try container.decodeIfPresent(String.self, forKey: .myTogetherReadingCompletedAt))
    }
}

struct LibraryBooksResultDTO: Decodable {
    let books: [LibraryBookResponseDTO]?
    let libraryBooks: [LibraryBookResponseDTO]?
    let content: [LibraryBookResponseDTO]?

    func resolveBooks() -> [LibraryBookResponseDTO] {
        books ?? libraryBooks ?? content ?? []
    }
}

struct LibraryBook: Identifiable, Equatable, Hashable {
    let id: Int
    /// 독서카드 생성 등 `/api/cards/{userBookId}` 에 사용. 서버 미전달 시 `nil`.
    let userBookId: Int?
    let groupId: Int
    /// `/api/library/books` 의 `groupType` (예: `RELAY`, `TOGETHER`).
    let groupType: String?
    let title: String
    let author: String?
    let coverImageURL: String?
    let hostNickname: String
    let startDate: String?
    let endDate: String?
    let status: LibraryGroupStatus
    let rating: Double?
    let isCreatedByMe: Bool
    /// 함께읽기: `GET /api/library/books`(및 검색)에서만 채워짐.
    let togetherMyReadingRate: Int?
    let togetherGroupReadingRate: Int?
    let togetherReadingCompletedAtISO: String?
}

enum LibraryGroupStatus: Equatable, Hashable {
    case matched
    case completed
    case deleted
    case unknown(String)

    init(rawValue: String?) {
        switch (rawValue ?? "").lowercased() {
        case "matched":
            self = .matched
        case "completed":
            self = .completed
        case "deleted":
            self = .deleted
        default:
            self = .unknown(rawValue ?? "")
        }
    }

    var badgeText: String {
        switch self {
        case .matched: return "진행 중"
        case .completed: return "종료"
        case .deleted: return "-"
        case .unknown: return "-"
        }
    }
}

// MARK: - 교환독서 후기 (POST /api/reviews/relay/{userBookId})

struct RelayReviewRequestBody: Encodable {
    let bookRating: Double      // 0.5 단위
    let bookComment: String
    let partnerRating: Double   // 0.5 단위
    let partnerComment: String
    let badgeCodes: [String]
}

extension LibraryBookResponseDTO {
    func toDomain() -> LibraryBook {
        let currentUserId = TokenManager.shared.userId
        let createdByMe = (hostId != nil && currentUserId != nil) ? (hostId == currentUserId) : false

        return LibraryBook(
            id: userBookId ?? groupId ?? Int.random(in: 100_000...999_999),
            userBookId: userBookId,
            groupId: groupId ?? 0,
            groupType: groupType,
            title: bookTitle ?? "-",
            author: author,
            coverImageURL: bookImage,
            hostNickname: hostNickname ?? hostNickName ?? "-",
            startDate: startDate,
            endDate: endDate,
            status: LibraryGroupStatus(rawValue: groupStatus),
            rating: rating,
            isCreatedByMe: createdByMe,
            togetherMyReadingRate: myReadingRate,
            togetherGroupReadingRate: groupReadingRate,
            togetherReadingCompletedAtISO: togetherReadingCompletedAt
        )
    }
}
