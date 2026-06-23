import SwiftUI

// 안드 fragment_start_bottom_sheet_dialog.xml (HostStartBottomDialogFragment) 대응.
// READY 상태 — 호스트가 "책 읽기 시작"을 눌러 HOST_READING으로 진입.
struct HostStartSheet: View {
    let startDate: String          // "2025. 12. 19."
    let endDate: String            // "2025. 12. 25."
    let onStart: () -> Void

    var body: some View {
        SheetContainer {
            Text("책 읽기 시작")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))
                .padding(.top, 20)

            ReadingPeriodCard(style: .start, startDate: startDate, endDate: endDate)
                .padding(.top, 24)

            InfoBannerCard(message: "그룹 매칭된 날로부터 3일 이내에 책 읽기를 시작해야 합니다.")
                .padding(.top, 16)

            PrimarySheetButton(title: "시작하기", action: onStart)
                .padding(.top, 32)
        }
    }
}

#Preview("HostStart") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        HostStartSheet(
            startDate: "2025. 12. 19.",
            endDate: "2025. 12. 25.",
            onStart: {}
        )
    }
}
