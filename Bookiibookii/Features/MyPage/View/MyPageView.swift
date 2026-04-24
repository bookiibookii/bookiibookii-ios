import SwiftUI

struct MyPageView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: MyPageViewModel

    init(userService: UserService) {
        _viewModel = StateObject(wrappedValue: MyPageViewModel(userService: userService))
    }

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        profileCard
                            .padding(.top, 16)

                        reviewSection
                            .padding(.top, 32)

                        groupSection
                            .padding(.top, 32)

                        recentBooksSection
                            .padding(.top, 32)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .task {
            await viewModel.loadProfile()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("마이페이지")
                .font(.pretendard(size: 24, weight: .medium))
                .foregroundColor(Color("grey900"))

            Spacer()

            Button {
                container.navigationRouter.push(to: .setting)
            } label: {
                Image("ic_setting")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 24)
        .padding(.trailing, 24)
        .frame(height: 68)
        .background(Color("white"))
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        VStack(spacing: 16) {
            editableProfileImage

            HStack(spacing: 8) {
                nicknameText

                Text("37.5°C")
                    .font(.pretendard(size: 14, weight: .medium))
                    .foregroundColor(Color("main200"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color("main100"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            HStack(spacing: 10) {
                CategoryChip(text: "인사이트")
                CategoryChip(text: "깔끔")
                CategoryChip(text: "메모환영")
            }

            HStack {
                StatItem(title: "내가 읽은 책", count: "12")
                Divider().frame(height: 45)
                StatItem(title: "이어 읽기", count: "5")
                Divider().frame(height: 45)
                StatItem(title: "함께 읽기", count: "2")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color("grey100"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal, 45)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(alignment: .topTrailing) {
            Button {
                container.navigationRouter.push(to: .profileChange)
            } label: {
                Image("pencil")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            .padding(.trailing, 16)
        }
    }

    private var editableProfileImage: some View {
        profileImage
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
        .frame(width: 180, height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 56))
        .overlay(
            RoundedRectangle(cornerRadius: 56)
                .stroke(Color("grey200"), lineWidth: 1)
        )
    }

    private var defaultProfileIcon: some View {
        Image("img_profile_default")
            .resizable()
            .scaledToFill()
    }

    private var nicknameText: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                Text(viewModel.profile?.nickname ?? "-")
                    .font(.pretendard(size: 20, weight: .regular))
                    .foregroundColor(Color("grey900"))
            }
        }
    }

    // MARK: - Review

    private var reviewSection: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "받은 후기",
                hasChevron: true,
                onChevronTap: { container.navigationRouter.push(to: .recievedReview) }
            )

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 10
            ) {
                ReviewChip(text: "친절하고 매너가 좋아요", count: 8)
                ReviewChip(text: "글씨가 예뻐요", count: 5)
                ReviewChip(text: "코멘트가 다정해요", count: 9)
                ReviewChip(text: "책에 대한 인사이트가 넘쳐요", count: 3)
                ReviewChip(text: "책을 빠르게 보내줬어요", count: 6)
                ReviewChip(text: "코멘트가 재미있어요", count: 12)
                ReviewChip(text: "책을 깨끗하고 깔끔하게 읽어요", count: 3)
            }
        }
    }

    // MARK: - Group

    private var groupSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "나의그룹", hasChevron: true)

            VStack(spacing: 10) {
                ProfileGroupCard(status: "모집 중", isOpen: true)
                ProfileGroupCard(status: "모집완료", isOpen: false)
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
}

// MARK: - Sub Views

private struct CategoryChip: View {
    let text: String

    var body: some View {
        HStack(spacing: 0) {
            Text("#")
            Text(text)
        }
        .font(.pretendard(size: 11, weight: .regular))
        .foregroundColor(Color("sub200"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        .background(Color("sub100"))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct StatItem: View {
    let title: String
    let count: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.pretendard(size: 10, weight: .regular))
                .foregroundColor(Color("grey700"))

            Text(count)
                .font(.pretendard(size: 24, weight: .medium))
                .foregroundColor(Color("main200"))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SectionHeader: View {
    let title: String
    let hasChevron: Bool
    var onChevronTap: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.pretendard(size: 16, weight: .medium))
                .foregroundColor(Color("grey900"))

            Spacer()

            if hasChevron {
                Button {
                    onChevronTap?()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("grey500"))
                }
                .buttonStyle(.plain)
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
                .font(.pretendard(size: 12, weight: .regular))
                .foregroundColor(Color("grey900"))

            Text("\(count)")
                .font(.pretendard(size: 12, weight: .regular))
                .foregroundColor(Color("main200"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct ProfileGroupCard: View {
    let status: String
    let isOpen: Bool

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("괴테는 모든 것을 말했다")
                    .font(.pretendard(size: 14, weight: .medium))
                    .foregroundColor(Color("grey900"))

                Text("스즈키 유이 (소설)")
                    .font(.pretendard(size: 12, weight: .regular))
                    .foregroundColor(Color("grey500"))

                HStack(spacing: 6) {
                    CategoryChip(text: "메모환영")
                    CategoryChip(text: "인사이트")
                    CategoryChip(text: "깔끔")
                }
            }

            Spacer()

            Text(status)
                .font(.pretendard(size: 11, weight: isOpen ? .medium : .regular))
                .foregroundColor(isOpen ? Color("white") : Color("grey500"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isOpen ? Color("main200") : Color("grey200"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct RecentBookRow: View {
    var body: some View {
        HStack {
            Text("책 제목")
                .font(.pretendard(size: 14, weight: .regular))
                .foregroundColor(Color("grey900"))

            Spacer()

            HStack(spacing: 0) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: index < 3 ? "star.fill" : "star")
                        .font(.system(size: 13))
                        .foregroundColor(index < 3 ? Color("sub200") : Color("grey300"))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color("grey100"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
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
