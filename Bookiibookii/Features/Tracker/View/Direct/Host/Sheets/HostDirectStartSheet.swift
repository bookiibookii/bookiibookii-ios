import SwiftUI

// 안드 fragment_direct_host_start_bottom_dialog.xml (DirectHostStartBottomDialogFragment) 대응.
// READY — 호스트가 그룹 매칭 후 책 읽기 시작.
struct HostDirectStartSheet: View {
    let startDate: String
    let endDate: String
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

#Preview("HostDirectStart") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        HostDirectStartSheet(
            startDate: "2025. 12. 19.",
            endDate: "2025. 12. 25.",
            onStart: {}
        )
    }
}
