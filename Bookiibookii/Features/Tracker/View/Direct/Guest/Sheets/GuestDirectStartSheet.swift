import SwiftUI

// 안드 fragment_direct_guest_start_bottom_dialog.xml (DirectGuestStartBottomDialogFragment) 대응.
// RECEIVED — 게스트가 호스트로부터 책 직접 수령 후 본인 독서 시작.
struct GuestDirectStartSheet: View {
    let startDate: String
    let endDate: String
    let onStart: () -> Void

    var body: some View {
        SheetContainer {
            Text("책 읽기 시작")
                .font(.pretendard(size: 20, weight: .medium))
                .foregroundColor(Color("grey900"))
                .padding(.top, 20)

            ReadingPeriodCard(
                style: .start,
                startDate: startDate,
                endDate: endDate,
                endColor: Color("sub200")
            )
            .padding(.top, 24)

            InfoBannerCard(message: "책을 수령한 날로부터 3일 이내에 책 읽기를 시작해야 합니다.")
                .padding(.top, 16)

            PrimarySheetButton(title: "시작하기", action: onStart)
                .padding(.top, 32)
        }
    }
}

#Preview("GuestDirectStart") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        GuestDirectStartSheet(
            startDate: "2025. 12. 19.",
            endDate: "2025. 12. 25.",
            onStart: {}
        )
    }
}
