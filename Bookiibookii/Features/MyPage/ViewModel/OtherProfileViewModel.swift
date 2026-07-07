import Foundation
import Combine

@MainActor
final class OtherProfileViewModel: ObservableObject {
    let nickname: String

    @Published var profile: MypageResult?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let userService: UserService

    init(nickname: String, userService: UserService) {
        self.nickname = nickname
        self.userService = userService
    }

    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            profile = try await userService.getUserProfile(nickname: nickname)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "프로필을 불러오지 못했습니다."
        }
    }

    var displayNickname: String { profile?.nickname ?? nickname }
    var userBooks: [MypageUserBook] { profile?.userBooks ?? [] }
    var bookReviewCount: Int { profile?.bookReviewCount ?? 0 }
    var recentBookReviews: [MypageBookReview] { profile?.recentBookReviews ?? [] }
    var boomUpCount: Int { profile?.boomUpCount ?? 0 }
    var recentReceivedReviews: [MypageReceivedReview] { profile?.recentReceivedReviews ?? [] }
}
