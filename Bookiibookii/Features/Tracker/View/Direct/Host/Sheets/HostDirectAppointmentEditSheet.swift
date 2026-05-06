import SwiftUI

// 안드 fragment_direct_host_appointment_edit_bottom_dialog.xml (DirectHostAppointmentEditBottomDialogFragment) 대응.
// SHIPPING_TO_GUEST (약속 시간 미경과) — 호스트가 등록한 약속 정보 + 댓글/수정 진입.
struct HostDirectAppointmentEditSheet: View {
    let titleDateTime: String       // "1월 19일 14:00 "
    let appointmentDateTime: String // "2026. 01. 19. 14:00 "
    let appointmentPlace: String    // "메가MGC커피 역삼초교교차로점"
    let onGoComment: () -> Void
    let onEditMeet: () -> Void

    var body: some View {
        SheetContainer {
            HStack(spacing: 0) {
                Text(titleDateTime)
                    .font(.pretendard(size: 20, weight: .medium))
                    .foregroundColor(Color("grey900"))
                Text("약속이 있어요.")
                    .font(.pretendard(size: 20, weight: .medium))
                    .foregroundColor(Color("grey900"))
            }
            .padding(.top, 20)

            Text("약속 시간 변경이 필요한 경우 수정해주세요.")
                .font(.pretendard(size: 14))
                .foregroundColor(Color("grey500"))
                .padding(.top, 8)

            AppointmentInfoCard(
                dateTime: appointmentDateTime,
                place: appointmentPlace,
                dateTimeColor: Color("main200")
            )
            .padding(.top, 16)

            OutlineSheetButton(title: "댓글 바로가기", action: onGoComment)
                .padding(.top, 16)
            PrimarySheetButton(title: "약속 수정하기", action: onEditMeet)
                .padding(.top, 12)
        }
    }
}

#Preview("HostDirectAppointmentEdit") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        HostDirectAppointmentEditSheet(
            titleDateTime: "1월 19일 14:00 ",
            appointmentDateTime: "2026. 01. 19. 14:00 ",
            appointmentPlace: "메가MGC커피 역삼초교교차로점",
            onGoComment: {},
            onEditMeet: {}
        )
    }
}
