import SwiftUI
import Kingfisher

/// S3 presigned URL 이미지를 캐시와 함께 표시한다.
///
/// presigned URL은 응답마다 서명(`X-Amz-Signature` 등)이 새로 붙어 전체 URL이 매번 달라지므로,
/// URL을 그대로 캐시 키로 쓰면 화면을 다시 열 때마다 재다운로드가 발생한다.
/// 쿼리를 제외한 경로(`.../image/cards/{uuid}`)는 이미지가 교체되기 전까지 고정이므로 이를 캐시 키로 사용한다.
struct PresignedRemoteImage: View {
    let urlString: String?
    var placeholderColor: Color = Color("grey200")

    var body: some View {
        placeholderColor
            .overlay {
                if let source {
                    KFImage(source: source)
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
    }

    private var source: Source? {
        guard let urlString, let url = URL(string: urlString) else { return nil }
        return .network(KF.ImageResource(downloadURL: url, cacheKey: url.presignedCacheKey))
    }
}

extension URL {
    /// 쿼리(서명 파라미터)를 제외한 URL 문자열. presigned URL의 안정적인 캐시 키로 쓴다.
    var presignedCacheKey: String {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return absoluteString
        }
        components.query = nil
        return components.url?.absoluteString ?? absoluteString
    }
}
