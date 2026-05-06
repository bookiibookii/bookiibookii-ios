import Foundation

/// 직접교환 전용 phase. 안드 trkDirectHost/trkDirectGuest 는 status 문자열을 직접 분기하지만,
/// iOS는 sheet 라우팅과 step 빌더 양쪽이 phase 추상화에 의존하므로 enum으로 끌어올림.
enum DirectPhase: String, Equatable, Hashable {
    case initState              // READY
    case hostReading            // HOST_READING / HOST_EXTENSION
    case hostAppointment        // HOST_DONE — 호스트가 게스트에게 책 전달할 약속 단계
    case hostHandover           // SHIPPING_TO_GUEST — 약속 시간 + 직접 전달
    case guestReading           // RECEIVED / GUEST_READING / GUEST_EXTENSION
    case guestAppointment       // GUEST_DONE — 게스트가 호스트에게 책 반납할 약속 단계
    case guestReturn            // SHIPPING_TO_HOST — 약속 시간 + 직접 반납
    case finished               // RETURNED / COMPLETED

    /// 서버 status → DirectPhase 매퍼.
    static func from(_ status: TrackerStatusDTO) -> DirectPhase {
        switch status {
        case .ready:                        return .initState
        case .hostReading, .hostExtension:  return .hostReading
        case .hostDone:                     return .hostAppointment
        case .shippingToGuest:              return .hostHandover
        case .received,
             .guestReading,
             .guestExtension:               return .guestReading
        case .guestDone:                    return .guestAppointment
        case .shippingToHost:               return .guestReturn
        case .returned, .completed:         return .finished
        case .unknown:                      return .initState
        }
    }

    /// 진행 비교 + visibleCount 계산용.
    var ordinal: Int {
        switch self {
        case .initState:         return 0
        case .hostReading:       return 1
        case .hostAppointment:   return 2
        case .hostHandover:      return 3
        case .guestReading:      return 4
        case .guestAppointment:  return 5
        case .guestReturn:       return 6
        case .finished:          return 7
        }
    }
}
