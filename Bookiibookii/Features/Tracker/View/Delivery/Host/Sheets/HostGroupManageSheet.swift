import SwiftUI

// 안드 fragment_host_group_manage_bottom_dialog.xml (HostGroupManageBottomDialogFragment) 대응.
// (•••) 메뉴 — 그룹 상세/수정/삭제. 진행 중엔 수정 비활성.
struct HostGroupManageSheet: View {
    let isInProgress: Bool                  // 진행 중이면 수정 비활성
    let onTapDetail: () -> Void
    let onTapEdit: () -> Void
    let onTapDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(Color("grey200"))
                .frame(width: 44, height: 4)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 12)

            Text("그룹 관리")
                .pretendardText(size: 20)
                .foregroundColor(Color("grey900"))
                .padding(.horizontal, 24)
                .padding(.top, 20)

            if isInProgress {
                noticeCard.padding(.horizontal, 24).padding(.top, 16)
            }

            Rectangle()
                .fill(Color("grey200"))
                .frame(height: 1)
                .padding(.horizontal, 24)
                .padding(.top, 20)

            menuRow(title: "그룹 상세페이지", color: Color("grey900"), enabled: true, action: onTapDetail)
                .padding(.top, 20)
            menuRow(title: "그룹 수정", color: Color("grey300"), enabled: !isInProgress, action: onTapEdit)
                .padding(.top, 4)
            menuRow(title: "그룹 삭제", color: pointRed, enabled: true, action: onTapDelete)
                .padding(.top, 4)

            Spacer().frame(height: 24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
        .clipShape(.rect(topLeadingRadius: 20, topTrailingRadius: 20))
    }

    private var noticeCard: some View {
        HStack(spacing: 10) {
            Image("ic_info")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(pointRed)
                .frame(width: 18, height: 18)
            Text("진행 중인 그룹은 수정할 수 없습니다.")
                .pretendardText(size: 14, weight: .medium)
                .foregroundColor(pointRed)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(pointRedPale)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(pointRed, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func menuRow(title: String, color: Color, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { if enabled { action() } }) {
            Text(title)
                .pretendardText(size: 18, weight: .medium)
                .foregroundColor(color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

// 안드 ui_point_red, ui_point_red_105
private let pointRed     = Color(red: 0xFF/255, green: 0x4D/255, blue: 0x4D/255)
private let pointRedPale = Color(red: 0xFF/255, green: 0xE6/255, blue: 0xE6/255)

#Preview("HostGroupManage") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        HostGroupManageSheet(
            isInProgress: true,
            onTapDetail: {},
            onTapEdit: {},
            onTapDelete: {}
        )
    }
}
