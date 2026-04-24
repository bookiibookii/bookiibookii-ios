import Foundation
import Combine

@MainActor
final class QuestoinViewModel: ObservableObject {
    @Published var items: [QuestionItem] = []
    @Published var isLoading = false

    private let store: QuestionStore

    init(store: QuestionStore = LocalQuestionStore.shared) {
        self.store = store
    }

    var isEmpty: Bool { items.isEmpty }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do { items = try await store.fetchQuestions() }
        catch { print("문의 목록 조회 실패: \(error)") }
    }
}
