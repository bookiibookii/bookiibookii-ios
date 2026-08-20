import SwiftUI
import PhotosUI

/// 프로필 사진 변경 바텀시트 (Figma ONB-01-02 / 프로필 사진 바텀 시트).
struct ProfilePhotoBottomSheet: View {
    @Binding var photoPickerItem: PhotosPickerItem?
    let onTakePhoto: () -> Void
    let onSelectDefault: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            optionsCard
            cancelButton
        }
    }

    private var optionsCard: some View {
        VStack(spacing: 0) {
            Text("프로필 사진 변경")
                .pretendardText(size: 20, weight: .semibold)
                .foregroundColor(Color("grey900"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                .padding(.bottom, 16)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color("grey100")).frame(height: 1)
                }

            optionRow(icon: "ic_camera", title: "사진 촬영", showsDivider: true, action: onTakePhoto)

            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                optionRowContent(icon: "ic_image", title: "앨범에서 선택")
            }
            .buttonStyle(.plain)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color("grey100")).frame(height: 1)
            }

            optionRow(icon: "ic_person2", title: "기본 이미지 선택", showsDivider: false, action: onSelectDefault)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 17.5, x: 0, y: 0)
    }

    private var cancelButton: some View {
        Button(action: onCancel) {
            Text("취소")
                .pretendardText(size: 16, weight: .regular)
                .foregroundColor(Color("grey900"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color("white"))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color("grey200"), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func optionRow(
        icon: String,
        title: String,
        showsDivider: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            optionRowContent(icon: icon, title: title)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if showsDivider {
                Rectangle().fill(Color("grey100")).frame(height: 1)
            }
        }
    }

    private func optionRowContent(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(Color("grey900"))

            Text(title)
                .pretendardText(size: 16, weight: .regular)
                .foregroundColor(Color("grey900"))
                .padding(.horizontal, 4)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
