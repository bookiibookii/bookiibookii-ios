import SwiftUI
import Combine
import Kingfisher

// 안드로이드 MypageFragment 대응 (심플 버전: 프로필 사진 + 닉네임)
struct MyPageView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: MyPageViewModel

    init(userService: UserService) {
        _viewModel = StateObject(wrappedValue: MyPageViewModel(userService: userService))
    }

    var body: some View {
        VStack(spacing: 0) {
            profileSection
                .padding(.top, 48)

            Spacer()

            logoutButton
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("grey100"))
        .task { await viewModel.loadProfile() }
    }

    // MARK: - 프로필 영역
    private var profileSection: some View {
        VStack(spacing: 16) {
            profileImage
            nicknameText
        }
    }

    private var profileImage: some View {
        Group {
            if let urlStr = viewModel.profile?.profileImageUrl,
               let url = URL(string: urlStr) {
                KFImage(url)
                    .placeholder { defaultProfileIcon }
                    .retry(maxCount: 2)
                    .cancelOnDisappear(true)
                    .resizable()
                    .scaledToFill()
            } else {
                defaultProfileIcon
            }
        }
        .frame(width: 90, height: 90)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color("grey200"), lineWidth: 1))
    }

    private var defaultProfileIcon: some View {
        Image(systemName: "person.fill")
            .resizable()
            .scaledToFit()
            .padding(20)
            .foregroundColor(Color("grey400"))
            .background(Color("grey200"))
    }

    private var nicknameText: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else {
                Text(viewModel.profile?.nickname ?? "-")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color("grey900"))
            }
        }
    }

    // MARK: - 로그아웃 버튼
    private var logoutButton: some View {
        Button(action: logout) {
            Group {
                if viewModel.isLoggingOut {
                    ProgressView().tint(.white)
                } else {
                    Text("로그아웃")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .background(Color("main200"))
        .cornerRadius(8)
        .disabled(viewModel.isLoggingOut)
    }

    private func logout() {
        guard !viewModel.isLoggingOut else { return }
        viewModel.isLoggingOut = true

        Task {
            if let token = TokenManager.shared.accessToken {
                await container.api.auth.logout(accessToken: token)
            }
            TokenManager.shared.clear()
            await MainActor.run {
                container.navigationRouter.hardReset(to: .login)
            }
        }
    }
}

// MARK: - ViewModel
final class MyPageViewModel: ObservableObject {
    @Published var profile: MypageResult?
    @Published var isLoading = false
    @Published var isLoggingOut = false

    private let userService: UserService

    init(userService: UserService) {
        self.userService = userService
    }

    func loadProfile() async {
        await MainActor.run { isLoading = true }
        do {
            let result = try await userService.getMypage()
            await MainActor.run {
                self.profile = result
                self.isLoading = false
            }
        } catch {
            print("❌ 프로필 로드 실패: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
}

#Preview {
    MyPageView(userService: UserService(interceptor: AuthInterceptor(authService: AuthService())))
        .environmentObject(DIContainer())
}
