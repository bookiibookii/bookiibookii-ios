import Foundation

struct CardListResponseDTO: Decodable {
    let groupId: Int?
    let currentBookOwner: CurrentBookOwnerDTO?
    let myComment: String?
    let partnerComment: String?
    let togetherComments: [TogetherCommentDTO]?
    let cards: [GroupCardResponseDTO]?
}

struct CurrentBookOwnerDTO: Decodable {
    let matchedMemberId: Int?
    let nickname: String?
}

struct TogetherCommentDTO: Decodable {
    let userId: Int?
    let nickname: String?
    let comment: String?
}

struct GroupCardResponseDTO: Decodable {
    let cardId: Int?
    let memberBookId: Int?
    let cardType: String?
    let page: Int?
    let memo: String?
    let quotation: String?
    let cardImage: CardImageResponseDTO?
    let createdAt: String?
    let bookTitle: String?
    let totalPages: Int?
    let genre: String?
    let completedAt: String?
    let isMine: Bool?
    let isBookmarked: Bool?
    let creatorName: String?
    let creatorProfileImageUrl: String?
    let reactionCounts: [CardReactionCountResponseDTO]?
    let myReactions: [String]?
}

struct CardReactionCountResponseDTO: Decodable {
    let reaction: String?
    let count: Int?
}

struct CardImageResponseDTO: Decodable {
    let cardImageId: Int?
    let s3Key: String?
    let presignedGetUrl: String?
}

struct CardBookmarkResponseDTO: Decodable {
    let bookmarked: Bool
}

struct CardReactionToggleRequestBody: Encodable {
    let reaction: LibraryCardReaction
}

/// POST `/api/member-books/cards/{cardId}/share-token`
struct CreateShareTokenRequestBody: Encodable {
    let shareLayout: String
}

struct ShareTokenResponseDTO: Decodable {
    let shareToken: String
    let shareUrl: String
    let shareLayout: String?
}

struct CardReactionToggleResponseDTO: Decodable {
    let reaction: LibraryCardReaction
    let active: Bool
}

enum LibraryCardReaction: String, Codable, CaseIterable, Hashable, Identifiable {
    case empathy = "FEELYOU"
    case good = "LIKE"
    case fun = "FUN"
    case sad = "SAD"
    case angry = "ANGRY"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .empathy: return "ic_empathy"
        case .good: return "ic_good"
        case .fun: return "ic_fun"
        case .sad: return "ic_sad"
        case .angry: return "ic_angry"
        }
    }

    var title: String {
        switch self {
        case .empathy: return "공감해요"
        case .good: return "좋아요"
        case .fun: return "웃겨요"
        case .sad: return "슬퍼요"
        case .angry: return "화나요"
        }
    }
}

struct CardCreateRequestBody: Encodable {
    let cardType: String
    let quotation: String?
    let s3Key: String?
    let page: Int
    let memo: String?
}

struct CardUpdateRequestBody: Encodable {
    let s3Key: String?
    let page: Int?
    let memo: String?
    let quotation: String?
}

struct CardCreateResponseDTO: Decodable {
    let cardId: Int?
    let cardType: String?
    let page: Int?
    let memo: String?
    let quotation: String?
    let cardImage: CardImageResponseDTO?
    let createdAt: String?
    let creatorName: String?
    let creatorProfileImageUrl: String?
}

struct CardCommentCreateRequestBody: Encodable {
    let content: String
}

struct CardCommentCreateResponseDTO: Decodable {
    let id: Int?
}

struct CardCommentWriterDTO: Decodable {
    let userId: Int?
    let name: String?
    let profileImageUrl: String?
}

struct CardCommentResponseDTO: Decodable {
    let id: Int?
    let content: String?
    let writer: CardCommentWriterDTO?
    let createdAt: String?
}

struct CardCommentListResponseDTO: Decodable {
    let totalCount: Int?
    let comments: [CardCommentResponseDTO]?
}

struct LibraryCardList: Equatable {
    let groupId: Int
    let cards: [LibraryCard]
}

struct LibraryCard: Equatable, Identifiable, Hashable {
    let id: Int
    let isBookmarkable: Bool
    let memberBookId: Int?
    let cardType: LibraryCardType
    let bookTitle: String?
    let page: Int
    let memo: String
    let quotation: String?
    let imageURL: String?
    let creatorName: String
    let creatorProfileImageURL: String?
    let isMine: Bool
    let isBookmarked: Bool
    let activeReactions: Set<LibraryCardReaction>
    let reactionCounts: [LibraryCardReaction: Int]
    let createdAt: String?
    let messageCount: Int
}

