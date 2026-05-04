import SwiftUI
import UIKit

// 안드 fragment_guest_receive_confirm_dialog.xml (GuestReceiveConfirmDialogFragment) 대응.
// 게스트가 책 수령 인증(사진 업로드 + 상태 확인 체크).
struct GuestReceiveConfirmSheet: View {
    let pickedImage: UIImage?
    @Binding var isChecked: Bool
    let onClose: () -> Void
    let onPickImage: () -> Void
    let onFinish: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            uploadCard.padding(.top, 18)
            checkRow.padding(.top, 18)

            Text("파손, 훼손, 낙서 등이 있다면 즉시 상대방에게 댓글로 알려주세요.")
                .font(.pretendard(size: 11))
                .foregroundColor(Color("grey600"))
                .padding(.top, 8)

            Button(action: onFinish) {
                Text("수령 완료")
                    .font(.pretendard(size: 16))
                    .foregroundColor(Color("grey100"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color("grey900"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
            .padding(.top, 22)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var header: some View {
        HStack {
            Text("수령 인증")
                .font(.pretendard(size: 20, weight: .medium))
                .foregroundColor(Color("grey900"))
            Spacer()
            Button(action: onClose) {
                Image("ic_fab_close")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Color("grey900"))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
    }

    private var uploadCard: some View {
        Button(action: onPickImage) {
            ZStack {
                if let img = pickedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                } else {
                    VStack(spacing: 10) {
                        Image("ic_upload")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Color("grey800"))
                            .frame(width: 28, height: 28)
                        Text("받은 책 사진을 업로드해주세요")
                            .font(.pretendard(size: 14))
                            .foregroundColor(Color("grey800"))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .background(Color("grey200"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color("grey100"), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var checkRow: some View {
        Button {
            isChecked.toggle()
        } label: {
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
                    .font(.pretendard(size: 14))
                    .foregroundColor(Color("grey900"))
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview("GuestReceiveConfirm") {
    StatefulPreview()
}

private struct StatefulPreview: View {
    @State var checked = false
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            GuestReceiveConfirmSheet(
                pickedImage: nil,
                isChecked: $checked,
                onClose: {},
                onPickImage: {},
                onFinish: {}
            )
            .padding(20)
        }
    }
}
