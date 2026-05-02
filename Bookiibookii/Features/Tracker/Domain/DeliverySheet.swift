import Foundation

/// `sheet(item:)`에 사용할 단일 라우팅 enum (Host/Guest 공통).
enum DeliverySheet: String, Identifiable {
    case start
    case reading
    case readingStatus
    case readingDone
    case extendPeriod
    case extendRequest
    case shipping
    case shippingInput
    case shippingPhoto
    case shipped
    case shippingStatus
    case receiveConfirm
    case tradeFinish
    case groupManage
    case photoSelection
    case sendConfirm

    var id: String { rawValue }
}
