import SwiftUI

// 안드 BookCover 대응 — round8 + 흰 배경 + grey100 1dp 테두리 + 1dp inset.
// 크기는 호출처 .frame(). URL/폴백 로직은 BookCoverImage 재사용.
// 표지 없음/로딩 시 흰 박스(placeholderColor .clear → 흰 배경이 비침).
struct BookCover: View {
    let imageUrl: String?

    init(imageUrl: String? = nil) {
        self.imageUrl = imageUrl
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color("white"))
            .overlay(
                // Color.clear가 프레임을 고정 → scaledToFill 오버플로우를 이 컨테이너 경계에서 클립.
                // (이미지에 직접 clipShape를 걸면 scaledToFill이 부풀린 자기 프레임 기준으로 클립돼 밖으로 넘침)
                Color.clear
                    .overlay(
                        BookCoverImage(imageUrl: imageUrl, placeholderColor: .clear)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .padding(1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color("grey100"), lineWidth: 1)
            )
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 12) {
        BookCover(imageUrl: nil)
            .frame(width: 100, height: 132)
        BookCover(imageUrl: "https://image.aladin.co.kr/product/0/0/cover500/x.jpg")
            .frame(width: 72, height: 100)
    }
    .padding()
    .background(Color("uiBg"))
}
#endif
