import SwiftUI
import Kingfisher

struct MyPageView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: MyPageViewModel
    @FocusState private var isIntroductionFocused: Bool
    @State private var isProfileSharePresented = false

    private let userService: UserService

    init(userService: UserService) {
        self.userService = userService
        _viewModel = StateObject(wrappedValue: MyPageViewModel(userService: userService))
    }

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

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

            if isProfileSharePresented {
                ProfileShareSheet(
                    nickname: viewModel.profile?.nickname ?? "",
                    introduction: viewModel.profile?.introduction ?? "",
                    profileImageURL: viewModel.profile?.profileImageUrl,
                    books: viewModel.userBooks,
                    userService: userService,
                    onClose: { isProfileSharePresented = false }
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .task { await viewModel.loadProfile() }
        .alert("안내", isPresented: Binding(
            get: { viewModel.introductionErrorMessage != nil },
            set: { if !$0 { viewModel.introductionErrorMessage = nil } }
        )) {
            Button("확인", role: .cancel) { viewModel.introductionErrorMessage = nil }
        } message: {
            Text(viewModel.introductionErrorMessage ?? "")
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Header

    private var topBar: some View {
        HStack {
            Button { container.navigationRouter.pop() } label: {
                Image("ic_back")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("마이페이지")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))

            Spacer()

            Button { container.navigationRouter.push(to: .setting) } label: {
                Image("ic_gear")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color("grey200")).frame(height: 1)
        }
    }

    // MARK: - Profile Card (프로필 + 한줄소개 + 나의 책장)

    private var profileCard: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                profileRow
                actionButtons
            }
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
            profileImage
                .frame(width: 52, height: 52)
                .clipShape(Circle())

            if viewModel.isLoading {
                ProgressView().scaleEffect(0.8)
            } else {
                Text(viewModel.profile?.nickname ?? "-")
                    .pretendardText(size: 20, weight: .semibold)
                    .foregroundColor(Color("grey900"))
            }

            Spacer(minLength: 0)
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
    }

    private var defaultProfileIcon: some View {
        Image("ic_profile_placeholder")
            .resizable()
            .scaledToFill()
    }

    private var actionButtons: some View {
        HStack(spacing: 4) {
            outlineButton("프로필 수정") {
                container.navigationRouter.push(to: .profileChange)
            }

            outlineButton("주소지 관리") {
                container.navigationRouter.push(to: .addressManagement(initialTab: .delivery))
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isProfileSharePresented = true
                }
            } label: {
                Image("ic_share")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .frame(width: 48, height: 48)
                    .background(Color("white"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("grey200"), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    private func outlineButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .pretendardText(size: 15, weight: .regular)
                .foregroundColor(Color("grey900"))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color("white"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("grey200"), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 한 줄 소개

    private var introductionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("한 줄 소개")
                    .pretendardText(size: 16, weight: .semibold)
                    .foregroundColor(Color("grey900"))
                Spacer()
                if !viewModel.isEditingIntroduction {
                    Button { viewModel.beginEditingIntroduction() } label: {
                        Text("수정")
                            .pretendardText(size: 11, weight: .medium)
                            .foregroundColor(Color("grey700"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("grey200"))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }

            if viewModel.isEditingIntroduction {
                introductionEditCard
            } else {
                introductionDisplayCard
            }
        }
    }

    private var introductionDisplayCard: some View {
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
                Text("한 줄 소개가 없어요")
                    .pretendardText(size: 15, weight: .regular)
                    .foregroundColor(Color("grey400"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("grey100"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var introductionEditCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .topLeading) {
                if viewModel.introductionDraft.isEmpty {
                    Text("한 줄 소개를 입력하세요...")
                        .pretendardText(size: 15, weight: .regular)
                        .foregroundColor(Color("grey500"))
                }

                TextField("", text: Binding(
                    get: { viewModel.introductionDraft },
                    set: { viewModel.updateIntroductionDraft($0) }
                ), axis: .vertical)
                .pretendardText(size: 15, weight: .regular)
                .foregroundColor(Color("grey900"))
                .tint(Color("main200"))
                .lineLimit(1...4)
                .focused($isIntroductionFocused)
            }
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)

            HStack(alignment: .bottom) {
                Text("\(viewModel.introductionDraft.count)/\(MyPageViewModel.introMaxLength)")
                    .pretendardText(size: 12, weight: .regular)
                    .foregroundColor(Color("grey500"))

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        viewModel.cancelEditingIntroduction()
                        isIntroductionFocused = false
                    } label: {
                        Text("취소")
                            .pretendardText(size: 15, weight: .regular)
                            .foregroundColor(Color("grey900"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color("white"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color("grey200"), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task {
                            await viewModel.saveIntroduction()
                            isIntroductionFocused = false
                        }
                    } label: {
                        Text("저장")
                            .pretendardText(size: 15, weight: .regular)
                            .foregroundColor(Color("white"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color("grey900"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isSavingIntroduction)
                    .opacity(viewModel.isSavingIntroduction ? 0.6 : 1)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("grey100"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear { isIntroductionFocused = true }
    }

    // MARK: - 나의 책장

    private var bookshelfSection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "나의 책장", showChevron: true) {
                container.navigationRouter.push(to: .myBookShelf)
            }

            if !viewModel.userBooks.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(Array(viewModel.userBooks.enumerated()), id: \.element.id) { index, book in
                            MypageBookSpine(title: book.title, colorIndex: index)
                        }
                    }
                    .padding(.top, 16)
                }
            }
        }
    }

    // MARK: - 작성한 후기

    private var writtenReviewsSection: some View {
        VStack(spacing: 8) {
            sectionHeader(title: "작성한 후기", showChevron: true) {
                let nickname = viewModel.profile?.nickname ?? ""
                container.navigationRouter.push(to: .myReviews(initialTab: .written, nickname: nickname))
            }

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
                    WrittenReviewCard(review: review)
                }
            }
        }
    }

    // MARK: - 받은 후기

    private var receivedReviewsSection: some View {
        VStack(spacing: 8) {
            sectionHeader(title: "받은 후기", showChevron: true) {
                let nickname = viewModel.profile?.nickname ?? ""
                container.navigationRouter.push(to: .myReviews(initialTab: .received, nickname: nickname))
            }

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
                    ReceivedReviewCard(
                        review: review,
                        onProfileTap: {
                            container.navigationRouter.push(to: .userProfile(nickname: review.reviewerNickname))
                        }
                    )
                }
            }
        }
    }

    private var receivedSummaryText: some View {
        let nickname = viewModel.profile?.nickname ?? ""
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

    private func sectionHeader(title: String, showChevron: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .pretendardText(size: 16, weight: .semibold)
                    .foregroundColor(Color("grey900"))
                Spacer()
                if showChevron {
                    Image("ic_chevron_r")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!showChevron)
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

private struct MypageBookSpine: View {
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
                            Color.clear.preference(key: SpineTextSizeKey.self, value: geo.size)
                        }
                    )
                    .rotationEffect(.degrees(90))
            }
            .frame(width: spineWidth, height: spineHeight)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            BookSpineTopCap(color: backgroundColor, width: spineWidth)
                .offset(y: -BookSpineTopCap.capHeight / 2)
        }
        .padding(.top, BookSpineTopCap.capHeight / 2)
        .onPreferenceChange(SpineTextSizeKey.self) { titleNaturalSize = $0 }
    }
}

