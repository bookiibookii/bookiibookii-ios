import SwiftUI

// 안드 fragment_reading_bottom_sheet_dialog.xml (HostReadingBottomDialogFragment) 대응.
// HOST_READING / HOST_EXTENSION 상태 — 호스트가 자기 독서 중일 때 보는 시트.
struct HostReadingSheet: View {
    let title: String              // 기본 "책을 읽고 있어요" (연장 상태에선 다른 텍스트로 갈아끼울 수 있게 외부에서 주입)
    let startDate: String
    let endDate: String
    /// 연장 가능 여부 (안드 canExtend = extensionCount < 1 && status in [HOST_READING, HOST_EXTENSION]).
    /// false면 "독서 기간 연장" 버튼 disabled + alpha 0.4.
    var canExtendPeriod: Bool = true
    let onWriteCard: () -> Void
    let onExtendPeriod: () -> Void
    let onFinish: () -> Void
    var isLoadingCard: Bool = false

    var body: some View {
        SheetContainer {
            Text(title)
                .font(.pretendard(size: 20, weight: .medium))
                .foregroundColor(Color("grey900"))
                .padding(.top, 20)

            ReadingPeriodCard(style: .ongoing, startDate: startDate, endDate: endDate)
                .padding(.top, 24)

            Text("원활한 교환독서를 위하여 책이 파손되지 않도록 유의해주세요.")
                .font(.pretendard(size: 14))
                .foregroundColor(Color("grey500"))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)

            OutlineSheetButton(title: "독서 카드 작성", action: onWriteCard, isDisabled: isLoadingCard)
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

#Preview("HostReading") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        HostReadingSheet(
            title: "책을 읽고 있어요",
            startDate: "2025. 12. 19.",
            endDate: "2025. 12. 25.",
            onWriteCard: {},
            onExtendPeriod: {},
            onFinish: {}
        )
    }
}
