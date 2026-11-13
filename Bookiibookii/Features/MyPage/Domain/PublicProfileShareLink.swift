import Foundation

/// 공유된 프로필 링크로 앱에 진입했을 때 공개 프로필 화면에 넘길 정보.
struct PublicProfileShareLink: Identifiable, Equatable {
    let shareToken: String
    let isDark: Bool

    var id: String { "\(shareToken)-\(isDark)" }

    /// `https://bookiibookii.com/share/profile/{token}?dark=1`
    init?(url: URL) {
        guard let token = PublicShareLink.universalLinkToken(from: url, pathSegment: "profile") else {
            return nil
        }
        shareToken = token
        isDark = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "dark" })?
            .value == "1"
    }
}
