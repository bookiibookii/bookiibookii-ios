import SwiftUI

// 안드 fragment_direct_host_receive_bottom_dialog.xml (DirectHostReceiveBottomDialogFragment) 대응.
// SHIPPING_TO_HOST (약속 시간 경과) — 호스트가 게스트로부터 책을 회수했는지 확인.
struct HostDirectReceiveSheet: View {
    let appointmentDateTime: String
    let appointmentPlace: String
    let onNoReceive: () -> Void
    let onReceive: () -> Void

    var body: some View {
        SheetContainer {
            Text("게스트에게 책을 받았나요?")
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
                dateTimeColor: Color("main200")
            )
            .padding(.top, 16)

            OutlineSheetButton(title: "받지 못했어요", action: onNoReceive)
                .padding(.top, 16)
            PrimarySheetButton(title: "받았어요!", action: onReceive)
                .padding(.top, 12)
        }
    }
}

#Preview("HostDirectReceive") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        HostDirectReceiveSheet(
            appointmentDateTime: "2026. 01. 19. 14:00 ",
            appointmentPlace: "메가MGC커피 역삼초교교차로점",
            onNoReceive: {},
            onReceive: {}
        )
    }
}
