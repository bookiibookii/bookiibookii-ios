import SwiftUI

// 안드 fragment_direct_guest_receive_issue_dialog.xml (DirectGuestReceiveIssueDialogFragment) 대응.
// 게스트가 책 수령 실패 시 신고/재약속 분기 다이얼로그.
struct GuestDirectReceiveIssueDialog: View {
    let onClose: () -> Void
    let onReport: () -> Void
    let onReschedule: () -> Void

    var body: some View {
        DirectIssueDialog(
            title: "책을 받지 못했나요?",
            onClose: onClose,
            onReport: onReport,
            onReschedule: onReschedule
        )
    }
}

#Preview("GuestDirectReceiveIssue") {
    ZStack {
        Color.black.opacity(0.4).ignoresSafeArea()
        GuestDirectReceiveIssueDialog(onClose: {}, onReport: {}, onReschedule: {})
            .padding(20)
    }
}
