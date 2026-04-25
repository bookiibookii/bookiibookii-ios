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
    let guestProfileImageUrls: [String]?
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

enum ExchangeRole {
    case host
    case guest
}

enum ExchangeType {
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

struct TrackerItem: Identifiable, Equatable {
    let id: Int            // = groupId
    let groupId: Int
    let role: ExchangeRole
    let exchangeType: ExchangeType
    let bookTitle: String
    let bookAuthor: String
    let bookCategory: String?
    let coverImageUrl: String?
    let withUserName: String?
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
        return TrackerItem(
            id: groupId,
            groupId: groupId,
            role: .host,
            exchangeType: type,
            bookTitle: bookTitle ?? "",
            bookAuthor: bookAuthor ?? "",
            bookCategory: bookCategory,
            coverImageUrl: bookImage,
            withUserName: withName
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
        return TrackerItem(
            id: groupId,
            groupId: groupId,
            role: .guest,
            exchangeType: type,
            bookTitle: bookTitle ?? "",
            bookAuthor: bookAuthor ?? "",
            bookCategory: bookCategory,
            coverImageUrl: bookImage,
            withUserName: withName
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
}
