import Foundation

// 안드로이드 data/model/location 대응 (희망 교환 장소 / 배송지).

// MARK: - 희망 교환 장소 (직접 교환)

struct ExchangeAddress: Decodable, Identifiable, Equatable {
    let id: Int
    let placeName: String
    let address: String
    let zipCode: String?
    let x: Double
    let y: Double
    let addressDetail: String?   // null 가능
    let isDefault: Bool

    enum CodingKeys: String, CodingKey {
        case id = "Id"           // 안드 @SerializedName("Id")
        case placeName, address, zipCode, x, y, addressDetail, isDefault
    }
}

// POST/PUT 공용 요청 body
struct ExchangeAddressRequest: Encodable {
    let placeName: String
    let address: String
    let zipCode: String
    let x: Double
    let y: Double
    let addressDetail: String?
}

// MARK: - 배송지 (택배 교환)

struct DeliveryAddress: Decodable, Identifiable, Equatable {
    let id: Int
    let placeName: String
    let address: String
    let zipCode: String
    let addressDetail: String?   // null 가능
    let receiverName: String
    let phone: String
    let isDefault: Bool

    enum CodingKeys: String, CodingKey {
        case id = "Id"           // 안드 @SerializedName("Id")
        case placeName, address, zipCode, addressDetail, receiverName, phone, isDefault
    }
}

// POST/PUT 공용 요청 body
struct DeliveryAddressRequest: Encodable {
    let placeName: String
    let address: String
    let zipCode: String
    let addressDetail: String?
    let receiverName: String
    let phone: String            // 형식: 02-123-4567 / 010-1234-5678
}
