import SwiftUI
import Kingfisher

struct NoticeView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: NoticeViewModel

    init(noticeService: NoticeService) {
        _viewModel = StateObject(wrappedValue: NoticeViewModel(noticeService: noticeService))
    }

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if viewModel.isLoading && viewModel.notices.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            if let message = viewModel.errorMessage {
                                errorCard(message)
                            } else if viewModel.notices.isEmpty {
                                emptyCard
                            } else {
                                ForEach(viewModel.notices) { notice in
                                    Button {
                                        container.navigationRouter.push(
                                            to: .noticeDetail(noticeId: notice.id)
                                        )
                                    } label: {
                                        noticeCard(notice)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
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

            Text("공지사항")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))

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

    // MARK: - States

    private var emptyCard: some View {
        Text("공지사항이 없어요.")
            .pretendardText(size: 16, weight: .regular)
            .foregroundColor(Color("grey600"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func errorCard(_ message: String) -> some View {
        Text("공지사항을 불러오지 못했어요.\n\(message)")
            .pretendardText(size: 16, weight: .regular)
            .foregroundColor(Color("grey600"))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - Card

    private func noticeCard(_ notice: NoticeItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                HStack(spacing: 4) {
                    Text(notice.title)
                        .pretendardText(size: 16, weight: .semibold)
                        .foregroundColor(Color("grey900"))
                        .lineLimit(1)

                    if notice.isNew {
                        Circle()
                            .fill(Color("main200"))
                            .frame(width: 6, height: 6)
                    }
                }

                Spacer(minLength: 8)

                Image("ic_chevron_r")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }

            Text(notice.summary)
                .pretendardText(size: 14, weight: .regular)
                .foregroundColor(Color("grey700"))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if notice.showsAuthorMeta {
                noticeMetaRow(notice)
            } else {
                Text(notice.listDateText)
                    .pretendardText(size: 14, weight: .regular)
                    .foregroundColor(Color("grey500"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func noticeMetaRow(_ notice: NoticeItem) -> some View {
        HStack(spacing: 4) {
            HStack(spacing: 8) {
                noticeProfileImage(urlString: notice.authorProfileImageUrl)
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())

                Text(notice.authorNickname ?? "")
                    .pretendardText(size: 14, weight: .medium)
                    .foregroundColor(Color("grey800"))
            }

            Text("·")
                .pretendardText(size: 14, weight: .regular)
                .foregroundColor(Color("grey500"))

            Text(notice.listDateText)
                .pretendardText(size: 14, weight: .regular)
                .foregroundColor(Color("grey500"))
        }
    }

    @ViewBuilder
    private func noticeProfileImage(urlString: String?) -> some View {
        if let urlString, let url = URL(string: urlString) {
            KFImage(url)
                .placeholder { Color("grey200") }
                .resizable()
                .scaledToFill()
        } else {
            Color("grey200")
        }
    }
}

#Preview {
    NoticeView(
        noticeService: NoticeService(
            interceptor: AuthInterceptor(authService: AuthService())
        )
    )
    .environmentObject(DIContainer())
}
