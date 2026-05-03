import CoreGraphics
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

    /// 안드 fragment_*_bottom_dialog.xml 컴포넌트 합산 기반 시트 높이(pt).
    /// 시뮬레이터에서 ±20pt 단위로 미세 조정 가능.
    var fixedHeight: CGFloat {
        switch self {
        case .start:           return 360   // 그래버+타이틀+카드+안내카드+버튼
        case .reading:         return 440   // 사용자 OK reference (HostReadingSheet)
        case .readingStatus:   return 260   // 그래버+타이틀+카드+버튼
        case .readingDone:     return 220   // 그래버+타이틀+안내+버튼
        case .extendPeriod:    return 360   // 헤더+안내+일수입력+날짜박스+버튼행
        case .extendRequest:   return 260   // 그래버+타이틀+날짜박스+버튼
        case .shipping:        return 500   // (Guest) 주소 안내 시트
        case .shippingInput:   return 580   // 헤더+택배사+운송장+사진+버튼
        case .shippingPhoto:   return 360   // 타이틀+사진(190)+버튼
        case .shipped:         return 340   // 그래버+타이틀+안내+카드+버튼*2
        case .shippingStatus:  return 280   // 그래버+타이틀+안내+카드+버튼
        case .receiveConfirm:  return 440   // 헤더+사진(180)+체크+안내+버튼
        case .tradeFinish:     return 220   // 그래버+타이틀+안내+버튼
        case .groupManage:     return 380   // 그래버+타이틀+안내+구분선+메뉴*3
        case .photoSelection:  return 140   // 행*2 (작은 카드 dialog)
        case .sendConfirm:     return 380   // 타이틀+사진(190)+체크+버튼
        }
    }
}
