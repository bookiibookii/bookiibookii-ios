import Foundation

// 안드로이드 TrkMainViewModel.TrackerTab 대응.
enum TrackerTab: Int, CaseIterable, Identifiable {
    case myGroup     // 내 그룹 (host)
    case joined      // 참여한 그룹 (guest)

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .myGroup: return "내 그룹"
        case .joined:  return "참여한 그룹"
        }
    }

    /// 리스트 비어있을 때 표시할 빈 카드 상단 문구
    var emptyTitle: String {
        switch self {
        case .myGroup: return "아직 그룹을 만들지 않았어요 😭"
        case .joined:  return "아직 참여한 그룹이 없어요 😭"
        }
    }

    /// 리스트 비어있을 때 표시할 빈 카드 설명 문구
    var emptyDescription: String {
        switch self {
        case .myGroup: return "읽고 싶은 책을 골라 그룹을 만들어볼까요?"
        case .joined:  return "독서 그룹에 참여하러 가볼까요?"
        }
    }
}

/// 안드로이드 TrackerAdapter.mapCategoryToKo 대응.
enum TrackerCategoryMapper {
    static func displayKo(_ raw: String?) -> String {
        guard let key = raw?.trimmingCharacters(in: .whitespaces), !key.isEmpty else { return "" }
        switch key {
        case "ECON_BIZ":      return "경제/경영"
        case "SCI_IT":        return "과학/IT"
        case "NOVEL_GENRE":   return "소설"
        case "POEM_ESSAY":    return "시/에세이"
        case "HOME_HOBBY":    return "가정/취미"
        case "ART_CULTURE":   return "예술/문화"
        case "HUMAN_HISTORY": return "인문/역사"
        case "SELF_DEV":      return "자기계발"
        case "POL_SOC":       return "정치/사회"
        case "ETC":           return "기타"
        default:              return key
        }
    }
}
