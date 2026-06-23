import SwiftUI

// 안드 fragment_host_send_confirm.xml (HostSendConfirmFragment) 대응.
// 게스트가 업로드한 받음 인증 사진을 호스트가 검수 후 서버에 verifyReception patch.
struct HostSendConfirmView: View {
    let imageUrl: String?
    @Binding var isChecked: Bool
    let onConfirm: () -> Void

    private var isEnabled: Bool { imageUrl != nil && isChecked }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("수령 인증")
                .pretendardText(size: 20)
                .foregroundColor(Color("grey900"))
                .frame(maxWidth: .infinity, alignment: .center)

            imageArea.padding(.top, 12)
            checkRow.padding(.top, 12)

            Button(action: { if isEnabled { onConfirm() } }) {
                Text("확인")
                    .pretendardText(size: 14)
                    .foregroundColor(isEnabled ? Color("grey100") : Color("grey600"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(isEnabled ? Color("grey900") : Color("grey100"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isEnabled ? Color.clear : Color("grey200"), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .opacity(isEnabled ? 1.0 : 0.55)
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
            .padding(.top, 14)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var imageArea: some View {
        ZStack {
            Color(red: 0xF2/255, green: 0xF2/255, blue: 0xF2/255)
            if let urlString = imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty:
                        Text("사진을 불러오는 중…")
                            .pretendardText(size: 14)
                            .foregroundColor(Color("grey600"))
                    case .failure:
                        Text("사진을 불러올 수 없어요")
                            .pretendardText(size: 14)
                            .foregroundColor(Color("grey600"))
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Text("사진을 불러오는 중…")
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey600"))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 190)
        .clipped()
    }

    private var checkRow: some View {
        Button(action: { isChecked.toggle() }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isChecked ? Color("grey900") : Color("grey200"))
                        .frame(width: 20, height: 20)
                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color("white"))
                    }
                }
                Text("책의 상태를 확인했습니다")
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey900"))
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("HostSendConfirm") {
    StatefulPreview()
}

private struct StatefulPreview: View {
    @State var checked: Bool = false
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            HostSendConfirmView(imageUrl: nil, isChecked: $checked, onConfirm: {})
                .padding(20)
        }
    }
}
