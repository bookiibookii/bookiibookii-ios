import Foundation

@MainActor
final class NoticeViewModel: ObservableObject {
    @Published var notices: [NoticeItem] = []
    @Published var isLoading = false

    private let store: NoticeStore

    init(store: NoticeStore = LocalNoticeStore.shared) {
        self.store = store
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            notices = try await store.fetchNotices()
        } catch {
            print("공지사항 조회 실패: \(error)")
        }
    }
}
