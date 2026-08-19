import PhotosUI
import SwiftUI

/// 독서카드 이미지 추가 바텀시트 (안드로이드 `CardImagePickerBottomSheet` 대응).
struct CardImagePickerBottomSheet: View {
    @Binding var photoPickerItem: PhotosPickerItem?
    let onTakePhoto: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("grey200"))
                .frame(width: 44, height: 4)
                .frame(maxWidth: .infinity)

            Spacer().frame(height: 20)

            Text("독서 카드 이미지 추가")
                .pretendardText(size: 20, weight: .semibold)
                .foregroundColor(Color("grey900"))

            Spacer().frame(height: 16)

            Button(action: onTakePhoto) {
                HStack(spacing: 8) {
                    Image("ic_camera")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color("white"))
                    Text("카메라로 촬영하기")
                        .pretendardText(size: 16, weight: .medium)
                        .foregroundColor(Color("white"))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color("grey900"))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)

            Spacer().frame(height: 8)

            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                HStack(spacing: 8) {
                    Image("ic_album")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color("grey900"))
                    Text("앨범에서 선택하기")
                        .pretendardText(size: 16, weight: .medium)
                        .foregroundColor(Color("grey900"))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color("white"))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color("grey200"), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 24)
        .background(Color("white"))
    }
}
