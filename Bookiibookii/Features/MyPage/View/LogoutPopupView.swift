import SwiftUI

struct LogoutPopupView: View {
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                Text("로그아웃")
                    .pretendardText(size: 20, weight: .semibold)
                    .foregroundColor(Color("grey900"))

                Spacer()

                Button(action: onCancel) {
                    Image("ic_x")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color("grey900"))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color("grey100")))
                }
                .buttonStyle(.plain)
            }

            Text("로그아웃 하시겠습니까?")
                .pretendardText(size: 16, weight: .regular)
                .foregroundColor(Color("grey700"))

            HStack(spacing: 12) {
                BottomSheetTwoBtnShort(text: "취소", style: .white, action: onCancel)
                BottomSheetTwoBtnShort(text: "로그아웃", style: .red, action: onConfirm)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -3)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.45).ignoresSafeArea()
        LogoutPopupView(onCancel: {}, onConfirm: {})
            .padding(.horizontal, 20)
    }
}
