import SwiftUI

struct MyReviewsView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: MyReviewsViewModel
    var onClose: (() -> Void)?

    init(userService: UserService, initialTab: MyReviewTab, nickname: String, profileNickname: String? = nil, onClose: (() -> Void)? = nil) {
        _viewModel = StateObject(
            wrappedValue: MyReviewsViewModel(
                userService: userService,
                initialTab: initialTab,
                nickname: nickname,
                profileNickname: profileNickname
            )
        )
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                header
                tabBar

                if viewModel.isLoading && currentReviewsEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 8) {
                            summaryCard

                            if currentReviewsEmpty {
                                emptyStateCard
                            } else {
                                reviewList
                            }

                            if viewModel.isLoadingMore {
                                ProgressView()
                                    .padding(.vertical, 16)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .task { await viewModel.load() }
        .alert("안내", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var currentReviewsEmpty: Bool {
        switch viewModel.selectedTab {
        case .written: return viewModel.writtenReviews.isEmpty
        case .received: return viewModel.receivedReviews.isEmpty
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                if let onClose {
                    onClose()
                } else {
                    container.navigationRouter.pop()
                }
            } label: {
                Image("ic_back")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("후기")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Divider().overlay(Color("grey200"))
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 8) {
            ForEach([MyReviewTab.written, .received], id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color("grey100"))
    }

    private func tabButton(_ tab: MyReviewTab) -> some View {
        let isSelected = viewModel.selectedTab == tab
        return Button {
            Task { await viewModel.selectTab(tab) }
        } label: {
            Text(tab.title)
                .pretendardText(size: 14, weight: .medium)
                .foregroundColor(isSelected ? Color("white") : Color("grey700"))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color("main200") : Color("white"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.clear : Color("grey200"), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Summary

    @ViewBuilder
    private var summaryCard: some View {
        switch viewModel.selectedTab {
        case .written:
            writtenSummaryCard
        case .received:
            receivedSummaryCard
        }
    }

    private var writtenSummaryCard: some View {
        HStack(spacing: 8) {
            Image("ic_book")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)

            HStack(spacing: 0) {
                Text("\(viewModel.writtenTotalCount)")
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey900"))
                Text("권의 책에 후기를 남겼어요.")
                    .pretendardText(size: 16, weight: .regular)
                    .foregroundColor(Color("grey700"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var receivedSummaryCard: some View {
        HStack(spacing: 8) {
            Image("ic_boomup")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)

            HStack(spacing: 0) {
                Text("\(viewModel.receivedPositiveCount)")
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey900"))
                Text("명의 파트너가 ")
                    .pretendardText(size: 16, weight: .regular)
                    .foregroundColor(Color("grey700"))
                Text(viewModel.nickname)
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey900"))
                Text("님을 좋아합니다.")
                    .pretendardText(size: 16, weight: .regular)
                    .foregroundColor(Color("grey700"))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - List

    @ViewBuilder
    private var reviewList: some View {
        switch viewModel.selectedTab {
        case .written:
            ForEach(viewModel.writtenReviews) { review in
                MyReviewsWrittenCard(review: review)
                    .onAppear {
                        Task { await viewModel.loadMoreIfNeeded(currentItemId: review.id) }
                    }
            }
        case .received:
            ForEach(viewModel.receivedReviews) { review in
                MyReviewsReceivedCard(
                    review: review,
                    onProfileTap: {
                        container.navigationRouter.push(to: .userProfile(nickname: review.reviewerNickname))
                    }
                )
                    .onAppear {
                        Task { await viewModel.loadMoreIfNeeded(currentItemId: review.id) }
                    }
            }
        }
    }

    private var emptyStateCard: some View {
        Text(viewModel.selectedTab == .written ? "작성한 후기가 없어요." : "받은 후기가 없어요.")
            .pretendardText(size: 16, weight: .regular)
            .foregroundColor(Color("grey600"))
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Written Card

private struct MyReviewsWrittenCard: View {
    let review: WrittenReviewItem

    private var tradeTypeLabel: String {
        if let label = review.exchangeTypeLabel, !label.isEmpty {
            return label
        }
        let type = review.exchangeType?.uppercased() ?? ""
        return type == "DELIVERY" ? "택배" : "직접"
    }

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

                        Text(review.author)
                            .pretendardText(size: 16, weight: .semibold)
                            .foregroundColor(Color("grey900"))
                            .lineLimit(1)
                    }

                    MyReviewsStarRating(rating: review.rating)
                }

                Spacer(minLength: 8)

                Text(tradeTypeLabel)
                    .pretendardText(size: 14, weight: .medium)
                    .foregroundColor(Color("grey700"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color("grey100"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.bottom, 16)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color("grey200")).frame(height: 1)
            }

            Text(review.content)
                .pretendardText(size: 16, weight: .regular)
                .foregroundColor(Color("grey700"))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(review.reviewedAt)
                .pretendardText(size: 14, weight: .regular)
                .foregroundColor(Color("grey500"))
        }
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Received Card

private struct MyReviewsReceivedCard: View {
    let review: ReceivedReviewItem
    let onProfileTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Button(action: onProfileTap) {
                    HStack(spacing: 8) {
                        ProfilePlaceholder(imageUrl: review.reviewerProfileImageUrl, size: 32)

                        Text(review.reviewerNickname)
                            .pretendardText(size: 16, weight: .medium)
                            .foregroundColor(Color("grey800"))
                    }
                }
                .buttonStyle(.plain)

                Spacer(minLength: 8)

                MyReviewsReactionChip(
                    isBoomUp: review.isBoomUp,
                    label: review.partnerReviewLabel
                )
            }

            Text(review.comment ?? "")
                .pretendardText(size: 16, weight: .regular)
                .foregroundColor(Color("grey700"))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(review.reviewedAt)
                .pretendardText(size: 14, weight: .regular)
                .foregroundColor(Color("grey500"))
        }
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Shared Components

private struct MyReviewsReactionChip: View {
    let isBoomUp: Bool
    let label: String?

    private var displayLabel: String {
        if let label, !label.isEmpty { return label }
        return isBoomUp ? "좋았어요" : "별로였어요"
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(isBoomUp ? "ic_hand_thumbs_up" : "ic_hand_thumbs_down")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(isBoomUp ? Color("main200") : Color("grey500"))

            Text(displayLabel)
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

private struct MyReviewsStarRating: View {
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
            return Image("ic_star_half")
        } else {
            return Image("ic_star")
        }
    }
}
