import Foundation

// 안드로이드 data/model/tracker 대응 (TrkApi 신규 구조).

// MARK: - 트래커 목록 (GET /api/me/trackers)

struct TrackerListResDTO: Decodable {
    let nickname: String?
    let summary: TrackerSummaryDTO
    let topBanners: [TrackerTopBannerResDTO]?
    let items: [TrackerListItemResDTO]
}

struct TrackerSummaryDTO: Decodable {
    let totalCount: Int
    let readingCount: Int
    let exchangingCount: Int
    let reviewCount: Int
}

struct TrackerTopBannerResDTO: Decodable {
    let bannerType: String?
    let groupId: Int?
    let matchedMemberId: Int?
    let groupName: String?
    let partnerNickname: String?
    let bookTitle: String?
    let title: String?
    let titleTemplate: String?
    let subtitle: String?
    let dDayLabel: String?
    let targetAt: String?
    let remainingSeconds: Int?
}

struct TrackerListItemResDTO: Decodable, Identifiable {
    let groupId: Int
    let groupName: String?
    let tradeType: String?
    let myRole: String?
    let displayStatus: String?
    let displayBookTitle: String?
    let displayStatusLabel: String?
    let remainingDays: Int?
    let myCurrentBook: BookInfo?
    let partnerCurrentBook: BookInfo?

    var id: Int { groupId }
}

struct BookInfo: Decodable {
    let title: String?
    let image: String?
    let totalPages: Int?
    let currentPage: Int?
    let isMyOriginalBook: Bool?
    let currentReaderNickname: String?
    let currentReaderProfileImageUrl: String?
    let currentReadingRate: Int?
}

// MARK: - 트래커 상세 (GET /api/trackers/{groupId}/tracker)

struct TrackerDetailResDTO: Decodable {
    let groupId: Int
    let groupName: String?
    let tradeType: String?
    let myRole: String?
    let displayStatus: String?
    let displayBookTitle: String?
    let displayStatusLabel: String?
    let dDay: Int?
    let myBook: BookInfo?
    let partnerBook: BookInfo?
    let steps: [TrackerStepDTO]?
}

struct TrackerStepDTO: Decodable {
    let status: String?
    let title: String?
    let description: String?
    let completed: Bool?
}

// MARK: - 독서 진행률 (PATCH /api/trackers/{groupId}/reading-progress)

struct ReadingProgressReqDTO: Encodable {
    let currentPage: Int
}

struct ReadingProgressResDTO: Decodable {
    let memberBookId: Int?
    let currentPage: Int?
    let totalPages: Int?
    let progressRate: Int?
    let readingStatus: String?
    let readingStatusText: String?
    let dDay: Int?
}

// MARK: - 독서 기간 수정 (PATCH /api/trackers/{groupId}/reading-period)

struct ReadingPeriodUpdateReqDTO: Encodable {
    let newEndDate: String   // "yyyy-MM-dd"
}

struct ReadingPeriodUpdateResDTO: Decodable {
    let newEndDate: String?
    let dDay: Int?
}

// MARK: - 책 후기 (GET/POST/PATCH /api/groups/{groupId}/reviews ...)

struct BookReviewReqDTO: Encodable {
    let star: Double
    let comment: String?
}

struct BookReviewResDTO: Decodable {
    let reviewId: Int?
    let groupId: Int?
    let memberBookId: Int?
    let star: Double?
    let comment: String?
    let readingStatus: String?
    let exchangeStatus: String?
}

struct MyBookReviewsResDTO: Decodable {
    let reviews: [BookReviewItem]?
}

struct BookReviewItem: Decodable {
    let reviewId: Int?
    let reviewType: String?   // MY_BOOK | PARTNER_BOOK
    let groupId: Int?
    let bookId: Int?
    let bookTitle: String?
    let bookAuthor: String?
    let bookImageUrl: String?
    let rating: Double?
    let content: String?
    let isEditable: Bool?
    let createdAt: String?
    let updatedAt: String?
}

// MARK: - 파트너(멤버) 후기 (POST /api/groups/{groupId}/member-reviews)

struct MemberReviewCreateReqDTO: Encodable {
    let reaction: String?   // BOOM_UP | BOOM_DOWN | nil
    let comment: String     // 최대 20자
}

struct MemberReviewResDTO: Decodable {
    let reviewId: Int?
    let groupCompleted: Bool?
}

// MARK: - 배송 등록 (POST /api/groups/{groupId}/deliveries)

struct DeliveryRegisterReqDTO: Encodable {
    let deliveryCompany: String
    let trackingNumber: String
}

// MARK: - 직접 교환 약속 (meetings)

struct MeetingRegisterReqDTO: Encodable {
    let placeName: String
    let address: String
    let zipCode: String?
    let x: Double
    let y: Double
    let addressDetail: String?
    let meetingAt: String   // offset 포함 ISO date-time
}

struct MeetingResDTO: Decodable {
    let meetingId: Int?
    let exchangeRound: String?   // FIRST_EXCHANGE | RETURN_EXCHANGE
    let location: MeetingLocationDTO?
    let addressDetail: String?
    let meetingAt: String?
    let createdBy: MeetingCreatedByDTO?
}

struct MeetingLocationDTO: Decodable {
    let placeName: String?
    let address: String?
    let zipCode: String?
    let x: Double?
    let y: Double?
}

struct MeetingCreatedByDTO: Decodable {
    let matchedMemberId: Int?
    let userId: Int?
    let nickname: String?
    let role: String?   // HOST | GUEST
}

// MARK: - 배송지 정보 (deliveries/address)

struct DeliveryAddressResDTO: Decodable {
    let myAddress: DeliveryAddressItemDTO?
    let partnerAddress: DeliveryAddressItemDTO?
    let canEditMyAddress: Bool?
}

struct DeliveryAddressItemDTO: Decodable {
    let receiverName: String?
    let phoneNumber: String?
    let address: String?
    let addressDetail: String?
    let zipCode: String?
}

struct DeliveryAddressSavedUpdateReqDTO: Encodable {
    let userDeliveryId: Int
}

struct DeliveryAddressDirectUpdateReqDTO: Encodable {
    let zipCode: String
    let address: String
    let addressDetail: String
}

// MARK: - 상대방 운송장 (GET /api/groups/{groupId}/deliveries/partner)

struct PartnerDeliveryResponseDTO: Decodable {
    let deliveryId: String?
    let deliveryCompany: String?
    let deliveryCompanyName: String?
    let trackingNumber: String?
    let trackingRegisteredAt: String?
    let canConfirmReceived: Bool?
}
