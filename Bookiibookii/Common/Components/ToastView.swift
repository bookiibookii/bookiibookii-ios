import SwiftUI

/// 하단 중앙 토스트.
/// @Binding message가 nil이 아닐 때 표시, 2초 후 자동으로 nil로 되돌림.
struct ToastView: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content

            if let message {
                Text(message)
                    .pretendardText(size: 14, weight: .medium)
                    .foregroundColor(Color("white"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color("grey900").opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 80)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .task(id: message) {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        guard !Task.isCancelled else { return }
                        withAnimation(.easeOut(duration: 0.3)) { self.message = nil }
                    }
            }
        }
        .animation(.easeOut(duration: 0.2), value: message)
    }
}

extension View {
    func toast(_ message: Binding<String?>) -> some View {
        modifier(ToastView(message: message))
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var msg: String? = nil
        var body: some View {
            VStack {
                Button("토스트 표시") { msg = "준비 중입니다" }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toast($msg)
        }
    }
    return PreviewHost()
}
