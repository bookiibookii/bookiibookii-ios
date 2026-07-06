import SwiftUI

struct AddressSearchOverlay: View {
    let title: String
    let onClose: () -> Void
    let onSelect: (DaumPostcodeResult) -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                DaumPostcodeView { result in
                    onSelect(result)
                    onClose()
                }
            }
            .background(Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 0)
            .padding(.top, 8)
            .padding(.bottom, 0)
        }
        .transition(.opacity)
    }

    private var header: some View {
        ZStack {
            Text(title)
                .pretendardText(size: 18, weight: .medium)
                .foregroundColor(Color("grey900"))

            HStack {
                Button(action: onClose) {
                    Text("닫기")
                        .pretendardText(size: 16, weight: .regular)
                        .foregroundColor(Color("grey900"))
                        .frame(height: 44)
                        .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .frame(height: 52)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color("grey200")).frame(height: 1)
        }
    }
}
