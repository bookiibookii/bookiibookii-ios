import Foundation

/// 공유된 독서카드 링크로 앱에 진입했을 때 공개 카드 뷰어에 넘길 정보.
struct PublicCardShareLink: Identifiable, Equatable {
    let shareToken: String

    var id: String { shareToken }

    /// - 유니버설 링크: `https://bookiibookii.com/share/reading-card/{token}`
    /// - 카카오톡 공유 메시지의 "보러가기": `kakao{앱키}://kakaolink?shareToken=…`
    init?(url: URL) {
        if let token = PublicShareLink.universalLinkToken(from: url, pathSegment: "reading-card") {
            shareToken = token
            return
        }

        guard url.scheme?.hasPrefix("kakao") == true,
              url.host == "kakaolink",
              let token = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "shareToken" })?
                .value,
              !token.isEmpty else {
            return nil
        }
        shareToken = PublicShareLink.sanitizedToken(token)
    }
}
