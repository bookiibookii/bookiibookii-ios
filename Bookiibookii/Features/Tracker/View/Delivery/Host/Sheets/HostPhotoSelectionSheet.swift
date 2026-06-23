import SwiftUI

// 안드 fragment_host_photo_selection_dialog.xml (HostPhotoSelectionDialogFragment) 대응.
// 사진 첨부 시 사진/카메라 선택용 작은 카드 다이얼로그.
struct HostPhotoSelectionSheet: View {
    let onPickFromAlbum: () -> Void
    let onTakeWithCamera: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            row(title: "사진", iconName: "ic_album", action: onPickFromAlbum)

            Rectangle()
                .fill(Color(red: 0xF0/255, green: 0xF0/255, blue: 0xF0/255))
                .frame(height: 1)
                .padding(.horizontal, 12)

            row(title: "카메라", iconName: "ic_camera", action: onTakeWithCamera)
        }
        .frame(width: 200)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func row(title: String, iconName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey700"))
                Spacer()
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .padding(20)
        }
        .buttonStyle(.plain)
    }
}

#Preview("HostPhotoSelection") {
    ZStack {
        Color.black.opacity(0.4).ignoresSafeArea()
        HostPhotoSelectionSheet(onPickFromAlbum: {}, onTakeWithCamera: {})
    }
}
