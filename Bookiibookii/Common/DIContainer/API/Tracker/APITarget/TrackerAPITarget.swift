import Foundation

// 안드로이드 TrkApi 대응 (신규 트래커 구조).
enum TrackerAPITarget: APITargetType {
    case myTrackers
    case detail(groupId: Int)
    case readingProgress(groupId: Int, body: ReadingProgressReqDTO)
    case readingPeriod(groupId: Int, body: ReadingPeriodUpdateReqDTO)

    case myBookReviews(groupId: Int)
    case postBookReview(groupId: Int, body: BookReviewReqDTO)
    case patchBookReview(groupId: Int, reviewId: Int, body: BookReviewReqDTO)
    case updateMyGroupReviews(groupId: Int, body: MyGroupReviewsUpdateRequestBody)
    case postMemberReview(groupId: Int, body: MemberReviewCreateReqDTO)

    case registerDelivery(groupId: Int, body: DeliveryRegisterReqDTO)

    case registerMeeting(groupId: Int, body: MeetingRegisterReqDTO)
    case fetchMeeting(groupId: Int)
    case updateMeeting(groupId: Int, body: MeetingRegisterReqDTO)
    case completeMeeting(groupId: Int)

    case deliveryAddress(groupId: Int)
    case updateDeliveryAddressSaved(groupId: Int, body: DeliveryAddressSavedUpdateReqDTO)
    case updateDeliveryAddressDirect(groupId: Int, body: DeliveryAddressDirectUpdateReqDTO)
    case partnerDelivery(groupId: Int)
    case confirmPartnerReceive(groupId: Int)

    var path: String {
        switch self {
        case .myTrackers:
            return API.Path.myTrackers
        case .detail(let id):
            return API.Path.trackerDetail(groupId: id)
        case .readingProgress(let id, _):
            return API.Path.trackerReadingProgress(groupId: id)
        case .readingPeriod(let id, _):
            return API.Path.trackerReadingPeriod(groupId: id)
        case .myBookReviews(let id):
            return API.Path.groupBookReviewsMe(groupId: id)
        case .postBookReview(let id, _):
            return API.Path.groupReviews(groupId: id)
        case .patchBookReview(let id, let reviewId, _):
            return API.Path.groupBookReview(groupId: id, reviewId: reviewId)
        case .updateMyGroupReviews(let id, _):
            return API.Path.groupReviewsMyGroup(groupId: id)
        case .postMemberReview(let id, _):
            return API.Path.groupMemberReviews(groupId: id)
        case .registerDelivery(let id, _):
            return API.Path.groupDeliveries(groupId: id)
        case .registerMeeting(let id, _), .fetchMeeting(let id), .updateMeeting(let id, _):
            return API.Path.groupMeetings(groupId: id)
        case .completeMeeting(let id):
            return API.Path.groupMeetingCompletion(groupId: id)
        case .deliveryAddress(let id):
            return API.Path.groupDeliveryAddress(groupId: id)
        case .updateDeliveryAddressSaved(let id, _):
            return API.Path.groupDeliveryAddressMeSaved(groupId: id)
        case .updateDeliveryAddressDirect(let id, _):
            return API.Path.groupDeliveryAddressMeDirect(groupId: id)
        case .partnerDelivery(let id):
            return API.Path.groupPartnerDelivery(groupId: id)
        case .confirmPartnerReceive(let id):
            return API.Path.groupPartnerDeliveryReceive(groupId: id)
        }
    }

    var method: HTTPMethod {
        switch self {
        case .myTrackers, .detail, .myBookReviews, .fetchMeeting,
             .deliveryAddress, .partnerDelivery:
            return .get
        case .postBookReview, .postMemberReview, .registerDelivery, .registerMeeting:
            return .post
        case .readingProgress, .readingPeriod, .patchBookReview, .updateMyGroupReviews,
             .updateMeeting, .completeMeeting, .confirmPartnerReceive:
            return .patch
        case .updateDeliveryAddressSaved, .updateDeliveryAddressDirect:
            return .put
        }
    }

    var body: Data? {
        switch self {
        case .readingProgress(_, let body):            return try? JSONEncoder().encode(body)
        case .readingPeriod(_, let body):              return try? JSONEncoder().encode(body)
        case .postBookReview(_, let body):             return try? JSONEncoder().encode(body)
        case .patchBookReview(_, _, let body):         return try? JSONEncoder().encode(body)
        case .updateMyGroupReviews(_, let body):       return try? JSONEncoder().encode(body)
        case .postMemberReview(_, let body):           return try? JSONEncoder().encode(body)
        case .registerDelivery(_, let body):           return try? JSONEncoder().encode(body)
        case .registerMeeting(_, let body):            return try? JSONEncoder().encode(body)
        case .updateMeeting(_, let body):              return try? JSONEncoder().encode(body)
        case .updateDeliveryAddressSaved(_, let body): return try? JSONEncoder().encode(body)
        case .updateDeliveryAddressDirect(_, let body): return try? JSONEncoder().encode(body)
        default:                                        return nil
        }
    }

    var headers: [String: String] {
        switch self {
        case .readingProgress, .readingPeriod, .postBookReview, .patchBookReview, .updateMyGroupReviews,
             .postMemberReview, .registerDelivery, .registerMeeting, .updateMeeting,
             .updateDeliveryAddressSaved, .updateDeliveryAddressDirect:
            return ["Content-Type": "application/json"]
        default:
            return [:]
        }
    }
}
