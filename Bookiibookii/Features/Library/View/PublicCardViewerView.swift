import SwiftUI

/// 공유 링크로 진입했을 때 보여주는 공개 독서카드 화면. 로그인 없이 볼 수 있다.
struct PublicCardViewerView: View {
    @StateObject private var viewModel: PublicCardViewerViewModel
    let onGoMain: () -> Void

    init(shareToken: String, libraryService: LibraryService, onGoMain: @escaping () -> Void) {
        _viewModel = StateObject(
            wrappedValue: PublicCardViewerViewModel(shareToken: shareToken, libraryService: libraryService)
        )
        self.onGoMain = onGoMain
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color("main100"), Color("grey100")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            footer
        }
        .background(Color("white").ignoresSafeArea())
        .toast($viewModel.toast, bottomPadding: 96)
        .task { await viewModel.load() }
    }

    private var header: some View {
        VStack(spacing: 0) {
            Image("ic_logo_wordmark")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color("main200"))
                .frame(height: 20)
                .frame(maxWidth: .infinity)
                .frame(height: 68)

            Rectangle()
                .fill(Color("grey200"))
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .tint(Color("main200"))
        case .error:
            VStack(spacing: 8) {
                Text("독서카드를 불러올 수 없어요")
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey900"))
                Text("링크가 만료되었거나 삭제된 카드일 수 있어요")
                    .pretendardText(size: 14, weight: .regular)
                    .foregroundColor(Color("grey500"))
            }
            .multilineTextAlignment(.center)
            .padding(24)
        case let .loaded(detail, style, image):
            GeometryReader { proxy in
                ScrollView(showsIndicators: false) {
                    LibraryCardSharePreview(detail: detail, style: style, loadedImage: image)
                        .background(Color("white"))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color("black").opacity(0.15), radius: 10, y: 4)
                        .frame(width: min(proxy.size.width * 0.82, 320))
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            footerButton(
                title: "메인으로",
                textColor: Color("grey900"),
                background: Color("white"),
                bordered: true,
                action: onGoMain
            )

            if case .loaded = viewModel.state {
                footerButton(
                    title: "이미지 저장",
                    textColor: Color("white"),
                    background: Color("main200"),
                    bordered: false
                ) {
                    Task { await viewModel.saveImage() }
                }
                .disabled(viewModel.isSaving)
            }
        }
        .padding(16)
    }

    private func footerButton(
        title: String,
        textColor: Color,
        background: Color,
        bordered: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay {
                    if bordered {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color("grey200"), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}
