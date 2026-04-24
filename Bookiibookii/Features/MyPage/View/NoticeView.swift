import SwiftUI

struct NoticeView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel = NoticeViewModel()

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                CustomNavigationBar(
                    title: "공지사항",
                    onBack: { container.navigationRouter.pop() },
                    rightButton: .none
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if viewModel.isLoading {
                            ProgressView().padding(.top, 40)
                        } else {
                            ForEach(viewModel.notices) { notice in
                                Button {
                                    container.navigationRouter.push(
                                        to: .noticeDetail(
                                            title: notice.title,
                                            dateText: notice.detailDateText,
                                            content: notice.content
                                        )
                                    )
                                } label: {
                                    noticeCard(notice)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task { await viewModel.load() }
    }

    private func noticeCard(_ notice: NoticeItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                Text(notice.title)
                    .font(.pretendard(size: 14, weight: .medium))
                    .foregroundColor(Color("grey900"))

                if notice.isUnread {
                    Circle()
                        .fill(Color("main200"))
                        .frame(width: 8, height: 8)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("grey500"))
            }

            Text(notice.content)
                .font(.pretendard(size: 14, weight: .regular))
                .foregroundColor(Color("grey700"))
                .multilineTextAlignment(.leading)
                .lineLimit(2)

            Text(notice.relativeDateText)
                .font(.pretendard(size: 12, weight: .regular))
                .foregroundColor(Color("grey400"))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    NoticeView()
        .environmentObject(DIContainer())
}