extension LibraryCard {
    var asDetail: LibraryCardDetail {
        LibraryCardDetail(
            cardId: id,
            memberBookId: memberBookId,
            cardType: cardType,
            page: page,
            memo: memo,
            quotation: quotation,
            imageURL: imageURL,
            imageS3Key: nil,
            creatorName: creatorName,
            creatorProfileImageURL: creatorProfileImageURL,
            bookTitle: bookTitle,
            totalPages: nil,
            genre: nil,
            completedAt: nil,
            isMine: isMine,
            isBookmarked: isBookmarked,
            activeReactions: activeReactions,
            createdAt: createdAt
        )
    }

    func updatingBookmark(_ isBookmarked: Bool) -> LibraryCard {
        LibraryCard(
            id: id,
            isBookmarkable: isBookmarkable,
            memberBookId: memberBookId,
            cardType: cardType,
            bookTitle: bookTitle,
            page: page,
            memo: memo,
            quotation: quotation,
            imageURL: imageURL,
            creatorName: creatorName,
            creatorProfileImageURL: creatorProfileImageURL,
            isMine: isMine,
            isBookmarked: isBookmarked,
            activeReactions: activeReactions,
            reactionCounts: reactionCounts,
            createdAt: createdAt,
            messageCount: messageCount
        )
    }

    func updatingReaction(_ reaction: LibraryCardReaction, active: Bool) -> LibraryCard {
        var reactions = activeReactions
        var counts = reactionCounts
        let wasActive = reactions.contains(reaction)
        if active {
            reactions.insert(reaction)
        } else {
            reactions.remove(reaction)
        }
        if wasActive != active {
            let current = counts[reaction] ?? 0
            counts[reaction] = active ? current + 1 : max(0, current - 1)
        }
        return LibraryCard(
            id: id,
            isBookmarkable: isBookmarkable,
            memberBookId: memberBookId,
            cardType: cardType,
            bookTitle: bookTitle,
            page: page,
            memo: memo,
            quotation: quotation,
            imageURL: imageURL,
            creatorName: creatorName,
            creatorProfileImageURL: creatorProfileImageURL,
            isMine: isMine,
            isBookmarked: isBookmarked,
            activeReactions: reactions,
            reactionCounts: counts,
            createdAt: createdAt,
            messageCount: messageCount
        )
    }
}

extension LibraryCard {
    var displayedReaction: LibraryCardReaction? {
        if let myReaction = LibraryCardReaction.allCases.first(
            where: { activeReactions.contains($0) }
        ) {
            return myReaction
        }

        return LibraryCardReaction.allCases
            .filter { (reactionCounts[$0] ?? 0) > 0 }
            .max {
                (reactionCounts[$0] ?? 0) < (reactionCounts[$1] ?? 0)
            }
    }
}

enum LibraryCardType: Equatable, Hashable {
    case image
    case text

    init(rawValue: String?) {
        self = rawValue?.uppercased() == "TEXT" ? .text : .image
    }
}

struct LibraryCardDetail: Equatable {
    let cardId: Int
    let memberBookId: Int?
    let cardType: LibraryCardType
    let page: Int
    let memo: String
    let quotation: String?
    let imageURL: String?
    /// 수정 시 기존 이미지 업로드 키 (변경 없이 저장할 때 필요).
    let imageS3Key: String?
    let creatorName: String
    let creatorProfileImageURL: String?
    let bookTitle: String?
    let totalPages: Int?
    let genre: String?
    let completedAt: String?
    let isMine: Bool
    let isBookmarked: Bool
    let activeReactions: Set<LibraryCardReaction>
    let createdAt: String?
}

extension LibraryCardDetail {
    func updatingBookmark(_ isBookmarked: Bool) -> LibraryCardDetail {
        LibraryCardDetail(
            cardId: cardId,
            memberBookId: memberBookId,
            cardType: cardType,
            page: page,
            memo: memo,
            quotation: quotation,
            imageURL: imageURL,
            imageS3Key: imageS3Key,
            creatorName: creatorName,
            creatorProfileImageURL: creatorProfileImageURL,
            bookTitle: bookTitle,
            totalPages: totalPages,
            genre: genre,
            completedAt: completedAt,
            isMine: isMine,
            isBookmarked: isBookmarked,
            activeReactions: activeReactions,
            createdAt: createdAt
        )
    }

