import SwiftUI

// 안드 fragment_direct_guest_appointment_edit_bottom_dialog.xml (DirectGuestAppointmentEditBottomDialogFragment) 대응.
// SHIPPING_TO_HOST (약속 시간 미경과) — 게스트가 등록한 회수 약속 + 댓글/수정 진입.
struct GuestDirectAppointmentEditSheet: View {
    let titleDateTime: String
    let appointmentDateTime: String
    let appointmentPlace: String
    let onGoComment: () -> Void
    let onEditMeet: () -> Void

    var body: some View {
        SheetContainer {
            HStack(spacing: 0) {
                Text(titleDateTime)
                    .pretendardText(size: 20, weight: .medium)
                    .foregroundColor(Color("grey900"))
                Text("약속이 있어요.")
                    .pretendardText(size: 20, weight: .medium)
                    .foregroundColor(Color("grey900"))
            }
            .padding(.top, 20)

            Text("약속 시간 변경이 필요한 경우 수정해주세요.")
                .pretendardText(size: 14)
                .foregroundColor(Color("grey500"))
                .padding(.top, 8)

            AppointmentInfoCard(
                dateTime: appointmentDateTime,
                place: appointmentPlace,
                dateTimeColor: Color("sub200")
            )
            .padding(.top, 16)

            OutlineSheetButton(title: "댓글 바로가기", action: onGoComment)
                .padding(.top, 16)
            PrimarySheetButton(title: "약속 수정하기", action: onEditMeet)
                .padding(.top, 12)
        }
    }
}

#Preview("GuestDirectAppointmentEdit") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        GuestDirectAppointmentEditSheet(
            titleDateTime: "1월 19일 14:00 ",
            appointmentDateTime: "2026. 01. 19. 14:00 ",
            appointmentPlace: "메가MGC커피 역삼초교교차로점",
            onGoComment: {},
            onEditMeet: {}
        )
    }
}
