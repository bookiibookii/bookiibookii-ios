import SwiftUI

// 안드 fragment_host_shipping_status_bottom_dialog.xml (HostShippingStatusBottomDialogFragment) 대응.
// SHIPPING_TO_GUEST / RECEIVED 등 — 호스트가 본인이 등록한 운송장 상태 조회.
struct HostShippingStatusSheet: View {
    let courier: String
    let trackingNumber: String
    let isReceived: Bool          // false → "수령 전", true → "수령 완료"
    let onConfirm: () -> Void
    var isLoading: Bool = false

    var body: some View {
        SheetContainer {
            Text("게스트에게 책을 발송했어요!")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))
                .padding(.top, 20)

            Text("게스트가 책을 수령하면 상태가 업데이트됩니다.")
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
                .foregroundColor(Color("main200"))
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
            .foregroundColor(Color("main200"))
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(mainPale)
            .clipShape(Capsule())
    }
}

private let mainPale = Color(red: 0xFF/255, green: 0xEA/255, blue: 0xDB/255) // pre_main_pale

#Preview("HostShippingStatus") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        HostShippingStatusSheet(
            courier: "CJ대한통운",
            trackingNumber: "1234123412",
            isReceived: false,
            onConfirm: {}
        )
    }
}