    func updatingReaction(
        _ reaction: LibraryCardReaction,
        active: Bool
    ) -> LibraryCardDetail {
        var reactions = activeReactions
        if active {
            reactions.insert(reaction)
        } else {
            reactions.remove(reaction)
        }

        return LibraryCardDetail(
            cardId: cardId,
            memberBookId: memberBookId,
            cardType: cardType,
            page: page,
            memo: memo,
            quotation: quotation,
            imageURL: imageURL,
            imageS3Key: imageS3Key,
            creatorName: creatorName,
            creatorProfileImageURL: creatorProfileImageURL,
            bookTitle: bookTitle,
            totalPages: totalPages,
            genre: genre,
            completedAt: completedAt,
            isMine: isMine,
            isBookmarked: isBookmarked,
            activeReactions: reactions,
            createdAt: createdAt
        )
    }
}

struct LibraryCardComment: Equatable, Identifiable {
    let id: Int
    let content: String
    let writerId: Int?
    let writerName: String
    let writerProfileImageURL: String?
    let createdAt: String?
}

struct LibraryCardCommentList: Equatable {
    let totalCount: Int
    let comments: [LibraryCardComment]
}

extension GroupCardResponseDTO {
    func toLibraryCard() -> LibraryCard {
        let serverCardId = cardId
        let rowId = serverCardId ?? (-abs(stableLibraryCardRowId(for: self)) - 1)
        let title = bookTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        return LibraryCard(
            id: rowId,
            isBookmarkable: serverCardId != nil,
            memberBookId: memberBookId,
            cardType: LibraryCardType(rawValue: cardType),
            bookTitle: (title?.isEmpty == false) ? title : nil,
            page: page ?? 0,
            memo: memo ?? "",
            quotation: quotation,
            imageURL: cardImage?.presignedGetUrl,
            creatorName: (creatorName ?? "").isEmpty ? "-" : (creatorName ?? ""),
            creatorProfileImageURL: creatorProfileImageUrl,
            isMine: isMine ?? false,
            isBookmarked: isBookmarked ?? false,
            activeReactions: Set(
                (myReactions ?? []).compactMap(LibraryCardReaction.init(rawValue:))
            ),
            reactionCounts: Dictionary(
                uniqueKeysWithValues: (reactionCounts ?? []).compactMap { item in
                    guard let rawValue = item.reaction,
                          let reaction = LibraryCardReaction(rawValue: rawValue),
                          let count = item.count,
                          count > 0 else {
                        return nil
                    }
                    return (reaction, count)
                }
            ),
            createdAt: createdAt,
            messageCount: 0
        )
    }

    func toLibraryCardDetail() -> LibraryCardDetail {
        LibraryCardDetail(
            cardId: cardId ?? 0,
            memberBookId: memberBookId,
            cardType: LibraryCardType(rawValue: cardType),
            page: page ?? 0,
            memo: memo ?? "",
            quotation: quotation,
            imageURL: cardImage?.presignedGetUrl,
            imageS3Key: cardImage?.s3Key,
            creatorName: (creatorName ?? "").isEmpty ? "-" : (creatorName ?? ""),
            creatorProfileImageURL: creatorProfileImageUrl,
            bookTitle: (bookTitle ?? "").isEmpty ? nil : bookTitle,
            totalPages: totalPages,
            genre: genre,
            completedAt: completedAt,
            isMine: isMine ?? false,
            isBookmarked: isBookmarked ?? false,
            activeReactions: Set(
                (myReactions ?? []).compactMap(LibraryCardReaction.init(rawValue:))
            ),
            createdAt: createdAt
        )
    }
}

extension CardListResponseDTO {
    func toDomain() -> LibraryCardList {
        LibraryCardList(
            groupId: groupId ?? 0,
            cards: (cards ?? []).map { $0.toLibraryCard() }
        )
    }
}

extension CardCommentResponseDTO {
    func toDomain() -> LibraryCardComment {
        LibraryCardComment(
            id: id ?? 0,
            content: content ?? "",
            writerId: writer?.userId,
            writerName: (writer?.name ?? "").isEmpty ? "-" : (writer?.name ?? ""),
            writerProfileImageURL: writer?.profileImageUrl,
            createdAt: createdAt
        )
    }
}

extension CardCommentListResponseDTO {
    func toDomain() -> LibraryCardCommentList {
        let mapped = (comments ?? []).map { $0.toDomain() }
        return LibraryCardCommentList(
            totalCount: totalCount ?? mapped.count,
            comments: mapped
        )
    }
}

private func stableLibraryCardRowId(for dto: GroupCardResponseDTO) -> Int {
    let s = "\(dto.page ?? 0)|\(dto.memo ?? "")|\(dto.createdAt ?? "")|\(dto.cardImage?.s3Key ?? "")|\(dto.bookTitle ?? "")"
    var h: UInt64 = 5381
    for byte in s.utf8 {
        h = ((h << 5) &+ h) &+ UInt64(byte)
    }
    return Int(truncatingIfNeeded: h & 0x7fff_ffff)
}
