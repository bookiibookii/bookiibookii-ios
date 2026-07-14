import SwiftUI

// 직접교환 완료 확인 다이얼로그.
// 카드 컨텐츠만 담당 — 스크림/오버레이는 호스트 담당.
struct TrackerDirectExchangeConfirmDialog: View {
    let onDismiss: () -> Void
    let onNotYetClick: () -> Void
    let onConfirmClick: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            Text("상대방과 교환을 완료했는지 확인해주세요.")
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
            Text("책을 교환하셨나요?")
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
            CardButton(text: "못했어요", style: .white, action: onNotYetClick)
            CardButton(text: "교환했어요", style: .main, action: onConfirmClick)
        }
    }
}

#Preview {
    TrackerDirectExchangeConfirmDialog(
        onDismiss: {},
        onNotYetClick: {},
        onConfirmClick: {}
    )
    .padding(24)
    .background(Color("uiBg"))
}
