import Foundation

/// 안드로이드 TradeConstants.Phase 대응.
enum DeliveryPhase: String, Equatable, Hashable {
    case initState
    case hostReading
    case hostShippingReady
    case hostShipped
    case guestReading
    case guestShippingReady
    case guestShipped
    case finished

    /// 서버 status → phase 매퍼 (안드로이드 TrackerDataMapper.statusToPhase 대응).
    static func from(_ status: TrackerStatusDTO) -> DeliveryPhase {
        switch status {
        case .ready:                        return .initState
        case .hostReading, .hostExtension:  return .hostReading
        case .hostDone:                     return .hostShippingReady
        case .shippingToGuest:              return .hostShipped
        case .received,
             .guestReading,
             .guestExtension:               return .guestReading
        case .guestDone:                    return .guestShippingReady
        case .shippingToHost:               return .guestShipped
        case .returned, .completed:         return .finished
        case .unknown:                      return .initState
        }
    }
}
