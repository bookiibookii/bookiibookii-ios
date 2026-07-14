import SwiftUI
import Kingfisher

// 안드 BookCover 대응 — 알라딘 표지를 cover500(고화질)로 표시, 실패 시 cover200으로 1회 폴백.
// 프레임/모양은 호출처에서 지정(.frame, .clipShape 등).
struct BookCoverImage: View {
    let imageUrl: String?
    var placeholderColor: Color = Color("grey200")
    @State private var useFallback = false

    var body: some View {
        KFImage(resolvedURL)
            .placeholder { placeholderColor }
            .onFailure { _ in
                // cover500이 없는 책 → cover200으로 1회 폴백.
                if !useFallback { useFallback = true }
            }
            .resizable()
            .scaledToFill()
            .id(useFallback)   // 폴백 전환 시 KFImage 재생성
    }

    private var resolvedURL: URL? {
        guard let base = imageUrl, !base.isEmpty else { return nil }
        let sized = base.toAladinCover(useFallback ? "cover200" : "cover500")
        return URL(string: sized)
    }
}
