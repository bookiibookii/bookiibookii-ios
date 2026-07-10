import SwiftUI

struct WithdrawRestrictedPopupView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                Text("회원 탈퇴")
                    .pretendardText(size: 20, weight: .semibold)
                    .foregroundColor(Color("grey900"))

                Spacer()

                Button(action: onDismiss) {
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

            Text("진행 중인 그룹이 모두 종료되어야 탈퇴 가능합니다.")
                .pretendardText(size: 16, weight: .regular)
                .foregroundColor(Color("grey700"))

            Button(action: onDismiss) {
                Text("닫기")
                    .pretendardText(size: 15, weight: .regular)
                    .foregroundColor(Color("white"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color("grey900"))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
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
        WithdrawRestrictedPopupView(onDismiss: {})
            .padding(.horizontal, 20)
    }
}
