import SwiftUI

// 그룹 상세 헤더 + 미트볼(수정/삭제) 팝오버. 안드 GroupDetailScreen.kt(401-541) 대응.
// showEditMenu(호스트 && buttonStatus == MANAGE)일 때만 우측 미트볼 노출.
struct GroupDetailHeader: View {
    let showEditMenu: Bool
    let onBack: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack(spacing: 0) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color("black"))
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if showEditMenu {
                        Button {
                            expanded = true
                        } label: {
                            Image("ic_meetball")
                                .renderingMode(.template)
                                .foregroundColor(Color("black"))
                                .frame(width: 40, height: 40)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("그룹 상세")
                    .pretendardText(size: 20, weight: .medium)
                    .foregroundColor(Color("grey900"))
            }
            .padding(.horizontal, 16)
            .frame(height: 68)
            .background(Color("white"))

            Rectangle()
                .fill(Color("grey200"))
                .frame(height: 1)
        }
        .overlay {
            if expanded {
                Color.black.opacity(0.001)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { expanded = false }
                    .overlay(alignment: .topTrailing) {
                        GroupDetailMenuPopover(
                            onEdit: {
                                expanded = false
                                onEdit()
                            },
                            onDelete: {
                                expanded = false
                                onDelete()
                            }
                        )
                        .padding(.top, 56)
                        .padding(.trailing, 16)
                    }
            }
        }
    }
}

// 미트볼 메뉴 팝오버 — 수정하기/삭제하기를 한 카드에 담음 (안드 GroupDetailMenuPopover)
private struct GroupDetailMenuPopover: View {
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            GroupDetailMenuItem(text: "수정하기", icon: "ic_edit", action: onEdit)
            Rectangle()
                .fill(Color("grey100"))
                .frame(height: 1)
            GroupDetailMenuItem(text: "삭제하기", icon: "ic_trash", action: onDelete)
        }
        .padding(.vertical, 4)
        .frame(width: 160)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color("grey200"), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)
    }
}

// 안드 GroupDetailMenuItem
private struct GroupDetailMenuItem: View {
    let text: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .pretendardText(size: 14, weight: .medium)
                    .foregroundColor(Color("grey700"))
                Spacer()
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color("grey700"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
