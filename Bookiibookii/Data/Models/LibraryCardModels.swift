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
    let page: Int?
    let memo: String?
    let cardImage: CardImageResponseDTO?
    let createdAt: String?
    let bookTitle: String?
    let isBookmarked: Bool?
    let creatorName: String?
}

struct CardImageResponseDTO: Decodable {
    let cardImageId: Int?
    let s3Key: String?
    let presignedGetUrl: String?
}

struct CardBookmarkResponseDTO: Decodable {
    let bookmarked: Bool
}

struct CardCreateRequestBody: Encodable {
    let s3Key: String
    let page: Int
    let memo: String?

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(s3Key, forKey: .s3Key)
        try c.encode(page, forKey: .page)
        try c.encodeIfPresent(memo, forKey: .memo)
    }

    private enum CodingKeys: String, CodingKey {
        case s3Key, page, memo
    }
}

struct CardCreateResponseDTO: Decodable {
    let cardId: Int?
    let page: Int?
    let memo: String?
    let cardImage: CardImageResponseDTO?
    let createdAt: String?
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
    let topComments: [LibraryTopComment]
    let togetherComments: [LibraryTopComment]
    let cards: [LibraryCard]
}

struct LibraryTopComment: Equatable, Identifiable {
    let id: String
    let nickname: String
    let comment: String
    let hasWrittenComment: Bool
}

struct LibraryCard: Equatable, Identifiable {
    let id: Int
    let isBookmarkable: Bool
    let bookTitle: String?
    let page: Int
    let memo: String
    let imageURL: String?
    let creatorName: String
    let isBookmarked: Bool
    let createdAt: String?
    let messageCount: Int
}

struct LibraryCardDetail: Equatable {
    let cardId: Int
    let page: Int
    let memo: String
    let imageURL: String?
    /// 수정 시 기존 이미지 업로드 키 (변경 없이 저장할 때 필요).
    let imageS3Key: String?
    let creatorName: String
    let bookTitle: String?
    let isBookmarked: Bool
    let createdAt: String?
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
            bookTitle: (title?.isEmpty == false) ? title : nil,
            page: page ?? 0,
            memo: memo ?? "",
            imageURL: cardImage?.presignedGetUrl,
            creatorName: (creatorName ?? "").isEmpty ? "-" : (creatorName ?? ""),
            isBookmarked: isBookmarked ?? false,
            createdAt: createdAt,
            messageCount: 0
        )
    }

    func toLibraryCardDetail() -> LibraryCardDetail {
        LibraryCardDetail(
            cardId: cardId ?? 0,
            page: page ?? 0,
            memo: memo ?? "",
            imageURL: cardImage?.presignedGetUrl,
            imageS3Key: cardImage?.s3Key,
            creatorName: (creatorName ?? "").isEmpty ? "-" : (creatorName ?? ""),
            bookTitle: (bookTitle ?? "").isEmpty ? nil : bookTitle,
            isBookmarked: isBookmarked ?? false,
            createdAt: createdAt
        )
    }
}

extension CardListResponseDTO {
    func toDomain() -> LibraryCardList {
        let fallbackRelayComment = "아직 한 줄 평을 남기지 않았어요."
        let fallbackTogetherComment = "아직 후기를 남기지 않았어요!"
        var comments: [LibraryTopComment] = []

        if let togetherComments, !togetherComments.isEmpty {
            comments = togetherComments.prefix(2).map {
                LibraryTopComment(
                    id: "\($0.userId ?? 0)",
                    nickname: ($0.nickname ?? "").isEmpty ? "-" : ($0.nickname ?? ""),
                    comment: (($0.comment ?? "").isEmpty ? fallbackTogetherComment : ($0.comment ?? "")),
                    hasWrittenComment: !(($0.comment ?? "").isEmpty)
                )
            }
        } else {
            comments = [
                LibraryTopComment(
                    id: "my",
                    nickname: "나",
                    comment: ((myComment ?? "").isEmpty ? fallbackRelayComment : (myComment ?? "")),
                    hasWrittenComment: !(myComment ?? "").isEmpty
                ),
                LibraryTopComment(
                    id: "partner",
                    nickname: currentBookOwner?.nickname ?? "파트너",
                    comment: ((partnerComment ?? "").isEmpty ? fallbackRelayComment : (partnerComment ?? "")),
                    hasWrittenComment: !(partnerComment ?? "").isEmpty
                )
            ]
        }

        let allTogetherComments: [LibraryTopComment] = (togetherComments ?? []).map {
            LibraryTopComment(
                id: "\($0.userId ?? 0)",
                nickname: ($0.nickname ?? "").isEmpty ? "-" : ($0.nickname ?? ""),
                comment: (($0.comment ?? "").isEmpty ? fallbackTogetherComment : ($0.comment ?? "")),
                hasWrittenComment: !(($0.comment ?? "").isEmpty)
            )
        }
        let mappedCards = (cards ?? []).map { $0.toLibraryCard() }

        return LibraryCardList(
            groupId: groupId ?? 0,
            topComments: comments,
            togetherComments: allTogetherComments,
            cards: mappedCards
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
