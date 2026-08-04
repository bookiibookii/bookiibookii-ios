import SwiftUI

// Figma COM-03 (3834:46260 시스템 / 46276 네트워크 / 46294·46311 404 계열)
struct ErrorScreen: View {
    let type: BookiiErrorType
    let onRetry: () -> Void
    let onBack: () -> Void
    let onGoMain: () -> Void

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                graphic
                    .frame(maxWidth: .infinity)
                    .aspectRatio(412 / 560, contentMode: .fit)
                    .padding(.top, 8)

                VStack(spacing: 4) {
                    Text(type.title)
                        .pretendardText(size: 18, weight: .medium)
                        .foregroundColor(Color("grey900"))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    if let subtitle = type.subtitle {
                        Text(subtitle)
                            .pretendardText(size: 16, weight: .regular)
                            .foregroundColor(Color("grey700"))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer(minLength: 16)
            }

            VStack(spacing: 12) {
                Spacer()
                footerButtons
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
    }

    private var graphic: some View {
        Image(type.uses404Artwork ? "img_404_graphic" : "img_error_graphic")
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var footerButtons: some View {
        if type.showsMainOnlyCTA {
            FooterButton(text: "메인으로 이동", style: .dark, action: onGoMain)
        } else {
            FooterButton(text: "다시 시도", style: .grey, action: onRetry)
            FooterButton(text: "이전", style: .dark, action: onBack)
        }
    }
}

#Preview("시스템") {
    ErrorScreen(type: .system, onRetry: {}, onBack: {}, onGoMain: {})
}

#Preview("네트워크") {
    ErrorScreen(type: .network, onRetry: {}, onBack: {}, onGoMain: {})
}

#Preview("종료된 그룹") {
    ErrorScreen(type: .groupClosed, onRetry: {}, onBack: {}, onGoMain: {})
}
