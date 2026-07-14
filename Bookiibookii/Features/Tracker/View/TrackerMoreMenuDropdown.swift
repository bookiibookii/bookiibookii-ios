import SwiftUI

// 트래커 상세 더보기 드롭다운. 게스트는 "독서 기간 수정" 미표시.
struct TrackerMoreMenuDropdown: View {
    let isHost: Bool
    let onEditPeriod: () -> Void
    let onGoToLibrary: () -> Void
    let onReport: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if isHost {
                menuItem(text: "독서 기간 수정", icon: "ic_edit", action: onEditPeriod)
            }
            menuItem(text: "서재로 이동", icon: "ic_book", action: onGoToLibrary)
            menuItem(text: "신고", icon: "ic_report_32", action: onReport)
        }
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color("white")))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color("grey200"), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 6, y: 2)
        .fixedSize()
    }

    private func menuItem(text: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(text).pretendardText(size: 14, weight: .medium).foregroundColor(Color("grey700"))
                Image(icon).renderingMode(.template).resizable().scaledToFit()
                    .frame(width: 24, height: 24).foregroundColor(Color("grey700"))
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
