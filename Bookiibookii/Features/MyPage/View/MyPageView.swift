import SwiftUI
import Combine

struct MyPageView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: MyPageViewModel

    init(userService: UserService) {
        _viewModel = StateObject(wrappedValue: MyPageViewModel(userService: userService))
    }

    var body: some View {
        ZStack {
            Color("grey100")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    profileCard
                    reviewSection
                    groupSection
                    recentBooksSection
                    logoutButton
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .task {
            await viewModel.loadProfile()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("마이페이지")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color("grey900"))

            Spacer()

            Image(systemName: "gearshape")
                .font(.system(size: 15))
                .foregroundColor(Color("grey700"))
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        VStack(spacing: 14) {
            editableProfileImage

            HStack(spacing: 6) {
                nicknameText

                Text("37.5°C")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.18))
                    .clipShape(Capsule())
            }

            HStack(spacing: 6) {
                CategoryChip(text: "미스터리")
                CategoryChip(text: "비문학")
                CategoryChip(text: "내마음대로")
            }

            HStack {
                StatItem(title: "내가 읽은 책", count: "12")
                Divider().frame(height: 26)
                StatItem(title: "마이셀 독서", count: "5")
                Divider().frame(height: 26)
                StatItem(title: "함께 읽기", count: "2")
            }
            .padding(.horizontal, 18)
            .padding(.top, 4)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var editableProfileImage: some View {
        ZStack(alignment: .topTrailing) {
            profileImage

            Circle()
                .fill(Color.white)
                .frame(width: 23, height: 23)
                .overlay(
                    Image(systemName: "pencil")
                        .font(.system(size: 11))
                        .foregroundColor(Color("grey400"))
                )
                .offset(x: 5, y: -4)
        }
    }

    private var profileImage: some View {
        Group {
            if let urlStr = viewModel.profile?.profileImageUrl,
               let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

                    case .failure, .empty:
                        defaultProfileIcon

                    @unknown default:
                        defaultProfileIcon
                    }
                }
            } else {
                defaultProfileIcon
            }
        }
        .frame(width: 98, height: 98)
        .clipShape(RoundedRectangle(cornerRadius: 34))
        .overlay(
            RoundedRectangle(cornerRadius: 34)
                .stroke(Color("grey200"), lineWidth: 1)
        )
    }

    private var defaultProfileIcon: some View {
        RoundedRectangle(cornerRadius: 34)
            .fill(Color.gray.opacity(0.45))
            .overlay(
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(28)
                    .foregroundColor(Color("grey400"))
            )
    }

    private var nicknameText: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                Text(viewModel.profile?.nickname ?? "-")
                    .font(.system(size: 12))
                    .foregroundColor(Color("grey900"))
            }
        }
    }

    // MARK: - Review

    private var reviewSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "받은 후기", hasChevron: true)

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 10
            ) {
                ReviewChip(text: "친절하고 배려가 좋아요", count: 8)
                ReviewChip(text: "글쓰기 실력이 좋아요", count: 5)
                ReviewChip(text: "코멘트가 다정해요", count: 9)
                ReviewChip(text: "책에 대한 인사이트가 넘쳐요", count: 3)
                ReviewChip(text: "책을 빠르게 보내줘요", count: 6)
                ReviewChip(text: "책읽기가 재미있어요", count: 12)
                ReviewChip(text: "책을 깨끗하고 꼼꼼하게 읽어요", count: 3)
            }
        }
    }

    // MARK: - Group

    private var groupSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "나의그룹", hasChevron: true)

            VStack(spacing: 10) {
                ProfileGroupCard(status: "모집중", statusColor: .orange)
                ProfileGroupCard(status: "모집완료", statusColor: .gray)
            }
        }
    }

    // MARK: - Recent Books

    private var recentBooksSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "최근 읽은 책", hasChevron: false)

            VStack(spacing: 10) {
                RecentBookRow()
                RecentBookRow()
                RecentBookRow()
            }
        }
    }

    // MARK: - Logout

    private var logoutButton: some View {
        Button(action: logout) {
            Group {
                if viewModel.isLoggingOut {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("로그아웃")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .background(Color("main200"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .disabled(viewModel.isLoggingOut)
        .padding(.top, 8)
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
                viewModel.isLoggingOut = false
                container.navigationRouter.hardReset(to: .login)
            }
        }
    }
}

// MARK: - Sub Views

private struct CategoryChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 8, weight: .medium))
            .foregroundColor(.blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.12))
            .clipShape(Capsule())
    }
}

private struct StatItem: View {
    let title: String
    let count: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 9))
                .foregroundColor(.gray)

            Text(count)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.orange)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SectionHeader: View {
    let title: String
    let hasChevron: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color("grey900"))

            Spacer()

            if hasChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
        }
    }
}

private struct ReviewChip: View {
    let text: String
    let count: Int

    var body: some View {
        HStack(spacing: 3) {
            Text(text)
                .font(.system(size: 8))
                .foregroundColor(.black.opacity(0.75))

            Text("\(count)")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(Color.white)
        .clipShape(Capsule())
    }
}

private struct ProfileGroupCard: View {
    let status: String
    let statusColor: Color

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("괴테는 모든 것을 말했다")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.black)

                Text("스즈키 유키 (소설)")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)

                HStack(spacing: 6) {
                    CategoryChip(text: "#미스터리")
                    CategoryChip(text: "#방구석책")
                    CategoryChip(text: "#감동")
                }
                .padding(.top, 3)
            }

            Spacer()

            Text(status)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(statusColor)
                .clipShape(Capsule())
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct RecentBookRow: View {
    var body: some View {
        HStack {
            Text("책 제목")
                .font(.system(size: 11))
                .foregroundColor(.black)

            Spacer()

            HStack(spacing: 1) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: index < 3 ? "star.fill" : "star")
                        .font(.system(size: 12))
                        .foregroundColor(index < 3 ? .blue : .gray.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
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

#Preview {
    MyPageView(
        userService: UserService(
            interceptor: AuthInterceptor(
                authService: AuthService()
            )
        )
    )
    .environmentObject(DIContainer())
}
