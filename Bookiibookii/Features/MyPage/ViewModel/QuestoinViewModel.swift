import Foundation
import Combine

@MainActor
final class QuestoinViewModel: ObservableObject {
    @Published var items: [QuestionItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let inquiryService: InquiryService

    init(inquiryService: InquiryService) {
        self.inquiryService = inquiryService
    }

    var isEmpty: Bool { items.isEmpty }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let result = try await inquiryService.fetchInquiryList()
            items = result.map(QuestionItem.init(dto:))
                .sorted(by: { $0.createdAt > $1.createdAt })
        } catch {
            items = []
            errorMessage = error.localizedDescription
            print("문의 목록 조회 실패: \(error)")
        }
    }
}
