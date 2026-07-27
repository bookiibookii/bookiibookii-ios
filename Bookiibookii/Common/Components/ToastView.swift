import SwiftUI

/// 하단 중앙 토스트.
/// @Binding message가 nil이 아닐 때 표시, 2초 후 자동으로 nil로 되돌림.
struct ToastView: ViewModifier {
    @Binding var message: String?
    var isSuccess: Bool = false
    var bottomPadding: CGFloat = 80

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content

            if let message {
                HStack(spacing: 8) {
                    Image(isSuccess ? "ic_check" : "ic_info")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    Text(message)
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey700"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .background(Color("white"))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color("grey200"), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .padding(.bottom, bottomPadding)
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
    func toast(_ message: Binding<String?>, isSuccess: Bool = false, bottomPadding: CGFloat = 80) -> some View {
        modifier(ToastView(message: message, isSuccess: isSuccess, bottomPadding: bottomPadding))
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
