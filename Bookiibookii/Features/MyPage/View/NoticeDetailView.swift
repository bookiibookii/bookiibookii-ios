import SwiftUI

struct NoticeDetailView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: NoticeDetailViewModel

    init(noticeId: Int, noticeService: NoticeService) {
        _viewModel = StateObject(
            wrappedValue: NoticeDetailViewModel(noticeId: noticeId, noticeService: noticeService)
        )
    }

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if viewModel.isLoading && viewModel.detail == nil {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if let detail = viewModel.detail {
                    ScrollView(showsIndicators: false) {
                        detailCard(detail)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 32)
                    }
                } else {
                    Spacer()
                    Text(viewModel.errorMessage ?? "공지사항을 불러오지 못했어요.")
                        .pretendardText(size: 16, weight: .regular)
                        .foregroundColor(Color("grey600"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Spacer()
                }
            }
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

            Text(viewModel.detail?.title ?? "공지사항")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))
                .lineLimit(1)

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

    // MARK: - Detail Card

    private func detailCard(_ detail: NoticeDetailItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if detail.showsAuthorMeta {
                authorMetaRow(detail)
            } else {
                HStack(spacing: 4) {
                    Text(detail.detailDateOnlyText)
                        .pretendardText(size: 14, weight: .regular)
                        .foregroundColor(Color("grey500"))
                    Text(detail.detailTimeOnlyText)
                        .pretendardText(size: 14, weight: .regular)
                        .foregroundColor(Color("grey500"))
                }
            }

            MarkdownText(markdown: detail.content)
                .multilineTextAlignment(.leading)
        }
        .padding(.leading, 20)
        .padding(.trailing, 32)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func authorMetaRow(_ detail: NoticeDetailItem) -> some View {
        HStack(spacing: 4) {
            HStack(spacing: 8) {
                ProfilePlaceholder(imageUrl: detail.authorProfileImageUrl, size: 22)

                Text(detail.authorNickname ?? "")
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey800"))
            }

            Text("·")
                .pretendardText(size: 14, weight: .regular)
                .foregroundColor(Color("grey500"))

            Text(detail.detailDateOnlyText)
                .pretendardText(size: 14, weight: .regular)
                .foregroundColor(Color("grey500"))

            Text(detail.detailTimeOnlyText)
                .pretendardText(size: 14, weight: .regular)
                .foregroundColor(Color("grey500"))
        }
    }
}

#Preview {
    NoticeDetailView(
        noticeId: 1,
        noticeService: NoticeService(
            interceptor: AuthInterceptor(authService: AuthService())
        )
    )
    .environmentObject(DIContainer())
}
