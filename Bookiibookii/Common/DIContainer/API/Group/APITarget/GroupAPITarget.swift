import Foundation

enum GroupAPITarget: APITargetType {
    case fetchGroups(tradeTypes: [String]?, regions: [String]?, categories: [String]?, sort: GroupSort, page: Int, size: Int)
    case popularKeywords
    case searchGroups(keyword: String, sort: GroupSort, page: Int, size: Int)
    case searchBooks(keyword: String, page: Int, size: Int)
    case createGroup(GroupCreateRequest)
    case fetchGroupDetail(groupId: Int)
    case applyGroup(groupId: Int, body: GroupApplyRequest)
    case cancelApply(groupId: Int)
    case fetchApplicants(groupId: Int)
    case updateApplicant(applicationId: Int, body: GroupAppStatusRequest)
    case modifyGroup(groupId: Int, body: GroupModifyRequest)
    case deleteGroup(groupId: Int)
    case completeTogetherReading(groupId: Int)
    case createTogetherReview(userBookId: Int, body: TogetherReviewCreateRequest)
    case homeGroups
    case myHostedGroups
    case appliedGroups
    case postComment(groupId: Int, body: CommentCreateRequest)
    case fetchComments(groupId: Int)
    case deleteComment(groupId: Int, commentId: Int)

    var path: String {
        switch self {
        case .fetchGroups, .createGroup:
            return API.Path.groups
        case .popularKeywords:
            return API.Path.groups + "/popular-keywords"
        case .searchGroups:
            return API.Path.groups + "/search"
        case .searchBooks:
            return API.Path.books + "/search"
        case .homeGroups:
            return API.Path.homeGroups
        case .myHostedGroups:
            return API.Path.myHostedGroups
        case .appliedGroups:
            return API.Path.applyMe
        case .fetchGroupDetail(let groupId),
             .modifyGroup(let groupId, _),
             .deleteGroup(let groupId):
            return API.Path.groups + "/\(groupId)"
        case .applyGroup(let groupId, _), .cancelApply(let groupId):
            return API.Path.groups + "/\(groupId)/apply"
        case .fetchApplicants(let groupId):
            return API.Path.groups + "/\(groupId)/applylist"
        case .completeTogetherReading(let groupId):
            return API.Path.groups + "/\(groupId)/together/members/me/complete"
        case .createTogetherReview(let userBookId, _):
            return "/api/reviews/together/\(userBookId)"
        case .updateApplicant(let applicationId, _):
            return API.Path.groups + "/apply/\(applicationId)"
        case .postComment(let groupId, _), .fetchComments(let groupId):
            return API.Path.groupComments(groupId: groupId)
        case .deleteComment(let groupId, let commentId):
            return API.Path.groupComment(groupId: groupId, commentId: commentId)
        }
    }

    var method: HTTPMethod {
        switch self {
        case .createGroup, .applyGroup, .createTogetherReview, .postComment: return .post
        case .modifyGroup, .updateApplicant, .completeTogetherReading: return .patch
        case .cancelApply, .deleteGroup, .deleteComment:        return .delete
        default:                                return .get
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .fetchGroups(let tradeTypes, let regions, let categories, let sort, let page, let size):
            var items = [
                URLQueryItem(name: "sort", value: sort.rawValue),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "size", value: String(size))
            ]
            tradeTypes?.forEach { items.append(URLQueryItem(name: "tradeTypes", value: $0)) }
            regions?.forEach { items.append(URLQueryItem(name: "regions", value: $0)) }
            categories?.forEach { items.append(URLQueryItem(name: "categories", value: $0)) }
            return items
        case .searchGroups(let keyword, let sort, let page, let size):
            return [
                URLQueryItem(name: "keyword", value: keyword),
                URLQueryItem(name: "sort", value: sort.rawValue),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "size", value: String(size))
            ]
        case .searchBooks(let keyword, let page, let size):
            return [
                URLQueryItem(name: "keyword", value: keyword),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "size", value: String(size))
            ]
        default:
            return []
        }
    }

    var body: Data? {
        switch self {
        case .createGroup(let request):           return try? JSONEncoder().encode(request)
        case .applyGroup(_, let body):            return try? JSONEncoder().encode(body)
        case .updateApplicant(_, let body):       return try? JSONEncoder().encode(body)
        case .modifyGroup(_, let body):           return try? JSONEncoder().encode(body)
        case .createTogetherReview(_, let body):  return try? JSONEncoder().encode(body)
        case .postComment(_, let body):           return try? JSONEncoder().encode(body)
        default:                                   return nil
        }
    }

    var headers: [String: String] {
        switch self {
        case .createGroup, .applyGroup, .updateApplicant, .modifyGroup, .createTogetherReview, .postComment:
            return ["Content-Type": "application/json"]
        default:
            return [:]
        }
    }
}
