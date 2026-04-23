import Foundation

// MARK: - API 응답

struct GroupListResponse: Codable {
    let isSuccess: Bool
    let code: String
    let message: String
    let result: GroupPageResult?
}

struct GroupPageResult: Codable {
    let groupList: [GroupItemDto]?
    let currentPage: Int
    let hasNext: Bool
}

struct GroupItemDto: Codable, Identifiable {
    let groupId: Int
    let title: String
    let author: String?
    let genre: String?
    let bookImage: String?
    let hostProfileImageUrl: String?
    let hostNickname: String?
    let tags: [String]?
    let groupStatus: String          // RECRUITING | MATCHED | COMPLETED | 기타
    let currentCount: Int
    let maxCapacity: Int
    let readingPeriod: Int
    let customTag: String?
    let groupType: String            // TOGETHER | RELAY
    let tradeType: String?           // DELIVERY | DIRECT | nil
    let startDate: String?
    let isHot: Bool
    let pictureBadge: String?

    var id: Int { groupId }
}

// MARK: - 표시용 파생 프로퍼티

extension GroupItemDto {
    var uiStatus: String {
        switch groupStatus {
        case "RECRUITING": return "모집 중"
        case "MATCHED":    return "진행 중"
        case "COMPLETED":  return "종료"
        default:           return "마감"
        }
    }
    var displayAuthor: String { author ?? "저자 미상" }
    var displayNickname: String { hostNickname ?? "알 수 없음" }
    var displayDate: String {
        guard let d = startDate else { return "날짜 미정" }
        return d.replacingOccurrences(of: "-", with: ".")
    }
    var displayGenre: String? {
        guard let g = genre, !g.isEmpty else { return nil }
        return "(\(g))"
    }
    var badgeText: String { pictureBadge ?? "모집" }
    var isTogether: Bool { groupType == "TOGETHER" }
}

// MARK: - 필터/정렬 enum

enum GroupSort: String {
    case recommend = "RECOMMEND"
    case latest = "LATEST"
    case popular = "POPULAR"

    var displayName: String {
        switch self {
        case .recommend: return "추천순"
        case .latest:    return "최신순"
        case .popular:   return "인기순"
        }
    }
}

enum GroupTypeFilter: String, CaseIterable, Identifiable {
    case together, delivery, direct
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .together: return "함께 읽기"
        case .delivery: return "택배 교환"
        case .direct:   return "직접 교환"
        }
    }
}

enum CategoryFilter: String, CaseIterable, Identifiable {
    case econBiz = "ECON_BIZ"
    case sciIt = "SCI_IT"
    case novelGenre = "NOVEL_GENRE"
    case poemEssay = "POEM_ESSAY"
    case homeHobby = "HOME_HOBBY"
    case artCulture = "ART_CULTURE"
    case humanHistory = "HUMAN_HISTORY"
    case selfDev = "SELF_DEV"
    case polSoc = "POL_SOC"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .econBiz:      return "경제/경영"
        case .sciIt:        return "과학/IT"
        case .novelGenre:   return "소설/장르"
        case .poemEssay:    return "시/에세이"
        case .homeHobby:    return "가정/취미"
        case .artCulture:   return "예술/문화"
        case .humanHistory: return "인문/역사"
        case .selfDev:      return "자기계발"
        case .polSoc:       return "정치/사회"
        }
    }
}

// MARK: - 지역 선택 상태

struct RegionSelection: Equatable {
    let city: String            // "" == 전체
    let districts: [String]     // [] && !city.isEmpty == "시도 전체"

    static let all = RegionSelection(city: "", districts: [])

    var isAll: Bool { city.isEmpty }
    var isCityAll: Bool { !city.isEmpty && districts.isEmpty }

    /// 메인 필터 칩에 표시할 라벨
    var chipLabel: String {
        if isAll { return "지역별" }
        if isCityAll { return city }
        return districts.joined(separator: " · ")
    }

