import SwiftUI

// 안드 fragment_host_reading_done_bottom_dialog.xml (HostReadingDoneBottomDialogFragment) 대응.
// GUEST_DONE — 게스트가 다 읽었지만 회수 운송장 미등록.
struct HostReadingDoneSheet: View {
    let onGoCard: () -> Void
    var isLoadingCard: Bool = false

    var body: some View {
        SheetContainer {
            Text("게스트가 책을 다 읽었어요!")
                .font(.pretendard(size: 20, weight: .medium))
                .foregroundColor(Color("grey900"))
                .padding(.top, 20)

            Text("게스트가 운송장을 등록하면 상태가 업데이트됩니다.")
                .font(.pretendard(size: 13))
                .foregroundColor(Color("grey700"))
                .padding(.top, 8)

            PrimarySheetButton(title: "독서카드 확인하러 가기", action: onGoCard, isDisabled: isLoadingCard)
                .padding(.top, 18)
        }
    }
}

#Preview("HostReadingDone") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        HostReadingDoneSheet(onGoCard: {})
    }
}
