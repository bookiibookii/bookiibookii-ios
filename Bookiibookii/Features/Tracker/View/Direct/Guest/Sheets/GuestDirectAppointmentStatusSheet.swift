import SwiftUI

// 안드 fragment_direct_guest_appointment_status_bottom_dialog.xml (DirectGuestAppointmentStatusBottomDialogFragment) 대응.
// SHIPPING_TO_GUEST (약속 시간 미경과) — 게스트가 책 받기 약속 상태 보는 시트.
struct GuestDirectAppointmentStatusSheet: View {
    let titleDateTime: String
    let appointmentDateTime: String
    let appointmentPlace: String
    let onGoChat: () -> Void

    var body: some View {
        SheetContainer {
            HStack(spacing: 0) {
                Text(titleDateTime)
                    .pretendardText(size: 20, weight: .medium)
                    .foregroundColor(Color("grey900"))
                Text(" 약속이 있어요.")
                    .pretendardText(size: 20, weight: .medium)
                    .foregroundColor(Color("grey900"))
            }
            .padding(.top, 20)

            Text("약속 시간 변경이 필요한 경우 상대방과 조율해주세요.")
                .pretendardText(size: 14)
                .foregroundColor(Color("grey500"))
                .padding(.top, 8)

            AppointmentInfoCard(
                dateTime: appointmentDateTime,
                place: appointmentPlace,
                dateTimeColor: Color("sub200")
            )
            .padding(.top, 16)

            PrimarySheetButton(title: "댓글 바로가기", action: onGoChat)
                .padding(.top, 12)
        }
    }
}

#Preview("GuestDirectAppointmentStatus") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        GuestDirectAppointmentStatusSheet(
            titleDateTime: "1월 19일 14:00 ",
            appointmentDateTime: "2026. 01. 19. 14:00 ",
            appointmentPlace: "메가MGC커피 역삼초교교차로점",
            onGoChat: {}
        )
    }
}
