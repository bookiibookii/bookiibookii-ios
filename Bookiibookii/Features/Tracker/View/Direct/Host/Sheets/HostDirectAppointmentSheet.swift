import SwiftUI

// 안드 fragment_direct_host_appointment_bottom_dialog.xml (DirectHostAppointmentBottomDialogFragment) 대응.
// HOST_DONE — 호스트가 "게스트와 만날 약속" 등록 진입 안내.
struct HostDirectAppointmentSheet: View {
    let onGoComment: () -> Void
    let onRegisterMeet: () -> Void

    var body: some View {
        SheetContainer {
            Text("게스트와 만날 약속을 정해요")
                .font(.pretendard(size: 18, weight: .medium))
                .foregroundColor(Color("grey900"))
                .padding(.top, 20)

            Text("책을 주고 받을 구체적인 일시 및 장소를 댓글로 정하고,\n확정된 약속을 등록해주세요.")
                .font(.pretendard(size: 14))
                .foregroundColor(Color("grey500"))
                .lineSpacing(2)
                .padding(.top, 8)

            OutlineSheetButton(title: "댓글 바로가기", action: onGoComment)
                .padding(.top, 20)
            PrimarySheetButton(title: "약속 등록하기", action: onRegisterMeet)
                .padding(.top, 12)
        }
    }
}

#Preview("HostDirectAppointment") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        HostDirectAppointmentSheet(onGoComment: {}, onRegisterMeet: {})
    }
}
