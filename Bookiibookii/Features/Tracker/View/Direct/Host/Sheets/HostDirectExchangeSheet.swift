import SwiftUI

// 안드 fragment_direct_host_exchange_bottom_dialog.xml (DirectHostExchangeBottomDialogFragment) 대응.
// SHIPPING_TO_GUEST (약속 시간 경과) — 호스트가 게스트에게 책을 전달했는지 확인.
struct HostDirectExchangeSheet: View {
    let appointmentDateTime: String
    let appointmentPlace: String
    let onNoSend: () -> Void
    let onSend: () -> Void

    var body: some View {
        SheetContainer {
            Text("게스트에게 책을 전달하셨나요?")
                .font(.pretendard(size: 20, weight: .medium))
                .foregroundColor(Color("grey900"))
                .padding(.top, 20)

            Text("서로 책을 확인하고 상태를 업데이트해주세요.")
                .font(.pretendard(size: 14))
                .foregroundColor(Color("grey500"))
                .padding(.top, 8)

            AppointmentInfoCard(
                dateTime: appointmentDateTime,
                place: appointmentPlace,
                dateTimeColor: Color("main200")
            )
            .padding(.top, 16)

            OutlineSheetButton(title: "전달하지 못했어요", action: onNoSend)
                .padding(.top, 16)
            PrimarySheetButton(title: "전달했어요!", action: onSend)
                .padding(.top, 12)
        }
    }
}

#Preview("HostDirectExchange") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        HostDirectExchangeSheet(
            appointmentDateTime: "2026. 01. 19. 14:00 ",
            appointmentPlace: "메가MGC커피 역삼초교교차로점",
            onNoSend: {},
            onSend: {}
        )
    }
}
