import Foundation
import Combine

final class MyPageViewModel: ObservableObject {
    @Published var profile: MypageResult?
    @Published var isLoading = false

    private let userService: UserService

    init(userService: UserService) {
        self.userService = userService
    }

    func loadProfile() async {
        await MainActor.run {
            isLoading = true
        }

        do {
            let result = try await userService.getMypage()

            await MainActor.run {
                self.profile = result
                self.isLoading = false
            }
        } catch {
            print("프로필 로드 실패: \(error)")

            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}
