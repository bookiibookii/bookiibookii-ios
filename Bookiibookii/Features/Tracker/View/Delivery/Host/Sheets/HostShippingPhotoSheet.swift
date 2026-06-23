import SwiftUI

// 안드 fragment_host_shipping_photo_dialog.xml (HostShippingPhotoDialogFragment) 대응.
// 등록한 배송 인증 사진을 다시 보여주는 다이얼로그.
struct HostShippingPhotoSheet: View {
    let imageUrl: String?
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("배송 인증")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))
                .frame(maxWidth: .infinity, alignment: .center)

            ZStack {
                Color("grey100")
                if let urlString = imageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Text("사진을 불러오는 중...")
                                .pretendardText(size: 14)
                                .foregroundColor(Color("grey500"))
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            Text("사진을 불러올 수 없어요")
                                .pretendardText(size: 14)
                                .foregroundColor(Color("grey500"))
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Text("이미지를 불러오는 중...")
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey500"))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 190)
            .clipped()
            .padding(.top, 12)

            Button(action: onConfirm) {
                Text("확인")
                    .pretendardText(size: 14, weight: .medium)
                    .foregroundColor(Color("grey100"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color("grey900"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

#Preview("HostShippingPhoto") {
    ZStack {
        Color.black.opacity(0.4).ignoresSafeArea()
        HostShippingPhotoSheet(imageUrl: nil, onConfirm: {})
            .padding(20)
    }
}
