import SwiftUI

struct MyPageView: View {
    @EnvironmentObject private var container: DIContainer
    @State private var isLoggingOut = false

    var body: some View {
        VStack {
            Text("마이페이지")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: logout) {
                Group {
                    if isLoggingOut {
                        ProgressView()
                            .tint(.white)
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
            .disabled(isLoggingOut)
            .padding(.horizontal, 20)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("grey100"))
    }

    private func logout() {
        guard !isLoggingOut else { return }
        isLoggingOut = true

        Task {
            // 서버에 로그아웃 요청 (실패해도 로컬 토큰은 삭제)
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

#Preview {
    MyPageView()
        .environmentObject(DIContainer())
}
