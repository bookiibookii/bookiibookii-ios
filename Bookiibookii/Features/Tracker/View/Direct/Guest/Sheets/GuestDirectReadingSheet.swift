import SwiftUI

// 안드 fragment_direct_guest_reading_bottom_dialog.xml (DirectGuestReadingBottomDialogFragment) 대응.
// GUEST_READING / GUEST_EXTENSION — 게스트 본인 독서 중.
struct GuestDirectReadingSheet: View {
    let title: String
    let startDate: String
    let endDate: String
    /// 안드 canExtend = extensionCount < 1 && status in [GUEST_READING, GUEST_EXTENSION]
    var canExtendPeriod: Bool = true
    let onWriteCard: () -> Void
    let onExtendPeriod: () -> Void
    let onFinish: () -> Void

    var body: some View {
        SheetContainer {
            Text(title)
                .font(.pretendard(size: 20, weight: .medium))
                .foregroundColor(Color("grey900"))
                .padding(.top, 20)

            ReadingPeriodCard(
                style: .ongoing,
                startDate: startDate,
                endDate: endDate,
                endColor: Color("sub200")
            )
            .padding(.top, 24)

            Text("원활한 교환독서를 위하여 책이 파손되지 않도록 유의해주세요.")
                .font(.pretendard(size: 14))
                .foregroundColor(Color("grey500"))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)

            OutlineSheetButton(title: "독서 카드 작성", action: onWriteCard)
                .padding(.top, 12)
            OutlineSheetButton(title: "독서 기간 연장", action: onExtendPeriod)
                .opacity(canExtendPeriod ? 1.0 : 0.4)
                .disabled(!canExtendPeriod)
                .padding(.top, 12)
            PrimarySheetButton(title: "다 읽었어요!", action: onFinish)
                .padding(.top, 12)
        }
    }
}

#Preview("GuestDirectReading") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        GuestDirectReadingSheet(
            title: "책을 읽고 있어요",
            startDate: "2025. 12. 19.",
            endDate: "2025. 12. 25.",
            onWriteCard: {},
            onExtendPeriod: {},
            onFinish: {}
        )
    }
}
