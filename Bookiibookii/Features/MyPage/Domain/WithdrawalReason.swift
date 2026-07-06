import Foundation

enum WithdrawalReason: String, CaseIterable, Codable, Hashable {
    case hardToFindPartner = "HARD_TO_FIND_PARTNER"
    case inconvenientExchange = "INCONVENIENT_EXCHANGE"
    case difficultAppUsage = "DIFFICULT_APP_USAGE"
    case infrequentExchange = "INFREQUENT_EXCHANGE"
    case privacyConcern = "PRIVACY_CONCERN"
    case customInput = "CUSTOM_INPUT"

    var displayName: String {
        switch self {
        case .hardToFindPartner: return "원하는 파트너를 찾기 어려워요"
        case .inconvenientExchange: return "교환 과정이 번거롭고 불편해요"
        case .difficultAppUsage: return "앱 사용이 어렵고 불편해요"
        case .infrequentExchange: return "교환독서를 자주 하지 않아요"
        case .privacyConcern: return "개인정보가 걱정돼요"
        case .customInput: return "직접 입력"
        }
    }
}

struct WithdrawalRequest: Encodable {
    let reason: WithdrawalReason
    let customReason: String?
}
