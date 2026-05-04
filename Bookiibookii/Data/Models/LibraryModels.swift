import Foundation

struct LibraryBookResponseDTO: Decodable {
    let userBookId: Int?
    let groupId: Int?
    let bookTitle: String?
    let bookImage: String?
    let hostNickname: String?
    let hostNickName: String?
    let author: String?
    let startDate: String?
    let endDate: String?
    let groupStatus: String?
    let rating: Double?

    private enum CodingKeys: String, CodingKey {
        case userBookId
        case groupId
        case bookTitle
        case title
        case bookImage
        case image
        case bookImageUrl
        case imageUrl
        case hostNickname
        case hostNickName
        case nickname
        case author
        case startDate
        case endDate
        case groupStatus
        case rating
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userBookId = try container.decodeIfPresent(Int.self, forKey: .userBookId)
        groupId = try container.decodeIfPresent(Int.self, forKey: .groupId)
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
        author = try container.decodeIfPresent(String.self, forKey: .author)
        startDate = try container.decodeIfPresent(String.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(String.self, forKey: .endDate)
        groupStatus = try container.decodeIfPresent(String.self, forKey: .groupStatus)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
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
    let groupId: Int
    let title: String
    let author: String?
    let coverImageURL: String?
    let hostNickname: String
    let startDate: String?
    let endDate: String?
    let status: LibraryGroupStatus
    let rating: Double?
}

enum LibraryGroupStatus: Equatable, Hashable {
    case matched
    case completed
    case unknown(String)

    init(rawValue: String?) {
        switch (rawValue ?? "").lowercased() {
        case "matched":
            self = .matched
        case "completed":
            self = .completed
        default:
            self = .unknown(rawValue ?? "")
        }
    }

    var badgeText: String {
        switch self {
        case .matched: return "진행 중"
        case .completed: return "종료"
        case .unknown: return "-"
        }
    }
}

extension LibraryBookResponseDTO {
    func toDomain() -> LibraryBook {
        LibraryBook(
            id: userBookId ?? groupId ?? Int.random(in: 100_000...999_999),
            groupId: groupId ?? 0,
            title: bookTitle ?? "-",
            author: author,
            coverImageURL: bookImage,
            hostNickname: hostNickname ?? hostNickName ?? "-",
            startDate: startDate,
            endDate: endDate,
            status: LibraryGroupStatus(rawValue: groupStatus),
            rating: rating
        )
    }
}
