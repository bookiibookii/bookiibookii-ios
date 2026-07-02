import SwiftUI

struct ExchangePlaceSearchOverlay: View {
    let onClose: () -> Void
    let onSelect: (KakaoPlaceResult) -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                KakaoPlaceSearchView { place in
                    onSelect(place)
                    onClose()
                }
            }
            .background(Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.top, 8)
        }
        .transition(.opacity)
    }

    private var header: some View {
        ZStack {
            Text("장소 검색")
                .pretendardText(size: 18, weight: .medium)
                .foregroundColor(Color("grey900"))

            HStack {
                Button(action: onClose) {
                    Text("닫기")
                        .pretendardText(size: 16, weight: .regular)
                        .foregroundColor(Color("grey900"))
                        .frame(height: 44)
                        .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .frame(height: 52)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color("grey200")).frame(height: 1)
        }
    }
}
