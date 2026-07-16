import SwiftUI

/// 장소 검색 전체 화면. 시트 위 또 다른 시트가 아니라, 네비게이션처럼 화면을 덮습니다.
struct ExchangePlaceSearchOverlay: View {
    let onClose: () -> Void
    let onSelect: (KakaoPlaceResult) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            KakaoPlaceSearchView { place in
                onSelect(place)
                onClose()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("white").ignoresSafeArea())
        .transition(.move(edge: .trailing).combined(with: .opacity))
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
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color("grey200")).frame(height: 1)
        }
    }
}
