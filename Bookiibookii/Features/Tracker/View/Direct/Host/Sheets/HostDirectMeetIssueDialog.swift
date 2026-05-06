import SwiftUI

// 안드 fragment_direct_host_meet_issue_dialog.xml (DirectHostMeetIssueDialogFragment) 대응.
// 호스트가 책 전달 실패 시 신고/재약속 분기 다이얼로그.
struct HostDirectMeetIssueDialog: View {
    let onClose: () -> Void
    let onReport: () -> Void
    let onReschedule: () -> Void

    var body: some View {
        DirectIssueDialog(
            title: "책을 전달하지 못했나요?",
            onClose: onClose,
            onReport: onReport,
            onReschedule: onReschedule
        )
    }
}

#Preview("HostDirectMeetIssue") {
    ZStack {
        Color.black.opacity(0.4).ignoresSafeArea()
        HostDirectMeetIssueDialog(onClose: {}, onReport: {}, onReschedule: {})
            .padding(20)
    }
}
