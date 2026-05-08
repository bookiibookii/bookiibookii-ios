import Foundation
import Combine

@MainActor
final class NoticeViewModel: ObservableObject {
    @Published var notices: [NoticeItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let noticeService: NoticeService

    init(noticeService: NoticeService) {
        self.noticeService = noticeService
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await noticeService.fetchNoticeList()
            notices = result
                .map(NoticeItem.init(dto:))
                .sorted(by: { $0.createdAt > $1.createdAt })
        } catch {
            notices = []
            errorMessage = error.localizedDescription
            print("공지사항 조회 실패: \(error)")
        }
    }

    func fetchDetail(noticeId: Int) async throws -> NoticeDetailItem {
        let dto = try await noticeService.fetchNoticeDetail(noticeId: noticeId)
        return NoticeDetailItem(dto: dto)
    }
}
