import Foundation

/// 외부 브라우저로 여는 링크 모음.
/// 안드로이드 `common/ExternalLink.kt`와 같은 주소를 사용해 두 플랫폼이 항상 같은 문서를 보여주도록 한다.
enum ExternalLink {
    /// 서비스 이용 약관
    static let termsOfService = URL(string: "https://www.bookiibookii.com/terms")!

    /// 개인정보 처리 방침
    static let privacyPolicy = URL(string: "https://www.bookiibookii.com/privacy")!
}
