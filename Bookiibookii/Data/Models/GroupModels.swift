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
    let totalCount: Int?           // 안드 신규
    let currentPage: Int
    let hasNext: Bool
}

struct GroupItemDto: Codable, Identifiable {
    let groupId: Int
    let groupName: String?           // 안드 신규
    let title: String?               // 안드 GroupItem.title 은 nullable (bookTitle alt)
    let author: String?
    let genre: String?
    let bookImage: String?
    let hostProfileImageUrl: String?
    let hostNickname: String?
    let tags: [String]?
    let groupStatus: String          // RECRUITING | MATCHED | COMPLETED | 기타
    let currentCount: Int
    let maxCapacity: Int
    let waitingCount: Int?           // 안드 신규
    let readingPeriod: Int
    let customTag: String?
    let groupType: String?           // 안드 GroupItem.groupType 은 nullable (nil → RELAY 취급)
    let tradeType: String?           // DELIVERY | DIRECT | nil
    let startDate: String?
    let isHot: Bool
    let pictureBadge: String?
    let displayStatus: String?       // 안드 신규

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

// 안드 GroupCreateRequest 대응
struct GroupCreateRequest: Encodable {
    let isbn13: String
    let groupName: String
    let tradeType: String           // DIRECT | DELIVERY
    let userDeliveryId: Int?        // DELIVERY일 때만
    let userExchangeId: Int?        // DIRECT일 때만
    let readingPeriod: Int          // 3, 7, 14, 21, 28
    let groupComment: String?       // 선택, 최대 500자
    let rules: [GroupRuleRequest]   // 1~5개
}

// 안드 GroupRuleRequest 대응
struct GroupRuleRequest: Encodable {
    let tag: String                 // MEMO/POSTIT/PHOTO/All_ROUNDER/NO_IDEA/CUSTOM
    let content: String?            // CUSTOM일 때만 텍스트
}

// 안드 GroupModifyRequest 대응
struct GroupModifyRequest: Encodable {
    let readingPeriod: Int
    let groupComment: String?
    let groupName: String
    let rules: [GroupRuleRequest]
}

// MARK: - 그룹 수정 응답

struct GroupModifyResultWrapper: Codable {
    let isSuccess: Bool
    let code: String
    let message: String
}

// MARK: - 그룹 상세

struct GroupDetailResponse: Codable {
    let isSuccess: Bool
    let code: String
    let message: String
    let result: GroupDetailDto?
}

// 안드 GroupDetailResponse 대응
struct GroupDetailDto: Codable {
    let groupId: Int
    let groupStatus: String       // RECRUITING | MATCHED
    let isHost: Bool
    let tradeType: String         // DIRECT | DELIVERY
    let placeName: String
    let address: String
    let detailAddress: String     // 없으면 ""
    let title: String
    let bookImage: String?
    let author: String
    let genre: String
    let readingPeriod: Int
    let matchedCount: Int
    let maxCapacity: Int
    let waitingCount: Int
    let isHot: Bool
    let createdAt: String
    let startDate: String?        // 미시작 시 null
    let hostNickname: String
    let hostProfileImageUrl: String?
    let groupComment: String?
    let groupName: String
    let rules: [GroupRule]
    let participantSlots: [ParticipantSlot]
    let buttonStatus: String      // APPLY | CANCEL | MANAGE | TRACKER | FULL
}

// 안드 GroupRule (응답 전용)
struct GroupRule: Codable {
    let tag: String
    let content: String
}

struct ParticipantSlot: Codable {
    let nickname: String?
    let profileImageUrl: String?
    let role: String              // HOST | GUEST | EMPTY
    let isMe: Bool
}

// MARK: - 신청 / 취소

struct GroupApplyRequest: Encodable {
    let isbn13: String              // 교환할 책 ISBN13
    let applyMsg: String            // 신청 한 마디 (0~50자)
}

struct GroupApplyResultWrapper: Codable {
    let isSuccess: Bool
    let code: String
    let message: String
}

struct GroupCancelResultWrapper: Codable {
    let isSuccess: Bool
    let code: String
    let message: String
}

// MARK: - 신청자 목록 (호스트용)

struct GroupApplicantListResponse: Codable {
    let isSuccess: Bool
    let code: String
    let message: String
    let result: GroupApplicantListResult?
}

struct GroupApplicantListResult: Codable {
    let applicationList: [GroupApplicantDto]
    let totalCount: Int
}

// 안드 GroupAppItem 대응
struct GroupApplicantDto: Codable, Identifiable {
    let applicationId: Int?
    let user: Int?
    let name: String?
    let profileImageUrl: String?   // null=프로필 미등록
    let createdAt: String?
    let applyMsg: String?
    let bookTitle: String?
    let bookAuthor: String?
    let bookImage: String?
    var id: Int { applicationId ?? 0 }
}

struct GroupAppStatusRequest: Encodable {
    let status: String            // ACCEPTED | REJECTED
}

struct GroupAppStatusResponse: Codable {
    let isSuccess: Bool
    let code: String
    let message: String
}

struct GroupDeleteResultWrapper: Codable {
    let isSuccess: Bool
    let code: String
    let message: String
}

/// PATCH `/api/groups/{groupId}/together/members/me/complete` 의 `result`.
struct TogetherCompleteReadingResultDTO: Decodable {
    let matchedMemberId: Int?
    let currentReadingRate: Int?
    let completedAt: String?
}

/// POST `/api/reviews/together/{userBookId}` request body.
struct TogetherReviewCreateRequest: Encodable {
    let rating: Double
    let comment: String?
}

// MARK: - 홈 그룹 (GET /api/groups/home)

struct HomeGroupsResponse: Decodable {
    let sections: [HomeSection]
}

struct HomeSection: Decodable {
    let sectionType: String
    let title: String
    let subtitle: String
    let layoutType: String
    let items: [HomeSectionItem]
}

struct HomeSectionItem: Decodable {
    // 공통
    let author: String?
    let bookImage: String?
    // 책 항목
    let isbn13: String?
    let title: String?
    let searchKeyword: String?
    let rank: Int?
    // 그룹 항목
    let groupId: Int?
    let groupName: String?
    let hostNickname: String?
    let hostProfileImageUrl: String?
    let bookTitle: String?
    let readingPeriod: Int?
    let tradeType: String?    // DIRECT | DELIVERY
    let genre: String?
}

enum HomeLayoutType {
    static let groupCardCarousel    = "GROUP_CARD_CAROUSEL"
    static let bookThumbnailCarousel = "BOOK_THUMBNAIL_CAROUSEL"
    static let bookThumbnailGrid     = "BOOK_THUMBNAIL_GRID"
}

// MARK: - 신청한 그룹 (GET /api/groups/apply/me)

struct AppliedGroupsResponse: Decodable {
    let applicationList: [AppliedGroupItem]
    let totalCount: Int
}

struct AppliedGroupItem: Decodable, Identifiable {
    let groupId: Int
    let groupName: String
    let hostNickname: String?
    let hostProfileImageUrl: String?
    let bookImage: String?
    let bookTitle: String?
    let author: String?
    let readingPeriod: Int
    let applicationStatus: String?
    let tradeType: String?
    let pictureBadge: String?

    var id: Int { groupId }
}

// MARK: - 그룹 댓글 (안드 CommentList / CommentCreate)

struct CommentWriter: Decodable, Equatable {
    let userId: Int
    let name: String
    let profileImage: String?
    let role: String

    enum CodingKeys: String, CodingKey {
        case userId, name, role
        case profileImage = "profileImageUrl"
    }
}

struct CommentItem: Decodable, Identifiable, Equatable {
    let id: Int
    let deleted: Bool
    let secret: Bool
    let content: String
    let parentId: Int?
    let writer: CommentWriter
    let createdAt: String
    let children: [CommentItem]?
}

struct CommentCreateRequest: Encodable {
    let content: String
    let parentId: Int?
    let secret: Bool

    init(content: String, parentId: Int? = nil, secret: Bool = false) {
        self.content = content
        self.parentId = parentId
        self.secret = secret
    }
}

struct CommentCreateResponse: Decodable {
    let commentId: Int
    let groupId: Int
    let parentId: Int?
    let content: String
    let createdAt: String
    let writer: CommentWriter
}

