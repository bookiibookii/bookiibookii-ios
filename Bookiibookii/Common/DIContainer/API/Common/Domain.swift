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
        static let trackerDetailFmt        = "/api/groups/%@/tracker"
        static let trackerReadingFmt       = "/api/groups/%@/tracker/reading"
        static let trackerExtensionFmt     = "/api/groups/%@/tracker/extension"
        static let trackerDoneFmt          = "/api/groups/%@/tracker/done"
        static let trackerDeliveryFmt      = "/api/groups/%@/tracker/delivery"
        static let trackerReceptionFmt     = "/api/groups/%@/tracker/reception"
        static let trackerVerificationFmt  = "/api/groups/%@/tracker/reception/verification"
        static let trackerPresignedUrlFmt  = "/api/groups/%@/tracker/images/presigned-url"
        static let trackerImageDeliveryFmt = "/api/groups/%@/tracker/images/delivery"
        static let trackerImageReceivedFmt = "/api/groups/%@/tracker/images/received"
    }
}
