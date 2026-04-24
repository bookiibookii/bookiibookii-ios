import Foundation

struct QuestionItem: Identifiable, Codable, Equatable {
    enum Status: String, Codable { case waiting, answered }
    let id: String
    let author: String
    let createdAt: Date
    let title: String
    let content: String
    let status: Status
    let answerAuthor: String?
    let answerDate: Date?
    let answerContent: String?
}

struct QuestionCreatePayload {
    let title: String
    let content: String
}

protocol QuestionStore {
    func fetchQuestions() async throws -> [QuestionItem]
    func createQuestion(_ payload: QuestionCreatePayload) async throws
}

actor LocalQuestionStore: QuestionStore {
    static let shared = LocalQuestionStore()
    private let key = "mypage_question_items_v1"

    func fetchQuestions() async throws -> [QuestionItem] {
        if let stored = loadFromDisk() { return stored.sorted(by: { $0.createdAt > $1.createdAt }) }
        let seeded = seedItems()
        saveToDisk(seeded)
        return seeded
    }

    func createQuestion(_ payload: QuestionCreatePayload) async throws {
        var items = loadFromDisk() ?? seedItems()
        items.insert(
            QuestionItem(id: UUID().uuidString, author: "noshel", createdAt: Date(), title: payload.title, content: payload.content, status: .waiting, answerAuthor: nil, answerDate: nil, answerContent: nil),
            at: 0
        )
        saveToDisk(items)
    }

    private func loadFromDisk() -> [QuestionItem]? {
        guard let data = UserDefaults.standard.data(forKey: key), let decoded = try? JSONDecoder().decode([QuestionItem].self, from: data) else { return nil }
        return decoded
    }

    private func saveToDisk(_ items: [QuestionItem]) {
        guard let encoded = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(encoded, forKey: key)
    }

    private func seedItems() -> [QuestionItem] {
        let date = Calendar.current.date(from: DateComponents(year: 2024, month: 11, day: 29)) ?? Date()
        return [
            QuestionItem(id: UUID().uuidString, author: "noshel", createdAt: date, title: "독서 카드 사용법", content: "독서 카드는 어떻게 사용하나요?", status: .waiting, answerAuthor: nil, answerDate: nil, answerContent: nil),
            QuestionItem(id: UUID().uuidString, author: "noshel", createdAt: date, title: "책 배송 관련 문의드립니다.", content: "안녕하세요, 혹시 책 배송은 어떻게 진행되나요?", status: .answered, answerAuthor: "부키부키 팀", answerDate: date, answerContent: "안녕하세요! 책 배송은 택배 또는 우편으로 진행됩니다. 교환이 확정되면 상대방과 주소를 공유하시면 됩니다.")
        ]
    }
}
