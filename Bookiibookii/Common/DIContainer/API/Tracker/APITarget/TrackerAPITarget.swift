import Foundation

// 안드로이드 TrkApi 대응 (택배 교환 포함).
enum TrackerAPITarget: APITargetType {
    case allList
    case hostList
    case guestList

    case detail(groupId: Int)
    case startReading(groupId: Int)
    case requestExtension(groupId: Int, days: Int)
    case markDone(groupId: Int)
    case startShipping(groupId: Int, body: TrackerShippingStartRequest)
    case registerReceipt(groupId: Int, body: TrackerReceiveRequest)
    case verifyReception(groupId: Int)
    case presignedUrl(groupId: Int)
    case shippingImage(groupId: Int)
    case receivedImage(groupId: Int)

    var path: String {
        switch self {
        case .allList:                             return API.Path.trackers
        case .hostList:                            return API.Path.trackers + "/host"
        case .guestList:                           return API.Path.trackers + "/guest"
        case .detail(let id):                      return API.Path.trackerDetail(groupId: id)
        case .startReading(let id):                return API.Path.trackerReading(groupId: id)
        case .requestExtension(let id, _):         return API.Path.trackerPeriodExtension(groupId: id)
        case .markDone(let id):                    return API.Path.trackerDone(groupId: id)
        case .startShipping(let id, _):            return API.Path.trackerDelivery(groupId: id)
        case .registerReceipt(let id, _):          return API.Path.trackerReception(groupId: id)
        case .verifyReception(let id):             return API.Path.trackerVerification(groupId: id)
        case .presignedUrl(let id):                return API.Path.trackerPresignedUrl(groupId: id)
        case .shippingImage(let id):               return API.Path.trackerImageDelivery(groupId: id)
        case .receivedImage(let id):               return API.Path.trackerImageReceived(groupId: id)
        }
    }

    var method: HTTPMethod {
        switch self {
        case .allList, .hostList, .guestList,
             .detail, .shippingImage, .receivedImage:
            return .get
        case .startShipping, .presignedUrl:
            return .post
        case .startReading, .requestExtension, .markDone,
             .registerReceipt, .verifyReception:
            return .patch
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .requestExtension(_, let days):
            return [URLQueryItem(name: "days", value: "\(days)")]
        default:
            return []
        }
    }

    var body: Data? {
        switch self {
        case .startShipping(_, let body):
            return try? JSONEncoder().encode(body)
        case .registerReceipt(_, let body):
            return try? JSONEncoder().encode(body)
        default:
            return nil
        }
    }

    var headers: [String: String] {
        switch self {
        case .startShipping, .registerReceipt:
            return ["Content-Type": "application/json"]
        default:
            return [:]
        }
    }
}
