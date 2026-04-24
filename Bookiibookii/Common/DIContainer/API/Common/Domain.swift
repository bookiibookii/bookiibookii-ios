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
    }
}
