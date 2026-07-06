import Foundation

/// Vinny 스타일처럼 서버 주소/도메인별 path를 한곳에서 관리합니다.
enum API {
    static let baseURL = "https://bookii.gyeonseo.com"

    enum Path {
        static let auth = "/api/auth"
        static let users = "/api/users"
        static let onboarding = "/api/onboarding"
        static let mypage = "/api/mypage"
        static let mypageIntroduction = mypage + "/introduction"
        static let mypageBookshelf = mypage + "/bookshelf"
        static let mypageBookshelfRepresentativesOrder = mypageBookshelf + "/representatives/order"
        static func mypageBookshelfRepresentative(userBookId: Int) -> String {
            mypageBookshelf + "/representatives/\(userBookId)"
        }
        static let mypageBookshelfFavorites = mypageBookshelf + "/favorites"
        static func mypageBookshelfFavorite(userBookId: Int) -> String {
            mypageBookshelfFavorites + "/\(userBookId)"
        }
        static let mypageReviewsWritten = mypage + "/reviews/written"
        static let mypageReviewsReceived = mypage + "/reviews/received"
        static let groups = "/api/groups"
        static let books = "/api/books"
        static let recommendations = "/api/recommendations"
        static let notifications = "/api/notifications"
        static let notice = "/api/notice"
        static let faq = "/api/faq"
        static let keywords = "/api/keywords"
        static let library = "/api/library"
        static let reviews = "/api/reviews"
        static let deviceTokens = "/api/device-tokens"
        static let profiles = "/api/profiles"
        static func relayReview(userBookId: Int) -> String { "/api/reviews/relay/\(userBookId)" }
        static func togetherReview(userBookId: Int) -> String { "/api/reviews/together/\(userBookId)" }

        // 트래커 (안드로이드 TrkApi 기준 경로)
        static let myTrackers = "/api/me/trackers"
        static func trackerDetail(groupId: Int)          -> String { "/api/trackers/\(groupId)/tracker" }
        static func trackerReadingProgress(groupId: Int) -> String { "/api/trackers/\(groupId)/reading-progress" }
        static func trackerReadingPeriod(groupId: Int)   -> String { "/api/trackers/\(groupId)/reading-period" }

        // 그룹 하위 (홈/신청/후기/배송/약속 — 안드로이드 GrpApi 기준)
        static let homeGroups = groups + "/home"
        static let myHostedGroups = groups + "/my-hosted"
        static let applyMe = groups + "/apply/me"
        static func groupComments(groupId: Int) -> String { groups + "/\(groupId)/comments" }
        static func groupComment(groupId: Int, commentId: Int) -> String { groups + "/\(groupId)/comments/\(commentId)" }
        static func groupBookReviewsMe(groupId: Int) -> String { groups + "/\(groupId)/reviews/book/me" }
        static func groupReviews(groupId: Int) -> String { groups + "/\(groupId)/reviews" }
        static func groupBookReview(groupId: Int, reviewId: Int) -> String { groups + "/\(groupId)/reviews/book/\(reviewId)" }
        static func groupMemberReviews(groupId: Int) -> String { groups + "/\(groupId)/member-reviews" }
        static func groupDeliveries(groupId: Int) -> String { groups + "/\(groupId)/deliveries" }
        static func groupDeliveryAddress(groupId: Int) -> String { groups + "/\(groupId)/deliveries/address" }
        static func groupDeliveryAddressMeSaved(groupId: Int) -> String { groups + "/\(groupId)/deliveries/address/me/saved" }
        static func groupDeliveryAddressMeDirect(groupId: Int) -> String { groups + "/\(groupId)/deliveries/address/me/direct" }
        static func groupPartnerDelivery(groupId: Int) -> String { groups + "/\(groupId)/deliveries/partner" }
        static func groupPartnerDeliveryReceive(groupId: Int) -> String { groups + "/\(groupId)/deliveries/partner/receive" }
        static func groupMeetings(groupId: Int) -> String { groups + "/\(groupId)/meetings" }
        static func groupMeetingCompletion(groupId: Int) -> String { groups + "/\(groupId)/meetings/completion" }

        // 위치/배송지 (안드로이드 LocationApi 기준)
        static let exchangeAddresses = mypage + "/addresses/exchanges"
        static func exchangeAddress(id: Int) -> String { mypage + "/addresses/exchanges/\(id)" }
        static func exchangeAddressDefault(id: Int) -> String { mypage + "/addresses/exchanges/\(id)/default" }
        static let deliveryAddresses = mypage + "/addresses/deliveries"
        static func deliveryAddress(id: Int) -> String { mypage + "/addresses/deliveries/\(id)" }
        static func deliveryAddressDefault(id: Int) -> String { mypage + "/addresses/deliveries/\(id)/default" }

        // 유저 프로필 (안드로이드 UserApi 기준)
        static func userProfile(nickname: String) -> String { profiles + "/\(nickname)" }
    }
}
