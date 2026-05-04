import SwiftUI

// 안드 fragment_host_shipped_bottom_dialog.xml (HostShippedBottomDialogFragment) 대응.
// SHIPPING_TO_HOST — 게스트가 회수 발송 완료, 호스트가 받기 전 단계.
struct HostShippedSheet: View {
    let courier: String
    let trackingNumber: String
    let onViewShippingPhoto: () -> Void
    let onDoReceiveConfirm: () -> Void

    var body: some View {
        SheetContainer {
            Text("게스트가 책을 발송했어요!")
                .font(.pretendard(size: 20, weight: .medium))
                .foregroundColor(Color("grey900"))
                .padding(.top, 20)

            Text("책을 받은 후 수령 인증을 진행해주세요.")
                .font(.pretendard(size: 14))
                .foregroundColor(Color("grey500"))
                .padding(.top, 8)

            trackingCard.padding(.top, 16)

            OutlineSheetButton(title: "배송 인증 사진 보기", action: onViewShippingPhoto)
                .padding(.top, 12)
            PrimarySheetButton(title: "수령 인증하기", action: onDoReceiveConfirm)
                .padding(.top, 12)
        }
    }

    private var trackingCard: some View {
        HStack(spacing: 8) {
            Text(courier)
                .foregroundColor(Color("grey900"))
            Text(trackingNumber)
                .font(.pretendard(size: 14, weight: .medium))
                .foregroundColor(Color("main200"))
            Spacer()
        }
        .font(.pretendard(size: 14))
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color("grey100"))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("grey200"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview("HostShipped") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        HostShippedSheet(
            courier: "CJ대한통운",
            trackingNumber: "1234123412",
            onViewShippingPhoto: {},
            onDoReceiveConfirm: {}
        )
    }
}
