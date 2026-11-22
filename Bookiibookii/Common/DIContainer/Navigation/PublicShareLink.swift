import Foundation

/// 공유 링크로 진입해 스택 위에 띄우는 공개 화면.
/// 링크가 연달아 들어와도 화면이 교체되도록 하나의 `fullScreenCover`로 표시한다.
enum PublicShareLink: Identifiable, Equatable {
    case card(PublicCardShareLink)
    case profile(PublicProfileShareLink)

    var id: String {
        switch self {
        case .card(let link): return "card-\(link.id)"
        case .profile(let link): return "profile-\(link.id)"
        }
    }

    init?(url: URL) {
        if let link = PublicCardShareLink(url: url) {
            self = .card(link)
        } else if let link = PublicProfileShareLink(url: url) {
            self = .profile(link)
        } else {
            return nil
        }
    }

    /// `https://bookiibookii.com/share/{pathSegment}/{token}` 형식이면 토큰을 돌려준다.
    /// 경로는 맞지만 토큰이 잘못된 링크도 앱에서 오류 화면을 보여줘야 하므로 빈 토큰으로 돌려준다.
    static func universalLinkToken(from url: URL, pathSegment: String) -> String? {
        guard url.scheme?.lowercased() == "https",
              url.host?.lowercased() == "bookiibookii.com" else {
            return nil
        }

        // pathComponents 예: ["/", "share", "profile", "{token}"]
        let components = url.pathComponents
        guard components.count >= 3, components[1] == "share", components[2] == pathSegment else {
            return nil
        }
        return components.count == 4 ? sanitizedToken(components[3]) : ""
    }

    /// 토큰은 API 경로에 그대로 들어가므로 경로를 바꿀 수 있는 문자가 있으면 잘못된 토큰으로 처리한다.
    static func sanitizedToken(_ token: String) -> String {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
        return token.unicodeScalars.allSatisfy(allowed.contains) ? token : ""
    }
}
