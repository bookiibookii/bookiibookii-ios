import SwiftUI

struct NoticeDetailView: View {
    @EnvironmentObject private var container: DIContainer

    let noticeId: Int
    private let noticeService: NoticeService

    @State private var detail: NoticeDetailItem?
    @State private var isLoading = false

    init(noticeId: Int, noticeService: NoticeService) {
        self.noticeId = noticeId
        self.noticeService = noticeService
    }

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                CustomNavigationBar(
                    title: detail?.title ?? "공지사항",
                    onBack: { container.navigationRouter.pop() },
                    rightButton: .none
                )

                ScrollView(showsIndicators: false) {
                    if isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else if let detail {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(detail.detailDateText)
                                .font(.pretendard(size: 12, weight: .regular))
                                .foregroundColor(Color("grey400"))

                            Text(detail.content)
                                .font(.pretendard(size: 14, weight: .regular))
                                .foregroundColor(Color("grey700"))
                                .multilineTextAlignment(.leading)
                                .lineSpacing(2)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color("white"))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task { await loadDetail() }
    }

    @MainActor
    private func loadDetail() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let dto = try await noticeService.fetchNoticeDetail(noticeId: noticeId)
            detail = NoticeDetailItem(dto: dto)
        } catch {
            print("공지 상세 조회 실패: \(error)")
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
