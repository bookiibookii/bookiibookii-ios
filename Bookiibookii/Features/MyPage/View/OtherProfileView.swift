import SwiftUI

struct NicknameRoute: Identifiable, Hashable {
    let nickname: String
    var id: String { nickname }
}

struct OtherProfileView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: OtherProfileViewModel
    @State private var nestedProfileRoute: NicknameRoute?
    var onClose: (() -> Void)?

    init(nickname: String, userService: UserService, onClose: (() -> Void)? = nil) {
        _viewModel = StateObject(
            wrappedValue: OtherProfileViewModel(nickname: nickname, userService: userService)
        )
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            if let errorMessage = viewModel.errorMessage, viewModel.profile == nil, !viewModel.isLoading {
                errorContent(errorMessage)
            } else {
                VStack(spacing: 0) {
                    topBar

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            profileCard
                            writtenReviewsSection
                            receivedReviewsSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .task { await viewModel.loadProfile() }
        .fullScreenCover(item: $nestedProfileRoute) { route in
            NavigationStack {
                OtherProfileView(
                    nickname: route.nickname,
                    userService: container.api.user,
                    onClose: { nestedProfileRoute = nil }
                )
                .environmentObject(container)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var isModalPresentation: Bool { onClose != nil }

    private func openProfile(nickname: String) {
        if isModalPresentation {
            nestedProfileRoute = NicknameRoute(nickname: nickname)
        } else {
            container.navigationRouter.push(to: .userProfile(nickname: nickname))
        }
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            container.navigationRouter.pop()
        }
    }

    private func errorContent(_ message: String) -> some View {
        VStack(spacing: 16) {
            Text(message)
                .pretendardText(size: 16, weight: .regular)
                .foregroundColor(Color("grey600"))
                .multilineTextAlignment(.center)

            Button("다시 시도") {
                Task { await viewModel.loadProfile() }
            }
            .pretendardText(size: 15, weight: .medium)
            .foregroundColor(Color("main200"))
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Header

    private var topBar: some View {
        HStack {
            Button(action: close) {
                Image("ic_back")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("\(viewModel.displayNickname) 님의 프로필")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))
                .lineLimit(1)

            Spacer()

            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color("grey200")).frame(height: 1)
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        VStack(spacing: 24) {
            profileRow
                .padding(.horizontal, 16)

            introductionSection
                .padding(.horizontal, 16)

            bookshelfSection
                .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
    }

    private var profileRow: some View {
        HStack(spacing: 12) {
            ProfilePlaceholder(imageUrl: viewModel.profile?.profileImageUrl, size: 52)

            if viewModel.isLoading {
                ProgressView().scaleEffect(0.8)
            } else {
                Text(viewModel.displayNickname)
                    .pretendardText(size: 20, weight: .semibold)
                    .foregroundColor(Color("grey900"))
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - 한 줄 소개

    private var introductionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("한 줄 소개")
                    .pretendardText(size: 16, weight: .semibold)
                    .foregroundColor(Color("grey900"))
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Image("ic_quote")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)

                if let intro = viewModel.profile?.introduction, !intro.isEmpty {
                    Text(intro)
                        .pretendardText(size: 15, weight: .medium)
                        .foregroundColor(Color("grey700"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("아직 대표 문구를 입력하지 않았어요.")
                        .pretendardText(size: 15, weight: .regular)
                        .foregroundColor(Color("grey500"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("grey100"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - 책장

    private var bookshelfSection: some View {
        VStack(spacing: 16) {
            bookshelfHeader

            if !viewModel.userBooks.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(Array(viewModel.userBooks.enumerated()), id: \.element.id) { index, book in
                            OtherProfileBookSpine(title: book.title, colorIndex: index)
                        }
                    }
                    .padding(.top, 16)
                }
            }
        }
    }

    private var bookshelfHeader: some View {
        HStack(spacing: 8) {
            Text("\(viewModel.displayNickname) 님의 책장")
                .pretendardText(size: 16, weight: .semibold)
                .foregroundColor(Color("grey900"))

            Text("\(viewModel.userBooks.count)/7권")
                .pretendardText(size: 11, weight: .medium)
                .foregroundColor(Color("grey900"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color("white"))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color("grey200"), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer(minLength: 0)
        }
    }

    // MARK: - 작성한 후기

    private var writtenReviewsSection: some View {
        VStack(spacing: 8) {
            sectionHeader(title: "작성한 후기")

            summaryCard {
                HStack(spacing: 8) {
                    Image("ic_book")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)

                    HStack(spacing: 0) {
                        Text("\(viewModel.bookReviewCount)")
                            .pretendardText(size: 16, weight: .medium)
                            .foregroundColor(Color("grey900"))
                        Text("권의 책에 후기를 남겼어요.")
                            .pretendardText(size: 16, weight: .regular)
                            .foregroundColor(Color("grey700"))
                    }
                }
            }

            if viewModel.recentBookReviews.isEmpty {
                emptyStateCard("작성한 후기가 없어요.")
            } else {
                ForEach(viewModel.recentBookReviews) { review in
                    OtherProfileWrittenReviewCard(review: review)
                }
            }
        }
    }

    // MARK: - 받은 후기

    private var receivedReviewsSection: some View {
        VStack(spacing: 8) {
            sectionHeader(title: "받은 후기")

            summaryCard {
                HStack(spacing: 8) {
                    Image("ic_boomup")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)

                    receivedSummaryText
                }
            }

            if viewModel.recentReceivedReviews.isEmpty {
                emptyStateCard("받은 후기가 없어요.")
            } else {
                ForEach(viewModel.recentReceivedReviews) { review in
                    OtherProfileReceivedReviewCard(
                        review: review,
                        onProfileTap: { openProfile(nickname: review.reviewerNickname) }
                    )
                }
            }
        }
    }

    private var receivedSummaryText: some View {
        let nickname = viewModel.displayNickname
        return HStack(spacing: 0) {
            Text("\(viewModel.boomUpCount)")
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey900"))
            Text("명의 부키메이트가 ")
                .pretendardText(size: 16, weight: .regular)
                .foregroundColor(Color("grey700"))
            Text(nickname)
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey900"))
            Text("님을 좋아합니다.")
                .pretendardText(size: 16, weight: .regular)
                .foregroundColor(Color("grey700"))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    // MARK: - Shared Components

    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .pretendardText(size: 16, weight: .semibold)
                .foregroundColor(Color("grey900"))
            Spacer()
        }
    }

    private func summaryCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func emptyStateCard(_ message: String) -> some View {
        Text(message)
            .pretendardText(size: 16, weight: .regular)
            .foregroundColor(Color("grey600"))
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Book Spine

private struct OtherProfileBookSpine: View {
    let title: String
    let colorIndex: Int

    @State private var titleNaturalSize: CGSize = .zero

    private var textColor: Color {
        colorIndex.isMultiple(of: 2) ? Color("main200") : Color("sub200")
    }

    private var backgroundColor: Color {
        colorIndex.isMultiple(of: 2) ? Color("main105") : Color("sub100")
    }

    private var spineWidth: CGFloat {
        max(titleNaturalSize.height + 12, 28)
    }

    private var spineHeight: CGFloat {
        max(titleNaturalSize.width + 32, 96)
    }

    var body: some View {
        ZStack(alignment: .top) {
            ZStack {
                Text(title)
                    .pretendardText(size: 15, weight: .medium)
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .fixedSize()
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(key: OtherProfileSpineTextSizeKey.self, value: geo.size)
                        }
                    )
                    .rotationEffect(.degrees(90))
            }
            .frame(width: spineWidth, height: spineHeight)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            OtherProfileBookSpineTopCap(color: backgroundColor, width: spineWidth)
                .offset(y: -OtherProfileBookSpineTopCap.capHeight / 2)
        }
        .padding(.top, OtherProfileBookSpineTopCap.capHeight / 2)
        .onPreferenceChange(OtherProfileSpineTextSizeKey.self) { titleNaturalSize = $0 }
    }
}

private struct OtherProfileBookSpineTopCap: View {
    static let capHeight: CGFloat = 13

    let color: Color
    let width: CGFloat

    var body: some View {
        Ellipse()
            .fill(color)
            .frame(width: width, height: Self.capHeight)
    }
}

private struct OtherProfileSpineTextSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - Review Cards

private struct OtherProfileWrittenReviewCard: View {
    let review: MypageBookReview

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(review.bookTitle)
                            .pretendardText(size: 16, weight: .semibold)
                            .foregroundColor(Color("grey900"))
                            .lineLimit(1)

                        Rectangle()
                            .fill(Color("grey200"))
                            .frame(width: 1, height: 15)

                        Text(review.bookAuthor)
                            .pretendardText(size: 16, weight: .semibold)
                            .foregroundColor(Color("grey900"))
                            .lineLimit(1)
                    }

                    OtherProfileStarRatingView(rating: review.rating)
                }

                Spacer(minLength: 8)

                OtherProfileTradeTypeChip(tradeType: review.tradeType)
            }
            .padding(.bottom, 16)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color("grey200")).frame(height: 1)
            }

            Text(review.comment)
                .pretendardText(size: 16, weight: .regular)
                .foregroundColor(Color("grey700"))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(review.reviewDate)
                .pretendardText(size: 14, weight: .regular)
                .foregroundColor(Color("grey500"))
        }
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct OtherProfileReceivedReviewCard: View {
    let review: MypageReceivedReview
    let onProfileTap: () -> Void

    private var isBoomUp: Bool {
        review.reaction.uppercased() == "BOOM_UP"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Button(action: onProfileTap) {
                    HStack(spacing: 8) {
                        ProfilePlaceholder(imageUrl: review.reviewerProfileUrl, size: 32)

                        Text(review.reviewerNickname)
                            .pretendardText(size: 16, weight: .medium)
                            .foregroundColor(Color("grey800"))
                    }
                }
                .buttonStyle(.plain)

                Spacer(minLength: 8)

                OtherProfileReactionChip(isBoomUp: isBoomUp)
            }

            Text(review.comment)
                .pretendardText(size: 16, weight: .regular)
                .foregroundColor(Color("grey700"))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(review.createdAt)
                .pretendardText(size: 14, weight: .regular)
                .foregroundColor(Color("grey500"))
        }
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct OtherProfileTradeTypeChip: View {
    let tradeType: String

    private var isDelivery: Bool { tradeType.uppercased() == "DELIVERY" }

    var body: some View {
        Text(isDelivery ? "택배 교환" : "직접 교환")
            .pretendardText(size: 14, weight: .medium)
            .foregroundColor(isDelivery ? Color("main200") : Color("sub200"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isDelivery ? Color("main100") : Color("sub100"))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct OtherProfileReactionChip: View {
    let isBoomUp: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(isBoomUp ? "ic_hand_thumbs_up" : "ic_hand_thumbs_down")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)

            Text(isBoomUp ? "좋았어요" : "별로였어요")
                .pretendardText(size: 14, weight: .medium)
                .foregroundColor(isBoomUp ? Color("main200") : Color("grey500"))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isBoomUp ? Color("main100") : Color("white"))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isBoomUp ? Color("main105") : Color("grey200"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct OtherProfileStarRatingView: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { index in
                starImage(for: index)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(Color("sub200"))
            }
        }
    }

    private func starImage(for index: Int) -> Image {
        let threshold = Double(index)
        if rating >= threshold + 1 {
            return Image("ic_star_fill")
        } else if rating >= threshold + 0.5 {
            return Image("ic_star_fill")
        } else {
            return Image("ic_star")
        }
    }
}
