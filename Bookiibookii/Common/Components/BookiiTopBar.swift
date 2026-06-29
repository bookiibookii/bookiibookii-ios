import SwiftUI

/// 안드로이드 BookiiTopBar 대응 공통 상단 헤더.
/// 좌측 프로필(고정) / 중앙 타이틀(고정) / 우측 트레일링(교체 가능).
/// 높이 68, 흰 배경, 하단 grey200 1px 구분선.
struct BookiiTopBar<Trailing: View>: View {
    let title: String
    let onProfileTap: () -> Void
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        ZStack {
            // 중앙 타이틀 (좌우 요소 폭과 무관하게 정확히 중앙)
            Text(title)
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))

            HStack(spacing: 0) {
                Button(action: onProfileTap) {
                    Image("ic_person")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(Color("grey900"))
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer()

                trailing()
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color("grey200"))
                .frame(height: 1)
        }
    }
}

/// 벨 아이콘 + 미읽음 주황 배지(흰 테두리) 버튼.
struct NotificationBellButton: View {
    var hasBadge: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image("ic_alert_32")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundColor(Color("grey900"))
                .overlay(alignment: .topTrailing) {
                    if hasBadge {
                        Circle()
                            .fill(Color("main200"))
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(Color("white"), lineWidth: 1))
                            .offset(x: 1, y: 1)
                    }
                }
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// 벨+배지 우측 고정 편의 이니셜라이저 (탐색/트래커용).
extension BookiiTopBar where Trailing == NotificationBellButton {
    init(
        title: String,
        hasNotificationBadge: Bool,
        onProfileTap: @escaping () -> Void,
        onNotificationTap: @escaping () -> Void
    ) {
        self.init(title: title, onProfileTap: onProfileTap) {
            NotificationBellButton(hasBadge: hasNotificationBadge, onTap: onNotificationTap)
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        BookiiTopBar(title: "탐색", hasNotificationBadge: true, onProfileTap: {}, onNotificationTap: {})
        BookiiTopBar(title: "서재", onProfileTap: {}) {
            Image("ic_bookmark").resizable().scaledToFit().frame(width: 32, height: 32)
        }
        Spacer()
    }
    .background(Color("grey100"))
}
