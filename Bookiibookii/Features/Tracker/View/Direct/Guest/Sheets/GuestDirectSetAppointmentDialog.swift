import SwiftUI

// 안드 fragment_direct_guest_set_appointment_dialog.xml (DirectGuestSetAppointmentDialogFragment) 대응.
// 게스트의 첫 약속 등록 다이얼로그. host와 동일 layout.
struct GuestDirectSetAppointmentDialog: View {
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

#Preview("GuestDirectSetAppointment") {
    GuestDirectSetAppointmentPreview()
}

private struct GuestDirectSetAppointmentPreview: View {
    @State var dateTime = ""
    @State var place = ""
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            GuestDirectSetAppointmentDialog(
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
