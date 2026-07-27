import SwiftUI

/// 토스트 내용. 성공/실패에 따라 아이콘이 갈린다(성공 ic_check · 실패 ic_info).
struct ToastMessage: Equatable {
    let text: String
    let isSuccess: Bool

    static func success(_ text: String) -> ToastMessage { .init(text: text, isSuccess: true) }
    static func failure(_ text: String) -> ToastMessage { .init(text: text, isSuccess: false) }
}

/// 하단 중앙 토스트.
/// @Binding message가 nil이 아닐 때 표시, 2초 후 자동으로 nil로 되돌림.
struct ToastView: ViewModifier {
    @Binding var message: ToastMessage?
    var bottomPadding: CGFloat = 80

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content

            if let message {
                HStack(spacing: 8) {
                    Image(message.isSuccess ? "ic_check" : "ic_info")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    Text(message.text)
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
    func toast(_ message: Binding<ToastMessage?>, bottomPadding: CGFloat = 80) -> some View {
        modifier(ToastView(message: message, bottomPadding: bottomPadding))
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var msg: ToastMessage? = nil
        var body: some View {
            VStack {
                Button("토스트 표시") { msg = .failure("준비 중입니다") }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toast($msg)
        }
    }
    return PreviewHost()
}
