import Foundation

// 안드로이드 온보딩 선택지(성별 · 기록 방식) 대응 — UI 무관 도메인 정의

// MARK: - 성별 (OnbStep1 성별 칩)

enum Gender: CaseIterable, Hashable {
    case female, male, unspecified

    var displayName: String {
        switch self {
        case .female:      return "여성"
        case .male:        return "남성"
        case .unspecified: return "선택 안함"
        }
    }

    var serverValue: String {
        switch self {
        case .female:      return "FEMALE"
        case .male:        return "MALE"
        case .unspecified: return "NONE"
        }
    }
}

// MARK: - 독서 기록 방식 (안드로이드 RecordMethod 대응)

enum RecordMethod: CaseIterable, Hashable {
    case memo, postit, photo, any

    var displayName: String {
        switch self {
        case .memo:   return "책에 직접 코멘트를 남겨요!"
        case .postit: return "직접 메모 대신 포스트잇이나 인덱스를 활용해요!"
        case .photo:  return "직접 메모 대신 사진으로 기록해요!"
        case .any:    return "어떤 방식이든 좋아요!"
        }
    }

    var iconSystemName: String {
        switch self {
        case .memo:   return "square.and.pencil"
        case .postit: return "bookmark.fill"
        case .photo:  return "camera.fill"
        case .any:    return "heart.fill"
        }
    }

    var serverValue: String {
        switch self {
        case .memo:   return "MEMO"
        case .postit: return "POSTIT"
        case .photo:  return "PHOTO"
        case .any:    return "All_ROUNDER"
        }
    }

    /// 다른 선택지와 함께 고를 수 없는 단독 선택 항목 (어떤 방식이든 좋아요)
    var isExclusive: Bool { self == .any }
}
