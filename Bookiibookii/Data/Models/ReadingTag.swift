import Foundation

// 그룹 독서 태그(코드) → 표시명 매핑. 공유 모델.
// 구 GroupCreateViewModel(그룹 생성 화면)이 GroupEditor로 교체되며 삭제됨에 따라,
enum ReadingTag: String, CaseIterable {
    case memo     = "MEMO"
    case postit   = "POSTIT"
    case clean    = "CLEAN"
    case serious  = "SERIOUS"
    case lightFun = "LIGHT_FUN"
    case insight  = "INSIGHT"

    var displayName: String {
        switch self {
        case .memo:     return "#메모환영"
        case .postit:   return "#포스트잇"
        case .clean:    return "#깔끔"
        case .serious:  return "#진지함"
        case .lightFun: return "#재미있게"
        case .insight:  return "#인사이트"
        }
    }

    var tagType: String {
        switch self {
        case .memo, .postit, .clean:        return "METHOD"
        case .serious, .lightFun, .insight: return "VIBE"
        }
    }
}
