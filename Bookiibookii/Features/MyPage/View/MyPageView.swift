import SwiftUI
import Combine
import Kingfisher

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
                Image("ic_gear")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .frame(height: 68)
        .background(Color("white"))
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        VStack(spacing: 16) {
            profileImage

            HStack(spacing: 8) {
                nicknameText

                Text(formattedManner(viewModel.manner))
                    .font(.pretendard(size: 14, weight: .medium))
                    .foregroundColor(Color("main200"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color("main100"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            tagChipsRow

            statBox
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(alignment: .topTrailing) {
            Button {
                container.navigationRouter.push(to: .profileChange)
            } label: {
                Image("ic_edit")
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
        .frame(width: 180, height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 56))
        .overlay(
            RoundedRectangle(cornerRadius: 56)
                .stroke(Color("grey200"), lineWidth: 1)
        )
    }

    private var defaultProfileIcon: some View {
        Image("ic_profile_placeholder")
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

    private var tagChipsRow: some View {
        HStack(spacing: 10) {
            ForEach(viewModel.topTags, id: \.self) { code in
                CategoryChip(text: tagDisplayName(code))
            }
        }
        .frame(minHeight: 22)
    }

    private var statBox: some View {
        HStack(spacing: 0) {
            StatItem(title: "내가 읽은 책", count: "\(viewModel.completeBook)")
            statDivider
            StatItem(title: "이어 읽기", count: "\(viewModel.relayGroup)")
            statDivider
            StatItem(title: "함께 읽기", count: "\(viewModel.togetherGroup)")
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color("grey100"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color("grey200"))
            .frame(width: 1, height: 45)
    }

    // MARK: - Review

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "받은 후기",
                trailing: .chevron(action: {
                    container.navigationRouter.push(to: .recievedReview)
                })
            )

            GroupFilterFlowLayout(spacing: 12, lineSpacing: 8) {
                ForEach(viewModel.reviewBadges) { badge in
                    ReviewChip(text: badge.label, count: badge.count)
                }
            }
        }
    }

    // MARK: - Group

    private var groupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "나의 그룹",
                trailing: .toggle(
                    isExpanded: viewModel.isGroupExpanded,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.toggleGroupSection()
                        }
                    }
                )
            )

            if viewModel.isGroupExpanded {
                VStack(spacing: 8) {
                    ForEach(viewModel.groups) { group in
                        ProfileGroupCard(group: group)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Recent Books

    private var recentBooksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "최근 읽은 책", trailing: .none)

            VStack(spacing: 8) {
                ForEach(Array(viewModel.recentBooks.enumerated()), id: \.offset) { _, book in
                    RecentBookRow(book: book)
                }
            }
        }
    }

    // MARK: - Helpers

    private func formattedManner(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        return String(format: "%.1f°C", rounded)
    }

    private func tagDisplayName(_ code: String) -> String {
        ReadingTag(rawValue: code)?.displayName ?? "#\(code)"
    }
}

// MARK: - Sub Views

private struct CategoryChip: View {
    let text: String

    var body: some View {
        let display = text.hasPrefix("#") ? text : "#\(text)"
        Text(display)
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

private enum SectionTrailing {
    case none
    case chevron(action: () -> Void)
    case toggle(isExpanded: Bool, action: () -> Void)
}

private struct SectionHeader: View {
    let title: String
    let trailing: SectionTrailing

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.pretendard(size: 16, weight: .medium))
                .foregroundColor(Color("grey900"))

            Spacer()

            switch trailing {
            case .none:
                EmptyView()
            case .chevron(let action):
                Button(action: action) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("grey500"))
                }
                .buttonStyle(.plain)
            case .toggle(let isExpanded, let action):
                Button(action: action) {
                    Image("ic_chevron")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color("grey500"))
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
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
        HStack(spacing: 4) {
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
    let group: MypageGroup

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                bookInfo

                if !(group.groupTags ?? []).isEmpty {
                    HStack(spacing: 8) {
                        ForEach(group.groupTags ?? [], id: \.self) { tag in
                            CategoryChip(text: ReadingTag(rawValue: tag)?.displayName ?? "#\(tag)")
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            statusChip
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var bookInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(group.bookTitle ?? "")
                .font(.pretendard(size: 14, weight: .medium))
                .foregroundColor(Color("grey900"))
                .lineLimit(1)

            HStack(spacing: 4) {
                if let author = group.auth, !author.isEmpty {
                    Text(author)
                        .font(.pretendard(size: 12, weight: .regular))
                        .foregroundColor(Color("grey500"))
                }
                if let genre = group.genre, !genre.isEmpty {
                    Text("(\(genre))")
                        .font(.pretendard(size: 11, weight: .regular))
                        .foregroundColor(Color("grey500"))
                }
            }
        }
    }

    private var statusChip: some View {
        let isRecruiting = (group.groupStatus ?? "").uppercased() == "RECRUITING"
        let label = isRecruiting ? "모집 중" : "모집완료"
        return Text(label)
            .font(.pretendard(size: 11, weight: isRecruiting ? .medium : .regular))
            .foregroundColor(isRecruiting ? Color("white") : Color("grey500"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isRecruiting ? Color("main200") : Color("grey200"))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct RecentBookRow: View {
    let book: MypageBook

    var body: some View {
        HStack {
            Text(book.bookTitle ?? "")
                .font(.pretendard(size: 14, weight: .regular))
                .foregroundColor(Color("grey900"))
                .lineLimit(1)

            Spacer()

            StarRatingView(rating: book.rating ?? 0)
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

private struct StarRatingView: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { index in
                star(for: index)
                    .font(.system(size: 14))
                    .foregroundColor(Color("sub200"))
            }
        }
    }

    private func star(for index: Int) -> Image {
        let threshold = Double(index)
        if rating >= threshold + 1 {
            return Image(systemName: "star.fill")
        } else if rating >= threshold + 0.5 {
            return Image(systemName: "star.leadinghalf.filled")
        } else {
            return Image(systemName: "star")
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
