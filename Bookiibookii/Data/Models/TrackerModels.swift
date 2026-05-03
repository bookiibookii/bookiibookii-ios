import Foundation

// MARK: - 서버 DTO (안드로이드 HostTrackerListItemDto / GuestTrackerListItemDto 대응)

struct HostTrackerListItemDto: Decodable {
    let groupId: Int
    let groupType: String?
    let bookTitle: String?
    let bookImage: String?
    let bookAuthor: String?
    let bookCategory: String?
    let tradeType: String?
    let relayDetail: TrackerRelayDetailDto?
    let togetherDetail: TrackerTogetherDetailDto?
}

struct GuestTrackerListItemDto: Decodable {
    let groupId: Int
    let groupType: String?
    let bookTitle: String?
    let bookImage: String?
    let bookAuthor: String?
    let bookCategory: String?
    let tradeType: String?
    let relayDetail: TrackerRelayDetailDto?
    let togetherDetail: TrackerTogetherDetailDto?
}

struct TrackerRelayDetailDto: Decodable {
    let partnerNickname: String?
    let hostProfileImageUrl: String?
    let guestProfileImageUrls: [String?]?
    let trackerStatus: String?
    let stepDates: [String?]?
}

struct TrackerTogetherDetailDto: Decodable {
    let hostNickname: String?
    let participantCount: Int?
    let myReadingRate: Int?
    let groupReadingRate: Int?
}

// MARK: - 도메인 모델

enum ExchangeRole: Hashable {
    case host
    case guest
}

enum ExchangeType: Hashable {
    case delivery   // 택배
    case direct     // 직거래
    case none       // 함께읽기

    static func from(raw: String?) -> ExchangeType {
        switch raw?.uppercased() {
        case "DELIVERY", "SHIPPING": return .delivery
        case "DIRECT":               return .direct
        default:                     return .none
        }
    }
}

struct TrackerItem: Identifiable, Equatable, Hashable {
    let id: Int            // = groupId
    let groupId: Int
    let role: ExchangeRole
    let exchangeType: ExchangeType
    let bookTitle: String
    let bookAuthor: String
    let bookCategory: String?
    let coverImageUrl: String?
    let withUserName: String?

    // 릴레이(택배/직거래) 진행도
    let stepDates: [String?]
    let currentStepIndex: Int          // 0~3, 진행 중인 단계
    let hostProfileImageUrl: String?
    let guestProfileImageUrl: String?  // 1:1 릴레이라 단일

    // 함께읽기 독서율
    let myReadingRate: Int?
    let groupReadingRate: Int?
}

// MARK: - 매퍼

extension HostTrackerListItemDto {
    func toTrackerItem() -> TrackerItem {
        let type = ExchangeType.from(raw: tradeType)
        let withName = TrackerModelsMapper.withUserName(
            exchangeType: type,
            relay: relayDetail,
            together: togetherDetail
        )
        let stepDates = relayDetail?.stepDates ?? []
        return TrackerItem(
            id: groupId,
            groupId: groupId,
            role: .host,
            exchangeType: type,
            bookTitle: bookTitle ?? "",
            bookAuthor: bookAuthor ?? "",
            bookCategory: bookCategory,
            coverImageUrl: bookImage,
            withUserName: withName,
            stepDates: stepDates,
            currentStepIndex: TrackerModelsMapper.stepIndex(stepDates: stepDates),
            hostProfileImageUrl: relayDetail?.hostProfileImageUrl,
            guestProfileImageUrl: relayDetail?.guestProfileImageUrls?.first ?? nil,
            myReadingRate: togetherDetail?.myReadingRate,
            groupReadingRate: togetherDetail?.groupReadingRate
        )
    }
}

