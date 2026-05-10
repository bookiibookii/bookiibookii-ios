import SwiftUI

// 안드 fragment_direct_reading_status_bottom_dialog.xml (DirectReadingStatusBottomDialogFragment, trkDirectHost 사용) 대응.
// GUEST_READING — 호스트가 게스트의 독서를 외부에서 보는 시트.
// 안드 XML은 "호스트가 책을 읽고 있어요!"로 되어있지만 안드 버그라 판단 — iOS는 "게스트가..."로 수정 (안드 추후 동기화).
struct HostDirectReadingStatusSheet: View {
    let startDate: String
    let endDate: String
    let onGoCard: () -> Void
    var isLoadingCard: Bool = false

    var body: some View {
        SheetContainer {
            Text("게스트가 책을 읽고 있어요!")
                .font(.pretendard(size: 20))
                .foregroundColor(Color("grey900"))
                .padding(.top, 20)

            ReadingPeriodCard(
                style: .ongoing,
                startDate: startDate,
                endDate: endDate,
                endColor: Color("sub200")
            )
            .padding(.top, 24)

            PrimarySheetButton(title: "독서카드 확인하러 가기", action: onGoCard, isDisabled: isLoadingCard)
                .padding(.top, 16)
        }
    }
}

#Preview("HostDirectReadingStatus") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        HostDirectReadingStatusSheet(
            startDate: "2025. 12. 19.",
            endDate: "2025. 12. 25.",
            onGoCard: {}
        )
    }
}
