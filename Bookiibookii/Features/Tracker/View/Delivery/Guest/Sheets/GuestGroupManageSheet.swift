import SwiftUI

// 안드 fragment_guest_group_manage_bottom_dialog.xml (GuestGroupManageBottomDialogFragment) 대응.
// 게스트 (•••) 메뉴 — 그룹 상세페이지 + 신고하기. 호스트와 다르게 진행 안내 카드 없음.
struct GuestGroupManageSheet: View {
    let onTapDetail: () -> Void
    let onTapReport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(Color("grey200"))
                .frame(width: 44, height: 4)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 12)

            Text("그룹 관리")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))
                .padding(.horizontal, 24)
                .padding(.top, 18)

            Rectangle()
                .fill(Color("grey200"))
                .frame(height: 1)
                .padding(.horizontal, 24)
                .padding(.top, 14)

            menuRow(title: "그룹 상세페이지", color: Color("grey900"), action: onTapDetail)
                .padding(.top, 14)
            menuRow(title: "신고하기", color: pointRed, action: onTapReport)
                .padding(.top, 2)

            Spacer().frame(height: 24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
        .clipShape(.rect(topLeadingRadius: 20, topTrailingRadius: 20))
    }

    private func menuRow(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .pretendardText(size: 18, weight: .medium)
                .foregroundColor(color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}

private let pointRed = Color(red: 0xFF/255, green: 0x4D/255, blue: 0x4D/255)

#Preview("GuestGroupManage") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        GuestGroupManageSheet(onTapDetail: {}, onTapReport: {})
    }
}
