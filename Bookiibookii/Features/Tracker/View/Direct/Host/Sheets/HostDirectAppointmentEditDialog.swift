import SwiftUI

// 안드 fragment_direct_host_appointment_edit_dialog.xml (DirectHostAppointmentEditDialogFragment) 대응.
// 호스트가 등록한 약속을 수정하는 중앙 다이얼로그.
struct HostDirectAppointmentEditDialog: View {
    @Binding var dateTime: String
    @Binding var place: String
    let onClose: () -> Void
    let onPickDateTime: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        AppointmentFormDialog(
            title: "약속 수정",
            actionTitle: "수정하기",
            dateTime: $dateTime,
            place: $place,
            onClose: onClose,
            onPickDateTime: onPickDateTime,
            onSubmit: onSubmit
        )
    }
}

#Preview("HostDirectAppointmentEditDialog") {
    HostDirectAppointmentEditDialogPreview()
}

private struct HostDirectAppointmentEditDialogPreview: View {
    @State var dateTime = "2026. 01. 19. 14:00"
    @State var place = "메가MGC커피 역삼초교교차로점"
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            HostDirectAppointmentEditDialog(
                dateTime: $dateTime,
                place: $place,
                onClose: {},
                onPickDateTime: {},
                onSubmit: {}
            )
            .padding(20)
        }
    }
}
