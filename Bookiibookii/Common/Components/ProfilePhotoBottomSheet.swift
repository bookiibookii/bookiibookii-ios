import SwiftUI
import PhotosUI

/// 프로필 사진 변경 바텀시트 (Figma BottomSheet / ActionBtn).
struct ProfilePhotoBottomSheet: View {
    @Binding var photoPickerItem: PhotosPickerItem?
    let onTakePhoto: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("grey200"))
                .frame(width: 44, height: 4)
                .frame(maxWidth: .infinity)

            Spacer().frame(height: 20)

            Text("프로필 사진 변경")
                .pretendardText(size: 20, weight: .semibold)
                .foregroundColor(Color("grey900"))

            Spacer().frame(height: 16)

            Button(action: onTakePhoto) {
                HStack(spacing: 8) {
                    Image("ic_camera")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color("white"))
                    Text("사진 촬영")
                        .pretendardText(size: 16, weight: .regular)
                        .foregroundColor(Color("white"))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color("grey900"))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)

            Spacer().frame(height: 12)

            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                HStack(spacing: 8) {
                    Image("ic_album")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color("grey900"))
                    Text("앨범에서 선택")
                        .pretendardText(size: 16, weight: .regular)
                        .foregroundColor(Color("grey900"))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color("white"))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color("grey200"), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color("white"))
    }
}
