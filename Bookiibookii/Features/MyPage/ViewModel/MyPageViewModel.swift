import Foundation
import Combine

@MainActor
final class MyPageViewModel: ObservableObject {
    static let introMaxLength = 50

    @Published var profile: MypageResult?
    @Published var isLoading = false
    @Published var isEditingIntroduction = false
    @Published var introductionDraft = ""
    @Published var isSavingIntroduction = false
    @Published var introductionErrorMessage: String?

    private let userService: UserService

    init(userService: UserService) {
        self.userService = userService
    }

    func loadProfile(showLoading: Bool = true) async {
        if showLoading { isLoading = true }
        defer { if showLoading { isLoading = false } }

        do {
            profile = try await userService.getMypage()
        } catch {
            print("프로필 로드 실패: \(error)")
        }
    }

    func beginEditingIntroduction() {
        introductionDraft = profile?.introduction ?? ""
        isEditingIntroduction = true
    }

    func cancelEditingIntroduction() {
        introductionDraft = profile?.introduction ?? ""
        isEditingIntroduction = false
    }

    func updateIntroductionDraft(_ value: String) {
        introductionDraft = String(value.prefix(Self.introMaxLength))
    }

    func saveIntroduction() async {
        let trimmed = introductionDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        isSavingIntroduction = true
        introductionErrorMessage = nil
        defer { isSavingIntroduction = false }

        do {
            try await userService.updateIntroduction(trimmed)
            await loadProfile(showLoading: false)
            isEditingIntroduction = false
        } catch {
            introductionErrorMessage = "한 줄 소개 저장에 실패했어요. 잠시 후 다시 시도해 주세요."
        }
    }

    var userBooks: [MypageUserBook] { profile?.userBooks ?? [] }
    var bookReviewCount: Int { profile?.bookReviewCount ?? 0 }
    var recentBookReviews: [MypageBookReview] { profile?.recentBookReviews ?? [] }
    var boomUpCount: Int { profile?.boomUpCount ?? 0 }
    var recentReceivedReviews: [MypageReceivedReview] { profile?.recentReceivedReviews ?? [] }
}
