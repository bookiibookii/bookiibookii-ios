import Foundation
import Combine

@MainActor
final class QustionDetailViewModel: ObservableObject {
    @Published var title = ""
    @Published var content = ""
    @Published var isSubmitting = false

    private let inquiryService: InquiryService

    init(inquiryService: InquiryService) {
        self.inquiryService = inquiryService
    }

    var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isSubmitting
    }

    func submit() async -> Bool {
        guard canSubmit else { return false }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await inquiryService.createInquiry(
                InquiryCreateRequestDto(
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    content: content.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            )
            return true
        } catch {
            print("문의 등록 실패: \(error)")
            return false
        }
    }
}
