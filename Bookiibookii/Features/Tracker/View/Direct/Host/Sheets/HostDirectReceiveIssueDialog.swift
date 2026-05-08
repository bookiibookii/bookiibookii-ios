import SwiftUI

// 안드 fragment_direct_host_receive_issue_dialog.xml (DirectHostReceiveIssueDialogFragment) 대응.
// 호스트가 책 회수 실패 시 신고/재약속 분기 다이얼로그.
struct HostDirectReceiveIssueDialog: View {
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

#Preview("HostDirectReceiveIssue") {
    ZStack {
        Color.black.opacity(0.4).ignoresSafeArea()
        HostDirectReceiveIssueDialog(onClose: {}, onReport: {}, onReschedule: {})
            .padding(20)
    }
}
