import Foundation

/// Vinny 스타일처럼 서버 주소/도메인별 path를 한곳에서 관리합니다.
enum API {
    static let baseURL = "https://bookii.gyeonseo.com"

    enum Path {
        static let auth = "/api/auth"
        static let users = "/api/users"
        static let onboarding = "/api/onboarding"
        static let mypage = "/api/mypage"
        static let groups = "/api/groups"
        static let books = "/api/books"
        static let recommendations = "/api/recommendations"
        static let notifications = "/api/notifications"
        static let keywords = "/api/keywords"
        static let trackers = "/api/groups/me/trackers"
        static let library = "/api/library"
        static func trackerDetail(groupId: Int)        -> String { "/api/groups/\(groupId)/tracker" }
        static func trackerReading(groupId: Int)       -> String { "/api/groups/\(groupId)/tracker/reading" }
        static func trackerPeriodExtension(groupId: Int) -> String { "/api/groups/\(groupId)/tracker/extension" }
        static func trackerDone(groupId: Int)          -> String { "/api/groups/\(groupId)/tracker/done" }
        static func trackerDelivery(groupId: Int)      -> String { "/api/groups/\(groupId)/tracker/delivery" }
        static func trackerReception(groupId: Int)     -> String { "/api/groups/\(groupId)/tracker/reception" }
        static func trackerVerification(groupId: Int)  -> String { "/api/groups/\(groupId)/tracker/reception/verification" }
        static func trackerPresignedUrl(groupId: Int)  -> String { "/api/groups/\(groupId)/tracker/images/presigned-url" }
        static func trackerImageDelivery(groupId: Int) -> String { "/api/groups/\(groupId)/tracker/images/delivery" }
        static func trackerImageReceived(groupId: Int) -> String { "/api/groups/\(groupId)/tracker/images/received" }
        static func trackerMeetings(groupId: Int)          -> String { "/api/groups/\(groupId)/tracker/meetings" }
        static func trackerMeetingCompletion(groupId: Int) -> String { "/api/groups/\(groupId)/tracker/meetings/completion" }
    }
}