private struct BookSpineTopCap: View {
    static let capHeight: CGFloat = 13

    let color: Color
    let width: CGFloat

    var body: some View {
        Ellipse()
            .fill(color)
            .frame(width: width, height: Self.capHeight)
    }
}

private struct SpineTextSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - Review Cards

private struct WrittenReviewCard: View {
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

                    StarRatingView(rating: review.rating)
                }

                Spacer(minLength: 8)

                TradeTypeChip(tradeType: review.tradeType)
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

private struct ReceivedReviewCard: View {
    let review: MypageReceivedReview
    var onProfileTap: (() -> Void)?

    private var isBoomUp: Bool {
        review.reaction.uppercased() == "BOOM_UP"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Group {
                    if let onProfileTap {
                        Button(action: onProfileTap) {
                            reviewerHeader
                        }
                        .buttonStyle(.plain)
                    } else {
                        reviewerHeader
                    }
                }

                Spacer(minLength: 8)

                ReactionChip(isBoomUp: isBoomUp)
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

    private var reviewerHeader: some View {
        HStack(spacing: 8) {
            reviewerProfileImage
                .frame(width: 32, height: 32)
                .clipShape(Circle())

            Text(review.reviewerNickname)
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey800"))
        }
    }

    @ViewBuilder
    private var reviewerProfileImage: some View {
        if let urlStr = review.reviewerProfileUrl,
           let url = URL(string: urlStr) {
            KFImage(url)
                .placeholder { Color("grey200") }
                .resizable()
                .scaledToFill()
        } else {
            Color("grey200")
        }
    }
}

private struct TradeTypeChip: View {
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

private struct ReactionChip: View {
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

private struct StarRatingView: View {
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

#Preview {
    MyPageView(
        userService: UserService(
            interceptor: AuthInterceptor(authService: AuthService())
        )
    )
    .environmentObject(DIContainer())
}
