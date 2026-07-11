import Foundation

// displayStatus(서버 상태) → 액션 버튼 / 활성화 / 진행률 표시 규칙.
enum TrackerAction {
    case none
    case recordProgress
    case writeReadingCard
    case writeBookReview
    case editBookReview
    case checkDeliveryInfo
    case checkShippingInfo
    case confirmReceive
    case registerTrackingNumber
    case registerMeeting
    case goToComments
    case checkMeeting
    case confirmExchange
    case completeExchange
    case writePartnerReview

    var label: String {
        switch self {
        case .none:                   return ""
        case .recordProgress:         return "진행률 기록"
        case .writeReadingCard:       return "독서카드 작성"
        case .writeBookReview:        return "책 후기 작성"
        case .editBookReview:         return "책 후기 수정"
        case .checkDeliveryInfo:      return "배송 정보 확인"
        case .checkShippingInfo:      return "운송장 정보 확인"
        case .confirmReceive:         return "수령 확인"
        case .registerTrackingNumber: return "운송장 등록"
        case .registerMeeting:        return "약속 등록"
        case .goToComments:           return "메시지로 이동"
        case .checkMeeting:           return "약속 확인"
        case .confirmExchange:        return "교환 확인"
        case .completeExchange:       return "교환 완료"
        case .writePartnerReview:     return "교환독서 후기 작성"
        }
    }
}

// displayStatus → (primary, secondary)
func actionsForStatus(_ displayStatus: String?) -> (primary: TrackerAction, secondary: TrackerAction) {
    switch displayStatus {
    case "READING":                            return (.recordProgress, .writeReadingCard)
    case "REVIEW_WRITING":                     return (.writeBookReview, .writeReadingCard)
    case "REVIEW_WAITING_PARTNER":             return (.editBookReview, .writeReadingCard)
    case "EXCHANGE_REVIEW_WRITING":            return (.writePartnerReview, .none)
    case "EXCHANGE_REVIEW_WAITING_PARTNER":    return (.writePartnerReview, .none)
    case "TRACKING_REQUIRED":                  return (.registerTrackingNumber, .checkDeliveryInfo)
    case "RETURN_TRACKING_REQUIRED":           return (.registerTrackingNumber, .checkDeliveryInfo)
    case "SHIPPING":                           return (.confirmReceive, .checkShippingInfo)
    case "RETURNING":                          return (.confirmReceive, .checkShippingInfo)
    case "WAITING_PARTNER_TRACKING_REGISTER":  return (.confirmReceive, .checkShippingInfo)
    case "WAITING_PARTNER_RECEIPT_CONFIRM":    return (.confirmReceive, .checkShippingInfo)
    case "MEETING_REGISTER_REQUIRED":          return (.goToComments, .registerMeeting)
    case "WAITING_HOST_MEETING_REGISTER":      return (.goToComments, .registerMeeting)
    case "EXCHANGING":                         return (.confirmExchange, .checkMeeting)
    case "WAITING_PARTNER_MEETING_COMPLETE":   return (.completeExchange, .none)
    default:                                   return (.none, .none)
    }
}

// secondary 버튼 비활성 상태
private let secondaryDisabledStatuses: Set<String> = [
    "WAITING_HOST_MEETING_REGISTER",
    "WAITING_PARTNER_TRACKING_REGISTER",
    "WAITING_PARTNER_RECEIPT_CONFIRM",
]

func isSecondaryActionDisabled(_ displayStatus: String?) -> Bool {
    guard let s = displayStatus else { return false }
    return secondaryDisabledStatuses.contains(s)
}

// primary 버튼 비활성 상태
private let primaryDisabledStatuses: Set<String> = [
    "WAITING_PARTNER_MEETING_COMPLETE",
    "WAITING_PARTNER_TRACKING_REGISTER",
    "WAITING_PARTNER_RECEIPT_CONFIRM",
    "EXCHANGE_REVIEW_WAITING_PARTNER",
]

func isPrimaryActionDisabled(_ displayStatus: String?) -> Bool {
    guard let s = displayStatus else { return false }
    return primaryDisabledStatuses.contains(s)
}

// 읽기 진행률 바·% 텍스트를 숨겨야 하는 상태 (교환 약속~교환 이후)
private let progressHiddenStatuses: Set<String> = [
    "MEETING_REGISTER_REQUIRED",
    "WAITING_HOST_MEETING_REGISTER",
    "EXCHANGING",
    "WAITING_PARTNER_MEETING_COMPLETE",
]

func isReadingProgressHidden(_ displayStatus: String?) -> Bool {
    guard let s = displayStatus else { return false }
    return progressHiddenStatuses.contains(s)
}

// 진행률 텍스트를 "%" 대신 다른 라벨로 표시해야 하는 상태
func progressTextOverride(_ displayStatus: String?, isMine: Bool) -> String? {
    switch displayStatus {
    case "TRACKING_REQUIRED", "RETURN_TRACKING_REQUIRED":
        return "운송장 등록 전"
    case "SHIPPING", "WAITING_PARTNER_TRACKING_REGISTER", "RETURNING":
        return "수령 전"
    case "WAITING_PARTNER_RECEIPT_CONFIRM":
        return isMine ? "수령 완료" : "수령 전"
    case "REVIEW_WAITING_PARTNER":
        return isMine ? "교환 준비 완료" : nil
    case "EXCHANGE_REVIEW_WRITING":
        return "수령 완료"
    case "EXCHANGE_REVIEW_WAITING_PARTNER":
        return isMine ? "교환독서 완료" : "수령 완료"
    default:
        return nil
    }
}
