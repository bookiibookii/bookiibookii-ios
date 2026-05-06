import SwiftUI

// 안드 fragment_direct_host_set_appointment.xml (DirectHostSetAppointmentDialogFragment) 대응.
// 호스트의 첫 약속 등록 다이얼로그.
struct HostDirectSetAppointmentDialog: View {
    @Binding var dateTime: String
    @Binding var place: String
    let onClose: () -> Void
    let onPickDateTime: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        AppointmentFormDialog(
            title: "약속 등록",
            actionTitle: "등록하기",
            dateTime: $dateTime,
            place: $place,
            onClose: onClose,
            onPickDateTime: onPickDateTime,
            onSubmit: onSubmit
        )
    }
}

#Preview("HostDirectSetAppointment") {
    HostDirectSetAppointmentPreview()
}

private struct HostDirectSetAppointmentPreview: View {
    @State var dateTime = ""
    @State var place = ""
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            HostDirectSetAppointmentDialog(
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
