import CoreGraphics
import Foundation

/// 직접교환 전용 sheet 라우팅 enum.
/// 안드 trkDirectHost / trkDirectGuest 의 *BottomDialogFragment / *DialogFragment 매핑.
enum DirectSheet: String, Identifiable {
    case start
    case reading
    case readingStatus
    case appointment            // HOST_DONE — 약속 잡기 진입 안내
    case appointmentEdit        // 약속 수정 (BottomSheet)
    case appointmentEditDialog  // 약속 수정 입력 폼 (Center dialog)
    case appointmentStatus      // 약속 현황 (BottomSheet)
    case setAppointment         // 첫 약속 등록 폼 (Center dialog)
    case meetEmpty              // 약속 없음 빈 상태 (BottomSheet)
    case meetIssue              // 만남 문제 발생 (Center dialog)
    case exchange               // 약속 시간 후 책 직접 전달/교환 (BottomSheet)
    case receive                // 약속 시간 후 책 회수 (BottomSheet)
    case receiveIssue           // 회수 문제 발생 (Center dialog)
    case extendPeriod           // 연장 일수 입력 (Center dialog)
    case extendRequest          // 게스트 연장 요청 알림 (BottomSheet)
    case tradeFinish
    case groupManage

    var id: String { rawValue }

    /// 안드 BottomSheetDialogFragment(=하단 시트)인지 여부.
    /// false면 일반 DialogFragment → 중앙 모달로 표시.
    var isBottomSheet: Bool {
        switch self {
        // 하단 시트
        case .start, .reading, .readingStatus,
             .appointment, .appointmentEdit, .appointmentStatus,
             .meetEmpty, .exchange, .receive,
             .extendRequest, .tradeFinish, .groupManage:
            return true
        // 중앙 다이얼로그
        case .appointmentEditDialog, .setAppointment,
             .meetIssue, .receiveIssue, .extendPeriod:
            return false
        }
    }

    /// 안드 fragment_direct_*.xml 컴포넌트 합산 기준 시트 높이(pt) 추정값.
    /// 실제 시트 본문 작업 시 시뮬레이터에서 ±20pt 미세 조정.
    var fixedHeight: CGFloat {
        switch self {
        case .start:                  return 360
        case .reading:                return 440
        case .readingStatus:          return 260
        case .appointment:            return 360
        case .appointmentEdit:        return 480
        case .appointmentEditDialog:  return 520
        case .appointmentStatus:      return 380
        case .setAppointment:         return 520
        case .meetEmpty:              return 320
        case .meetIssue:              return 360
        case .exchange:               return 360
        case .receive:                return 360
        case .receiveIssue:           return 360
        case .extendPeriod:           return 360
        case .extendRequest:          return 260
        case .tradeFinish:            return 220
        case .groupManage:            return 380
        }
    }
}
