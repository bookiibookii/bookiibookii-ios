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

struct LibraryCardList: Equatable {
    let groupId: Int
    let topComments: [LibraryTopComment]
    let cards: [LibraryCard]
}

struct LibraryTopComment: Equatable, Identifiable {
    let id: String
    let nickname: String
    let comment: String
}

struct LibraryCard: Equatable, Identifiable {
    let id: Int
    let page: Int
    let memo: String
    let imageURL: String?
    let creatorName: String
    let isBookmarked: Bool
    let createdAt: String?
    let messageCount: Int
}

extension CardListResponseDTO {
    func toDomain() -> LibraryCardList {
        let fallbackComment = "아직 한 줄 평을 남기지 않았어요."
        var comments: [LibraryTopComment] = []

        if let togetherComments, !togetherComments.isEmpty {
            comments = togetherComments.prefix(2).map {
                LibraryTopComment(
                    id: "\($0.userId ?? 0)",
                    nickname: ($0.nickname ?? "").isEmpty ? "-" : ($0.nickname ?? ""),
                    comment: (($0.comment ?? "").isEmpty ? fallbackComment : ($0.comment ?? ""))
                )
            }
        } else {
            comments = [
                LibraryTopComment(
                    id: "my",
                    nickname: "나",
                    comment: ((myComment ?? "").isEmpty ? fallbackComment : (myComment ?? ""))
                ),
                LibraryTopComment(
                    id: "partner",
                    nickname: currentBookOwner?.nickname ?? "파트너",
                    comment: ((partnerComment ?? "").isEmpty ? fallbackComment : (partnerComment ?? ""))
                )
            ]
        }

        let mappedCards = (cards ?? []).map { dto in
            LibraryCard(
                id: dto.cardId ?? Int.random(in: 100_000...999_999),
                page: dto.page ?? 0,
                memo: dto.memo ?? "",
                imageURL: dto.cardImage?.presignedGetUrl,
                creatorName: (dto.creatorName ?? "").isEmpty ? "-" : (dto.creatorName ?? ""),
                isBookmarked: dto.isBookmarked ?? false,
                createdAt: dto.createdAt,
                messageCount: 0
            )
        }

        return LibraryCardList(
            groupId: groupId ?? 0,
            topComments: comments,
            cards: mappedCards
        )
    }
}
