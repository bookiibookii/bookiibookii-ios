import SwiftUI

struct GroupFabMenu: View {
    @Binding var isOpen: Bool
    let onTapTogether: () -> Void
    let onTapRelay: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            if isOpen {
                optionPill(icon: "ic_fab_together", title: "함께읽기") {
                    onTapTogether()
                    isOpen = false
                }
                optionPill(icon: "ic_fab_relay", title: "이어읽기") {
                    onTapRelay()
                    isOpen = false
                }
            }
            fabButton
        }
    }

    private func optionPill(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundColor(Color("white"))
                Text(title)
                    .font(.pretendard(size: 14, weight: .medium))
                    .foregroundColor(Color("white"))
            }
            .frame(width: 108, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("grey900"))
            )
        }
        .buttonStyle(.plain)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom)),
            removal: .opacity
        ))
    }

    private var fabButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.25)) { isOpen.toggle() }
        } label: {
            Image("ic_plus")
                .renderingMode(.template)
                .resizable()
                .frame(width: 19, height: 19)
                .foregroundColor(Color("white"))
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color("grey900")))
        }
        .buttonStyle(.plain)
    }
}

#Preview("닫힘") {
    struct Host: View {
        @State private var open = false
        var body: some View {
            ZStack(alignment: .bottomTrailing) {
                Color("grey100").ignoresSafeArea()
                GroupFabMenu(isOpen: $open, onTapTogether: {}, onTapRelay: {})
                    .padding(.trailing, 24).padding(.bottom, 16)
            }
        }
    }
    return Host()
}

#Preview("열림") {
    struct Host: View {
        @State private var open = true
        var body: some View {
            ZStack(alignment: .bottomTrailing) {
                Color("grey100").ignoresSafeArea()
                GroupFabMenu(isOpen: $open, onTapTogether: {}, onTapRelay: {})
                    .padding(.trailing, 24).padding(.bottom, 16)
            }
        }
    }
    return Host()
}