extension GuestTrackerListItemDto {
    func toTrackerItem() -> TrackerItem {
        let type = ExchangeType.from(raw: tradeType)
        let withName = TrackerModelsMapper.withUserName(
            exchangeType: type,
            relay: relayDetail,
            together: togetherDetail
        )
        let stepDates = relayDetail?.stepDates ?? []
        return TrackerItem(
            id: groupId,
            groupId: groupId,
            role: .guest,
            exchangeType: type,
            bookTitle: bookTitle ?? "",
            bookAuthor: bookAuthor ?? "",
            bookCategory: bookCategory,
            coverImageUrl: bookImage,
            withUserName: withName,
            stepDates: stepDates,
            currentStepIndex: TrackerModelsMapper.stepIndex(stepDates: stepDates),
            hostProfileImageUrl: relayDetail?.hostProfileImageUrl,
            guestProfileImageUrl: relayDetail?.guestProfileImageUrls?.first ?? nil,
            myReadingRate: togetherDetail?.myReadingRate,
            groupReadingRate: togetherDetail?.groupReadingRate
        )
    }
}

enum TrackerModelsMapper {
    static func withUserName(
        exchangeType: ExchangeType,
        relay: TrackerRelayDetailDto?,
        together: TrackerTogetherDetailDto?
    ) -> String? {
        switch exchangeType {
        case .delivery, .direct:
            return relay?.partnerNickname
        case .none:
            guard let name = together?.hostNickname, !name.isEmpty else { return nil }
            if let count = together?.participantCount, count > 0 {
                return "\(name)  +\(count)"
            }
            return name
        }
    }

    /// stepDates에서 마지막으로 채워진 인덱스 = 진행 중인 단계.
    /// 안드로이드 TrackerAdapter.progressStatusFromDates 로직 대응.
    static func stepIndex(stepDates: [String?]) -> Int {
        let lastFilled = stepDates.lastIndex(where: { !($0 ?? "").isEmpty }) ?? -1
        // -1(아무 단계도 미진행) → 0단계로 표시 (호스트 읽는 중)
        return max(0, min(lastFilled, 3))
    }
}

// MARK: - 택배 교환 상세 DTO (안드로이드 TrackerDetailResponseDto 대응)

struct TrackerDetailResponse: Decodable {
    let bookTitle: String?
    let partnerNickname: String?
    let trackerStatus: TrackerStatusDTO
    let startDate: String?
    let endDate: String?
    let extensionCount: Int?
    let extensionDays: Int?
    let readingPeriod: Int?
    let trackerId: Int?
    let deliveryInfo: DeliveryInfoDTO?
    let meetingInfo: MeetingInfoDTO?
}

struct DeliveryInfoDTO: Decodable {
    let receiverName: String?
    let receiverPhone: String?
    let receiverAddress: String?
    let deliveryCompany: String?
    let trackingNumber: String?
    let isVerified: Bool?
}

struct MeetingInfoDTO: Decodable {
    let meetingTime: String?
    let meetingPlace: String?
}

enum TrackerStatusDTO: String, Decodable {
    case ready              = "READY"
    case hostReading        = "HOST_READING"
    case hostExtension      = "HOST_EXTENSION"
    case hostDone           = "HOST_DONE"
    case shippingToGuest    = "SHIPPING_TO_GUEST"
    case received           = "RECEIVED"
    case guestReading       = "GUEST_READING"
    case guestExtension     = "GUEST_EXTENSION"
    case guestDone          = "GUEST_DONE"
    case shippingToHost     = "SHIPPING_TO_HOST"
    case returned           = "RETURNED"
    case completed          = "COMPLETED"
    case unknown            = "UNKNOWN"

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = TrackerStatusDTO(rawValue: raw) ?? .unknown
    }
}

// MARK: - 배송/수령 요청·응답

struct TrackerShippingStartRequest: Encodable {
    let deliveryCompany: String
    let trackingNumber: String
    let s3Key: String
}

struct TrackerReceiveRequest: Encodable {
    let s3Key: String
}

struct TrackerPresignedUrlResponse: Decodable {
    let s3Key: String
    let presignedPutUrl: String
}

struct TrackerImageResponse: Decodable {
    /// 안드 TrackerCheckShippingImageResponseDto / TrackerCheckImageResponseDto 의 `presignedGetUrl` 필드.
    let presignedGetUrl: String
}
