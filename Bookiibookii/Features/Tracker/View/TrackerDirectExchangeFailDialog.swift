import SwiftUI

// 직접교환 실패 안내 다이얼로그.
// 카드 컨텐츠만 담당 — 스크림/오버레이는 호스트 담당.
struct TrackerDirectExchangeFailDialog: View {
    let onDismiss: () -> Void
    let onReportClick: () -> Void
    let onGoToCommentsClick: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            Text("상대방과 연락하여 약속을 다시 잡거나, 일방적인 노쇼라면 신고를 진행해 주세요.")
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey700"))
                .frame(maxWidth: .infinity, alignment: .leading)
            buttonRow
        }
        .padding(20)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - 헤더

    private var header: some View {
        HStack(alignment: .center) {
            Text("책을 교환하지 못했나요?")
                .pretendardText(size: 24, weight: .bold)
                .foregroundColor(Color("grey900"))
            Spacer()
            closeButton
        }
    }

    private var closeButton: some View {
        Button(action: onDismiss) {
            Image("ic_x")
                .renderingMode(.template)
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(Color("grey900"))
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color("grey100")))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 버튼

    private var buttonRow: some View {
        HStack(spacing: 8) {
            CardButton(text: "신고하기", style: .white, action: onReportClick)
            CardButton(text: "메시지", style: .main, action: onGoToCommentsClick)
        }
    }
}

#Preview {
    TrackerDirectExchangeFailDialog(
        onDismiss: {},
        onReportClick: {},
        onGoToCommentsClick: {}
    )
    .padding(24)
    .background(Color("uiBg"))
}
