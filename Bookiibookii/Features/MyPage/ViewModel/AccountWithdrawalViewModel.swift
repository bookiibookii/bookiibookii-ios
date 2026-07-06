import Foundation

@MainActor
final class AccountWithdrawalViewModel: ObservableObject {
    @Published var nickname: String = ""
    @Published var selectedReason: WithdrawalReason?
    @Published var customReason: String = ""
    @Published var isLoadingProfile = false
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var showActiveGroupRestriction = false

    private let userService: UserService

    init(userService: UserService) {
        self.userService = userService
    }

    var canProceed: Bool {
        guard let selectedReason else { return false }
        if selectedReason == .customInput {
            return !customReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }

    func loadProfile() async {
        guard nickname.isEmpty else { return }
        isLoadingProfile = true
        defer { isLoadingProfile = false }

        do {
            let profile = try await userService.getMypage()
            nickname = profile.nickname
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "프로필을 불러오지 못했습니다."
        }
    }

    func withdraw() async -> Bool {
        guard let selectedReason, canProceed else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        let trimmedCustomReason = customReason.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = WithdrawalRequest(
            reason: selectedReason,
            customReason: selectedReason == .customInput ? trimmedCustomReason : nil
        )

        do {
            try await userService.withdraw(request)
            return true
        } catch UserError.activeGroupExists {
            showActiveGroupRestriction = true
            return false
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "회원탈퇴에 실패했습니다."
            return false
        }
    }
}
