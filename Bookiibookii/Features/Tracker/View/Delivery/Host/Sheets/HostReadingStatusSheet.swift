import SwiftUI

// 안드 fragment_host_reading_status_bottom_dialog.xml (HostReadingStatusBottomDialogFragment) 대응.
// GUEST_READING 상태(검수 통과 후) — 호스트가 게스트의 독서를 외부에서 보는 시트.
struct HostReadingStatusSheet: View {
    let startDate: String
    let endDate: String
    let onGoCard: () -> Void

    var body: some View {
        SheetContainer {
            Text("게스트가 책을 읽고 있어요!")
                .font(.pretendard(size: 20))
                .foregroundColor(Color("grey900"))
                .padding(.top, 20)

            ReadingPeriodCard(style: .ongoing, startDate: startDate, endDate: endDate)
                .padding(.top, 24)

            PrimarySheetButton(title: "독서카드 확인하러 가기", action: onGoCard)
                .padding(.top, 16)
        }
    }
}

#Preview("HostReadingStatus") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        HostReadingStatusSheet(
            startDate: "2025. 12. 19.",
            endDate: "2025. 12. 25.",
            onGoCard: {}
        )
    }
}
