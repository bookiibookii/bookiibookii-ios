import Foundation

struct LibraryBookResponseDTO: Decodable {
    let userBookId: Int?
    let memberBookId: Int?
    let groupId: Int?
    let groupName: String?
    let bookId: Int?
    let bookTitle: String?
    let bookImage: String?
    let hostNickname: String?
    let hostNickName: String?
    let hostId: Int?
    let hostProfileImageUrl: String?
    let groupType: String?
    let author: String?
    let genre: String?
    let totalPages: Int?
    let startDate: String?
    let endDate: String?
    let duration: Int?
    let groupStatus: String?
    let rating: Double?
    let comment: String?
    let isMine: Bool?
    let progressRate: Int?
    let completedAt: String?
    /// 함께읽기: 서재 책 목록 응답에 포함될 때만 (스펙별 키 별칭은 디코더에서 처리).
    let myReadingRate: Int?
    let groupReadingRate: Int?
    let togetherReadingCompletedAt: String?

    private enum CodingKeys: String, CodingKey {
        case userBookId
        case memberBookId
        case groupId
        case groupName
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
        case genre
        case totalPages
        case startDate
        case endDate
        case duration
        case groupStatus
        case rating
        case comment
        case isMine
        case progressRate
        case completedAt
        case myReadingRate
        case groupReadingRate
        case togetherReadingCompletedAt
        case readingCompletedAt
        case myTogetherReadingCompletedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userBookId = try container.decodeIfPresent(Int.self, forKey: .userBookId)
        memberBookId = try container.decodeIfPresent(Int.self, forKey: .memberBookId)
        groupId = try container.decodeIfPresent(Int.self, forKey: .groupId)
        groupName = try container.decodeIfPresent(String.self, forKey: .groupName)
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
        genre = try container.decodeIfPresent(String.self, forKey: .genre)
        totalPages = try container.decodeIfPresent(Int.self, forKey: .totalPages)
        startDate = try container.decodeIfPresent(String.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(String.self, forKey: .endDate)
        duration = try container.decodeIfPresent(Int.self, forKey: .duration)
        groupStatus = try container.decodeIfPresent(String.self, forKey: .groupStatus)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        isMine = try container.decodeIfPresent(Bool.self, forKey: .isMine)
        progressRate = try container.decodeIfPresent(Int.self, forKey: .progressRate)
        completedAt = try container.decodeIfPresent(String.self, forKey: .completedAt)
        myReadingRate =
            try container.decodeIfPresent(Int.self, forKey: .myReadingRate)
            ?? container.decodeIfPresent(Int.self, forKey: .progressRate)
        groupReadingRate = try container.decodeIfPresent(Int.self, forKey: .groupReadingRate)
        togetherReadingCompletedAt =
            try container.decodeIfPresent(String.self, forKey: .togetherReadingCompletedAt)
            ?? (try container.decodeIfPresent(String.self, forKey: .readingCompletedAt))
            ?? (try container.decodeIfPresent(String.self, forKey: .myTogetherReadingCompletedAt))
            ?? (try container.decodeIfPresent(String.self, forKey: .completedAt))
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
    let bookId: Int?
    /// 독서카드 생성 등 `/api/cards/{userBookId}` 에 사용. 서버 미전달 시 `nil`.
    let userBookId: Int?
    let groupId: Int
    let groupName: String
    /// `/api/library/memberbooks` 의 `groupType` (예: `RELAY`, `TOGETHER`).
    let groupType: String?
    let title: String
    let author: String?
    let genre: String?
    let totalPages: Int?
    let coverImageURL: String?
    let hostNickname: String
    let startDate: String?
    let endDate: String?
    let status: LibraryGroupStatus
    let rating: Double?
    let isCreatedByMe: Bool
    let isMyOriginalBook: Bool
    var progressRate: Int
    let completedAtISO: String?
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

extension LibraryBookResponseDTO {
    func toDomain() -> LibraryBook {
        let currentUserId = TokenManager.shared.userId
        let createdByMe = (hostId != nil && currentUserId != nil) ? (hostId == currentUserId) : false

        return LibraryBook(
            id: memberBookId ?? userBookId ?? groupId ?? Int.random(in: 100_000...999_999),
            bookId: bookId,
            userBookId: memberBookId ?? userBookId,
            groupId: groupId ?? 0,
            groupName: groupName ?? "-",
            groupType: groupType,
            title: bookTitle ?? "-",
            author: author,
            genre: genre,
            totalPages: totalPages,
            coverImageURL: bookImage,
            hostNickname: hostNickname ?? hostNickName ?? "-",
            startDate: startDate,
            endDate: endDate,
            status: LibraryGroupStatus(rawValue: groupStatus),
            rating: rating,
            isCreatedByMe: createdByMe,
            isMyOriginalBook: isMine ?? false,
            progressRate: min(max(progressRate ?? myReadingRate ?? 0, 0), 100),
            completedAtISO: completedAt
        )
    }
}

// MARK: - 완료 그룹 후기 (GET /api/groups/{groupId}/reviews)

struct LibraryGroupReviewsResponseDTO: Decodable {
    let bookReviews: [LibraryGroupBookReviewDTO]?
    let memberReviews: [LibraryGroupMemberReviewDTO]?
}

struct LibraryGroupBookReviewDTO: Decodable, Identifiable {
    let reviewId: Int?
    let bookId: Int?
    let bookTitle: String?
    let bookAuthor: String?
    let bookImageUrl: String?
    let writerId: Int?
    let writerNickname: String?
    let writerProfileImageUrl: String?
    let rating: Double?
    let content: String?
    let createdAt: String?

    var id: Int { reviewId ?? hashValue }

    private var hashValue: Int {
        var hasher = Hasher()
        hasher.combine(bookId)
        hasher.combine(writerId)
        hasher.combine(createdAt)
        return hasher.finalize()
    }
}

struct LibraryGroupMemberReviewDTO: Decodable, Identifiable {
    let reviewId: Int?
    let writerId: Int?
    let writerNickname: String?
    let writerProfileImageUrl: String?
    let reaction: String?
    let content: String?
    let createdAt: String?

    var id: Int { reviewId ?? hashValue }

    enum CodingKeys: String, CodingKey {
        case reviewId, writerId, writerNickname, writerProfileImageUrl
        case reaction, content, comment, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reviewId = try container.decodeIfPresent(Int.self, forKey: .reviewId)
        writerId = try container.decodeIfPresent(Int.self, forKey: .writerId)
        writerNickname = try container.decodeIfPresent(String.self, forKey: .writerNickname)
        writerProfileImageUrl = try container.decodeIfPresent(String.self, forKey: .writerProfileImageUrl)
        reaction = try container.decodeIfPresent(String.self, forKey: .reaction)
        content = try container.decodeIfPresent(String.self, forKey: .content)
            ?? container.decodeIfPresent(String.self, forKey: .comment)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
    }

    private var hashValue: Int {
        var hasher = Hasher()
        hasher.combine(writerId)
        hasher.combine(createdAt)
        return hasher.finalize()
    }
}
