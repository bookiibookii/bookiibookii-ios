import Foundation

enum NoticeAPITarget: APITargetType {
    case list
    case detail(noticeId: Int)

    var path: String {
        switch self {
        case .list:
            return API.Path.notice
        case .detail(let noticeId):
            return API.Path.notice + "/\(noticeId)"
        }
    }

    var method: HTTPMethod { .get }
}
