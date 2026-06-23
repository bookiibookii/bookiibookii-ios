import SwiftUI

struct WithdrawPopupView: View {
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("회원 탈퇴를 진행할까요?")
                    .pretendardText(size: 18, weight: .medium)
                    .foregroundColor(Color("grey900"))

                Text("탈퇴 시 계정 정보는 복구할 수 없어요.")
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

                Button("탈퇴하기") { onConfirm() }
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("white"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(red: 1.0, green: 0.302, blue: 0.302))
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
        WithdrawPopupView(onCancel: {}, onConfirm: {})
            .padding(24)
    }
}
