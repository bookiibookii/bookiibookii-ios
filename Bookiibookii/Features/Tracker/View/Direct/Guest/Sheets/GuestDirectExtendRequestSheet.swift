import SwiftUI

// 안드 fragment_direct_guest_extend_request_bottom_dialog.xml (DirectGuestExtendRequestBottomDialogFragment) 대응.
// HOST_EXTENSION — 호스트 신청한 연장을 게스트가 확인.
// 안드 텍스트는 "파트너가 기간 연장을 신청했어요" — 택배("호스트가...")와 다름.
struct GuestDirectExtendRequestSheet: View {
    let originalEndDate: String
    let newEndDate: String
    let onConfirm: () -> Void

    var body: some View {
        SheetContainer {
            Text("파트너가 기간 연장을 신청했어요")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))
                .padding(.top, 12)

            datesBox.padding(.top, 20)

            PrimarySheetButton(title: "확인", action: onConfirm)
                .padding(.top, 20)
        }
    }

    private var datesBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 0) {
                Text("기존 예정 종료일")
                    .frame(minWidth: 130, alignment: .leading)
                    .foregroundColor(Color("grey900"))
                Text(originalEndDate)
                    .foregroundColor(Color("grey900"))
            }
            HStack(spacing: 0) {
                Text("연장 후 예정 종료일")
                    .frame(minWidth: 130, alignment: .leading)
                    .foregroundColor(Color("grey900"))
                Text(newEndDate)
                    .pretendardText(size: 14, weight: .medium)
                    .foregroundColor(Color("sub200"))
            }
        }
        .pretendardText(size: 14)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("grey100"))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("grey200"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview("GuestDirectExtendRequest") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        GuestDirectExtendRequestSheet(
            originalEndDate: "2025. 12. 25.",
            newEndDate: "2025. 12. 28.",
            onConfirm: {}
        )
    }
}
