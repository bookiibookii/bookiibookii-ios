import Foundation
import Combine

@MainActor
final class FaQViewModel: ObservableObject {
    @Published private(set) var items: [FaqItem] = []
    @Published var expandedFaqId: Int?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let faqService: FaqService

    init(faqService: FaqService) {
        self.faqService = faqService
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await faqService.fetchFaqList()
            items = result
                .sorted {
                    let left = $0.displayOrder ?? Int.max
                    let right = $1.displayOrder ?? Int.max
                    if left == right { return $0.id < $1.id }
                    return left < right
                }
                .map(FaqItem.init(dto:))
            expandedFaqId = items.first?.id
        } catch {
            items = []
            expandedFaqId = nil
            errorMessage = error.localizedDescription
        }
    }

    func toggle(_ id: Int) {
        expandedFaqId = expandedFaqId == id ? nil : id
    }
}
