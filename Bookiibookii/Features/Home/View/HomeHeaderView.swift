import SwiftUI

// 안드로이드 section_home_header.xml + ic_home_badge.xml 대응
// 흰 배경 + 하단 grey_200 구분선, 로고(메인 오렌지) + 알림 벨 + 주황 뱃지(흰 테두리)
struct HomeHeaderView: View {
    var hasNotificationBadge: Bool = true
    var onTapNotification: () -> Void = {}

    var body: some View {
        HStack(spacing: 0) {
            Image("ic_title")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(height: 20)
                .foregroundColor(Color("main200"))

            Spacer()

            Button(action: onTapNotification) {
                Image(systemName: "bell")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(Color("grey900"))
                    .overlay(alignment: .topTrailing) {
                        if hasNotificationBadge {
                            Circle()
                                .fill(Color("main200"))
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle().stroke(Color("white"), lineWidth: 1)
                                )
                                .offset(x: 2, y: -2)
                        }
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .frame(height: 68)
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color("grey200"))
                .frame(height: 1)
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        HomeHeaderView(hasNotificationBadge: true)
        HomeHeaderView(hasNotificationBadge: false)
        Spacer()
    }
    .background(Color("grey100"))
}
