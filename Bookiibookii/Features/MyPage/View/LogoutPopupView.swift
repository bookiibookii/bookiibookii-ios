import SwiftUI

struct LogoutPopupView: View {
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("로그아웃 하시겠어요?")
                    .pretendardText(size: 18, weight: .medium)
                    .foregroundColor(Color("grey900"))

                Text("언제든 다시 로그인할 수 있어요.")
                    .pretendardText(size: 14, weight: .regular)
                    .foregroundColor(Color("grey600"))
            }
            .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                Button("취소") { onCancel() }
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey900"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color("grey100"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Button("로그아웃") { onConfirm() }
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("white"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color("grey900"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.35).ignoresSafeArea()
        LogoutPopupView(onCancel: {}, onConfirm: {})
            .padding(24)
    }
}
