import Foundation

enum LegalDocumentType: Hashable {
    case termsOfService
    case privacyPolicy

    var navigationTitle: String {
        switch self {
        case .termsOfService:
            return "서비스 이용 약관"
        case .privacyPolicy:
            return "개인정보 처리 방침"
        }
    }
}
