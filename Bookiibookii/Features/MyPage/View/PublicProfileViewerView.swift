import SwiftUI

/// 공유 링크로 진입했을 때 보여주는 공개 프로필 화면. 로그인 없이 볼 수 있다.
/// 앱은 라이트 모드 고정이고 에셋의 다크 변형은 쓰지 않으므로, `?dark=1`은 공유 카드와 같이 색을 직접 지정해 반영한다.
struct PublicProfileViewerView: View {
    @StateObject private var viewModel: PublicProfileViewerViewModel
    let isDark: Bool
    let onGoMain: () -> Void

    init(shareToken: String, isDark: Bool, userService: UserService, onGoMain: @escaping () -> Void) {
        _viewModel = StateObject(
            wrappedValue: PublicProfileViewerViewModel(
                shareToken: shareToken,
                isDark: isDark,
                userService: userService
            )
        )
        self.isDark = isDark
        self.onGoMain = onGoMain
    }

    private var background: Color { isDark ? Color("grey900") : Color("white") }
    private var dividerColor: Color { isDark ? Color("grey800") : Color("grey200") }
    private var primaryText: Color { isDark ? Color("white") : Color("grey900") }

    var body: some View {
        VStack(spacing: 0) {
            header

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            footer
        }
        .background(background.ignoresSafeArea())
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
                .fill(dividerColor)
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
                Text("프로필을 불러올 수 없어요")
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(primaryText)
                Text("링크가 만료되었거나 존재하지 않는 프로필이에요")
                    .pretendardText(size: 14, weight: .regular)
                    .foregroundColor(Color("grey500"))
            }
            .multilineTextAlignment(.center)
            .padding(24)
        case let .loaded(profile):
            ScrollView(showsIndicators: false) {
                ProfileShareCardContent(
                    nickname: profile.nickname,
                    introduction: profile.introduction ?? "",
                    profileImageURL: profile.profileImageUrl,
                    books: profile.books,
                    isDark: isDark
                )
                .padding(.top, 36)
                .padding(.bottom, 24)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            footerButton(
                title: "메인으로",
                textColor: primaryText,
                background: background,
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
                .pretendardText(size: 16)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay {
                    if bordered {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(dividerColor, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}
