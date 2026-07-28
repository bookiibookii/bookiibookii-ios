import Foundation

/// 안드로이드 `ErrorType` 대응 (COM-03 공통 에러).
enum BookiiErrorType: String, Identifiable, Hashable {
    case system
    case network
    case noPermission
    case groupDeleted
    case groupClosed

    var id: String { rawValue }

    /// 404 일러스트 (`img_404_graphic`) vs Error 일러스트 (`img_error_graphic`)
    var uses404Artwork: Bool {
        switch self {
        case .noPermission, .groupDeleted, .groupClosed: return true
        case .system, .network: return false
        }
    }

    var title: String {
        switch self {
        case .system: return "현재 서비스 이용이 원활하지 않습니다."
        case .network: return "네트워크 연결 오류입니다."
        case .noPermission: return "접근 권한이 없는 페이지입니다."
        case .groupDeleted: return "삭제된 페이지입니다."
        case .groupClosed: return "종료된 그룹입니다."
        }
    }

    var subtitle: String? {
        switch self {
        case .network:
            return "현재 네트워크에 연결되어 있지 않습니다.\n확인 후 다시 시도해주세요."
        default:
            return nil
        }
    }

    /// true: [메인으로 이동] 단일 CTA (404 계열)
    var showsMainOnlyCTA: Bool { uses404Artwork }
}
