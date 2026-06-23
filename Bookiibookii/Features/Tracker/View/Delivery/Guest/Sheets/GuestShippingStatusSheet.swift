import SwiftUI

// 안드 fragment_guest_shipping_status_bottom_dialog.xml (GuestShippingStatusBottomDialogFragment) 대응.
// SHIPPING_TO_HOST / RETURNED — 게스트가 등록한 회수 운송장 상태 조회.
struct GuestShippingStatusSheet: View {
    let courier: String
    let trackingNumber: String
    let isReceived: Bool
    let onConfirm: () -> Void
    var isLoading: Bool = false

    var body: some View {
        SheetContainer {
            Text("호스트에게 책을 발송했어요!")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))
                .padding(.top, 20)

            Text("호스트가 책을 수령하면 상태가 업데이트됩니다.")
                .pretendardText(size: 14)
                .foregroundColor(Color("grey500"))
                .padding(.top, 8)

            trackingCard.padding(.top, 16)

            PrimarySheetButton(title: "수령 인증 확인하기", action: onConfirm, isDisabled: isLoading)
                .padding(.top, 12)
        }
    }

    private var trackingCard: some View {
        HStack(spacing: 8) {
            Text(courier)
                .pretendardText(size: 14)
                .foregroundColor(Color("grey900"))
            Text(trackingNumber)
                .pretendardText(size: 14, weight: .medium)
                .foregroundColor(Color("sub200"))
            Spacer()
            statusPill
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color("grey100"))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color("grey200"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var statusPill: some View {
        Text(isReceived ? "수령 완료" : "수령 전")
            .pretendardText(size: 12, weight: .medium)
            .foregroundColor(Color("sub200"))
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(subPale)
            .clipShape(Capsule())
    }
}

private let subPale = Color(red: 0xD4/255, green: 0xED/255, blue: 0xFF/255) // pre_sub_pale

#Preview("GuestShippingStatus") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        GuestShippingStatusSheet(
            courier: "CJ대한통운",
            trackingNumber: "1234123412",
            isReceived: false,
            onConfirm: {}
        )
    }
}
