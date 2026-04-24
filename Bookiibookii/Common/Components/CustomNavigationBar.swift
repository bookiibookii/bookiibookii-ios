import SwiftUI

enum NavigationBarRightButton {
    case none
    case text(title: String, action: () -> Void)
    case systemImage(name: String, action: () -> Void)
}

struct CustomNavigationBar: View {
    var title: String
    var onBack: () -> Void
    var rightButton: NavigationBarRightButton = .none

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onBack) {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color("grey700"))
            }
            .frame(width: 44, height: 44)

            Spacer()

            Text(title)
                .font(.pretendard(size: 18, weight: .medium))
                .foregroundStyle(Color("grey900"))

            Spacer()

            rightButtonView
                .frame(width: 44, height: 44)
        }
        .frame(height: 68)
        .padding(.horizontal, 20)
        .background(Color.white)
    }

    @ViewBuilder
    private var rightButtonView: some View {
        switch rightButton {
        case .none:
            Color.clear
        case .text(let title, let action):
            Button(action: action) {
                Text(title)
                    .font(.pretendard(size: 14, weight: .medium))
                    .foregroundStyle(Color("grey900"))
            }
        case .systemImage(let name, let action):
            Button(action: action) {
                Image(systemName: name)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color("grey900"))
            }
        }
    }
}

#Preview {
    CustomNavigationBar(title: "프로필 설정", onBack: {}, rightButton: .none)
}
