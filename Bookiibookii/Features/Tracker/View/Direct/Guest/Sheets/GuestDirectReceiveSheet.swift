import SwiftUI

// 안드 fragment_direct_guest_receive_bottom_dialog.xml (DirectGuestReceiveBottomDialogFragment) 대응.
// SHIPPING_TO_GUEST (약속 시간 경과) — 게스트가 호스트로부터 책을 받았는지 확인.
struct GuestDirectReceiveSheet: View {
    let appointmentDateTime: String
    let appointmentPlace: String
    let onNoReceive: () -> Void
    let onReceive: () -> Void

    var body: some View {
        SheetContainer {
            Text("호스트에게 책을 받았나요?")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))
                .padding(.top, 20)

            Text("서로 책을 확인하고 상태를 업데이트해주세요.")
                .pretendardText(size: 14)
                .foregroundColor(Color("grey500"))
                .padding(.top, 8)

            AppointmentInfoCard(
                dateTime: appointmentDateTime,
                place: appointmentPlace,
                dateTimeColor: Color("sub200")
            )
            .padding(.top, 16)

            OutlineSheetButton(title: "받지 못했어요", action: onNoReceive)
                .padding(.top, 16)
            PrimarySheetButton(title: "받았어요!", action: onReceive)
                .padding(.top, 12)
        }
    }
}

#Preview("GuestDirectReceive") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        GuestDirectReceiveSheet(
            appointmentDateTime: "2026. 01. 19. 14:00 ",
            appointmentPlace: "메가MGC커피 역삼초교교차로점",
            onNoReceive: {},
            onReceive: {}
        )
    }
}
