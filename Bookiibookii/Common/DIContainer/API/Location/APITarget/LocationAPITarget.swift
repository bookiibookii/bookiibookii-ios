import Foundation

// 안드로이드 LocationApi 대응 — 희망 교환 장소 / 배송지 CRUD + 대표 설정.
enum LocationAPITarget: APITargetType {
    // 희망 교환 장소 (직접 교환)
    case fetchExchanges
    case addExchange(ExchangeAddressRequest)
    case updateExchange(id: Int, body: ExchangeAddressRequest)
    case deleteExchange(id: Int)
    case setDefaultExchange(id: Int)

    // 배송지 (택배 교환)
    case fetchDeliveries
    case addDelivery(DeliveryAddressRequest)
    case updateDelivery(id: Int, body: DeliveryAddressRequest)
    case deleteDelivery(id: Int)
    case setDefaultDelivery(id: Int)

    var path: String {
        switch self {
        case .fetchExchanges, .addExchange:
            return API.Path.exchangeAddresses
        case .updateExchange(let id, _), .deleteExchange(let id):
            return API.Path.exchangeAddress(id: id)
        case .setDefaultExchange(let id):
            return API.Path.exchangeAddressDefault(id: id)
        case .fetchDeliveries, .addDelivery:
            return API.Path.deliveryAddresses
        case .updateDelivery(let id, _), .deleteDelivery(let id):
            return API.Path.deliveryAddress(id: id)
        case .setDefaultDelivery(let id):
            return API.Path.deliveryAddressDefault(id: id)
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchExchanges, .fetchDeliveries:
            return .get
        case .addExchange, .addDelivery:
            return .post
        case .updateExchange, .updateDelivery:
            return .put
        case .deleteExchange, .deleteDelivery:
            return .delete
        case .setDefaultExchange, .setDefaultDelivery:
            return .patch
        }
    }

    var body: Data? {
        switch self {
        case .addExchange(let request):           return try? JSONEncoder().encode(request)
        case .updateExchange(_, let body):        return try? JSONEncoder().encode(body)
        case .addDelivery(let request):           return try? JSONEncoder().encode(request)
        case .updateDelivery(_, let body):        return try? JSONEncoder().encode(body)
        default:                                   return nil
        }
    }

    var headers: [String: String] {
        switch self {
        case .addExchange, .updateExchange, .addDelivery, .updateDelivery:
            return ["Content-Type": "application/json"]
        default:
            return [:]
        }
    }
}
