import Foundation
import Combine

@MainActor
final class NoticeDetailViewModel: ObservableObject {
    @Published private(set) var detail: NoticeDetailItem?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let noticeId: Int
    private let noticeService: NoticeService

    init(noticeId: Int, noticeService: NoticeService) {
        self.noticeId = noticeId
        self.noticeService = noticeService
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let dto = try await noticeService.fetchNoticeDetail(noticeId: noticeId)
            detail = NoticeDetailItem(dto: dto)
        } catch {
            detail = nil
            errorMessage = error.localizedDescription
        }
    }
}
