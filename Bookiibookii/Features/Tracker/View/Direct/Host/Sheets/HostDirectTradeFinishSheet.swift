import SwiftUI

// 안드 fragment_direct_trade_finish_bottom_dialog.xml (DirectTradeFinishBottomDialogFragment, trkDirectHost 사용) 대응.
// RETURNED — 교환 종료, 후기 작성 유도.
struct HostDirectTradeFinishSheet: View {
    let onWriteReview: () -> Void

    var body: some View {
        SheetContainer {
            Text("교환독서 종료")
                .font(.pretendard(size: 20, weight: .medium))
                .foregroundColor(Color("grey900"))
                .padding(.top, 20)

            Text("교환독서가 종료되었어요. 따뜻한 후기를 남겨볼까요?")
                .font(.pretendard(size: 14))
                .foregroundColor(Color("grey500"))
                .padding(.top, 8)

            PrimarySheetButton(title: "후기 남기기", action: onWriteReview)
                .padding(.top, 18)
        }
    }
}

#Preview("HostDirectTradeFinish") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        HostDirectTradeFinishSheet(onWriteReview: {})
    }
}
