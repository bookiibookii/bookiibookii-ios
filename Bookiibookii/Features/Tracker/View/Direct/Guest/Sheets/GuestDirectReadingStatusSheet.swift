import SwiftUI

// 안드 fragment_direct_guest_reading_status_bottom_dialog.xml (DirectGuestReadingStatusBottomDialogFragment) 대응.
// READY / HOST_READING — 호스트 독서 중일 때 게스트가 보는 외부 시트.
struct GuestDirectReadingStatusSheet: View {
    let startDate: String
    let endDate: String
    let onGoCard: () -> Void
    var isLoadingCard: Bool = false

    var body: some View {
        SheetContainer {
            Text("호스트가 책을 읽고 있어요!")
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

#Preview("GuestDirectReadingStatus") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        GuestDirectReadingStatusSheet(
            startDate: "2025. 12. 19.",
            endDate: "2025. 12. 25.",
            onGoCard: {}
        )
    }
}
