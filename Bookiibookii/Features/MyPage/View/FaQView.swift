import SwiftUI

struct FaQView: View {
    @EnvironmentObject private var container: DIContainer
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel: FaQViewModel

    private static let kakaoChannelURL = URL(string: "http://pf.kakao.com/_cIxlxjX/chat")!

    init(faqService: FaqService) {
        _viewModel = StateObject(wrappedValue: FaQViewModel(faqService: faqService))
    }

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if viewModel.isLoading && viewModel.items.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            if viewModel.items.isEmpty {
                                emptyCard
                            } else {
                                ForEach(viewModel.items) { item in
                                    faqCard(item)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 16)
                    }
                }

                footerButtons
            }
        }
        .alert("안내", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task { await viewModel.load() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { container.navigationRouter.pop() } label: {
                Image("ic_back")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("자주 묻는 질문 / 신고하기")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Divider().overlay(Color("grey200"))
        }
    }

    // MARK: - FAQ

    private var emptyCard: some View {
        Text("등록된 FAQ가 없어요.")
            .pretendardText(size: 16, weight: .regular)
            .foregroundColor(Color("grey600"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func faqCard(_ item: FaqItem) -> some View {
        let isExpanded = viewModel.expandedFaqId == item.id

        return Button {
            viewModel.toggle(item.id)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 8) {
                    questionLabel(item.question)

                    Spacer(minLength: 0)

                    Image("ic_chevron_r")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(isExpanded ? -90 : 90))
                }

                if isExpanded {
                    answerLabel(item.answer)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("white"))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isExpanded ? Color("main200") : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private func questionLabel(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text("Q.")
                .pretendardText(size: 16, weight: .semibold)
                .foregroundColor(Color("main200"))

            Text(text)
                .pretendardText(size: 15, weight: .semibold)
                .foregroundColor(Color("grey900"))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func answerLabel(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text("A.")
                .pretendardText(size: 16, weight: .semibold)
                .foregroundColor(Color("main200"))

            Text(text)
                .pretendardText(size: 14, weight: .regular)
                .foregroundColor(Color("grey900"))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Footer

    private var footerButtons: some View {
        VStack(spacing: 12) {
            Button {
                openURL(Self.kakaoChannelURL)
            } label: {
                Text("1:1 문의")
                    .pretendardText(size: 18, weight: .medium)
                    .foregroundColor(Color("grey900"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(Color("white"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color("grey200"), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)

            Button {
                openURL(Self.kakaoChannelURL)
            } label: {
                Text("신고")
                    .pretendardText(size: 18, weight: .medium)
                    .foregroundColor(Color("white"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(Color("pointRed"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color("grey100"))
    }
}

#Preview {
    FaQView(
        faqService: FaqService(
            interceptor: AuthInterceptor(authService: AuthService())
        )
    )
    .environmentObject(DIContainer())
}