    /// 바텀시트 상단 요약에 표시할 라벨
    var summaryLabel: String {
        if isAll { return "전체" }
        if isCityAll { return city }
        return districts.joined(separator: " · ")
    }

    /// 서버 `meetPlace` 파라미터
    var serverMeetPlace: [String]? {
        if isAll { return nil }
        if isCityAll { return [city] }
        return districts
    }
}

// MARK: - 태그 매퍼 (안드로이드 GroupTagMapper 포팅)

enum GroupTagMapper {
    static func koreanTag(_ raw: String) -> String {
        switch raw {
        // METHOD
        case "MEMO": return "#메모환영"
        case "POSTIT": return "#포스트잇"
        case "CLEAN": return "#깔끔하게"
        // VIBE
        case "SERIOUS": return "#진지함"
        case "LIGHT_FUN": return "#재미있게"
        case "INSIGHT": return "#인사이트"
        // SPEED
        case "FAST": return "#약 3일"
        case "NORMAL": return "#약 1주"
        case "SLOW": return "#약 1개월"
        case "UNKNOWN": return "#속도모름"
        // GENRE
        case "ECON_BIZ": return "#경제/경영"
        case "SCI_IT": return "#과학/IT"
        case "NOVEL_GENRE": return "#소설/장르"
        case "POEM_ESSAY": return "#시/에세이"
        case "HOME_HOBBY": return "#가정/취미"
        case "ART_CULTURE": return "#예술/문화"
        case "HUMAN_HISTORY": return "#인문/역사"
        case "SELF_DEV": return "#자기계발"
        case "POL_SOC": return "#정치/사회"
        case "ESC": return "#기타"
        // REVIEW
        case "KINDNESS": return "#친절매너"
        case "GOOD_HANDWRITING": return "#예쁜글씨"
        case "SWEET_COMMENT": return "#다정한코멘트"
        case "INSIGHTFUL": return "#인사이트넘침"
        case "FAST_SHIPPING": return "#빠른배송"
        case "FUNNY": return "#재미있는코멘트"
        case "CLEAN_CONDITION": return "#깔끔한상태"
        default:
            return raw.hasPrefix("#") ? raw : "#\(raw)"
        }
    }
}

// MARK: - 검색 API 응답

struct PopularKeywordsResponse: Codable {
    let isSuccess: Bool
    let result: [String]
}

struct GroupSearchResponse: Codable {
    let isSuccess: Bool
    let code: String
    let message: String
    let result: GroupSearchResult?
}

struct GroupSearchResult: Codable {
    let groupList: [GroupItemDto]
    let totalCount: Int
    let currentPage: Int
    let hasNext: Bool
}

// MARK: - 도서 검색

struct BookSearchAPIResponse: Codable {
    let isSuccess: Bool
    let code: String
    let message: String
    let result: BookSearchResultData?
}

struct BookSearchResultData: Codable {
    let books: [BookItem]
    let totalPage: Int
    let totalResults: Int
}

struct BookItem: Codable, Identifiable {
    let title: String
    let author: String
    let image: String
    let publisher: String
    let isbn13: String
    let category: String
    let categoryLabel: String
    let link: String
    var id: String { isbn13 }
}

// MARK: - 그룹 생성 요청

struct GroupCreateRequest: Encodable {
    let isbn13: String
    let maxCapacity: Int
    let startDate: String          // "yyyy-MM-dd"
    let readingPeriod: Int
    let groupComment: String
    let customTag: String          // 없으면 ""
    let groupType: String          // "RELAY" | "TOGETHER"
    let tradeType: String          // "DELIVERY" | "DIRECT" | "NONE"
    let preferRegion: String       // 없으면 ""
    let meetPlace: String          // 없으면 ""
    let tags: [GroupTagRequest]
}

struct GroupTagRequest: Encodable {
    let type: String               // "METHOD" | "VIBE"
    let value: [String]
}
