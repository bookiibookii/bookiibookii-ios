import SwiftUI

struct LibraryCardListView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: LibraryCardListViewModel
    @State private var showTogetherFinishDialog = false
    @State private var isTogetherCommentsExpanded = false

    let book: LibraryBook

    private var isTogetherBook: Bool {
        (book.groupType ?? "").uppercased() == "TOGETHER"
    }

    init(
        book: LibraryBook,
        libraryService: LibraryService,
        groupService: GroupService,
        trackerService: TrackerService
    ) {
        self.book = book
        _viewModel = StateObject(
            wrappedValue: LibraryCardListViewModel(
                book: book,
                libraryService: libraryService,
                groupService: groupService,
                trackerService: trackerService
            )
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        groupInfoCard
                        if viewModel.isLoading {
                            ProgressView().padding(.top, 40)
                        } else if viewModel.cards.isEmpty {
                            emptyCard
                        } else {
                            listHeader
                            cardsGrid
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, viewModel.cards.isEmpty ? 24 : 112)
                }
            }

            if !viewModel.cards.isEmpty && !viewModel.shouldShowTogetherReviewSummary {
                addCardButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }

            if showTogetherFinishDialog {
                TogetherFinishReadingDialog(
                    onDismiss: { showTogetherFinishDialog = false },
                    onConfirmFinish: {
                        showTogetherFinishDialog = false
                        Task { await viewModel.confirmTogetherReadingFinished() }
                    }
                )
            }
        }
        .task { await viewModel.load() }
        .onAppear {
            Task { await viewModel.load() }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .alert("안내", isPresented: Binding(
            get: { viewModel.toastMessage != nil },
            set: { if !$0 { viewModel.toastMessage = nil } }
        )) {
            Button("확인", role: .cancel) { viewModel.toastMessage = nil }
        } message: {
            Text(viewModel.toastMessage ?? "")
        }
    }

    private var header: some View {
        HStack {
            Button {
                container.navigationRouter.pop()
            } label: {
                Image("ic_back")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("grey900"))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            Spacer()
            Text(book.title)
                .font(.pretendard(size: 20, weight: .medium))
                .foregroundColor(Color("grey900"))
                .lineLimit(1)
            Spacer()

            HeaderCircleButton(systemName: "ellipsis")
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Divider().overlay(Color("grey200"))
        }
    }

    private var groupInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Color("grey300")
                    .frame(width: 92, height: 118)
                    .overlay(
                        AsyncImage(url: URL(string: book.coverImageURL ?? "")) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            case .empty, .failure:
                                EmptyView()
                            @unknown default:
                                EmptyView()
                            }
                        }
                    )
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle().fill(Color("grey300")).frame(width: 20, height: 20)
                        Text(book.hostNickname)
                            .font(.pretendard(size: 12, weight: .medium))
                            .foregroundColor(Color("grey700"))
                    }
                    Text(book.title)
                        .font(.pretendard(size: 14, weight: .regular))
                        .foregroundColor(Color("grey900"))
                    HStack(spacing: 4) {
                        Text(book.author ?? "-")
                            .font(.pretendard(size: 12, weight: .regular))
                            .foregroundColor(Color("grey500"))
                        Text("(소설)")
                            .font(.pretendard(size: 11, weight: .regular))
                            .foregroundColor(Color("grey500"))
                    }
                    StarRow(rating: viewModel.refreshedBookRating ?? book.rating ?? 0)
                    Text(periodLineUnderTitle)
                        .font(.pretendard(size: 11, weight: .regular))
                        .foregroundColor(Color("grey400"))
                }
            }

            Divider().overlay(Color("grey100"))

            if isTogetherBook {
                if viewModel.shouldShowTogetherReviewSummary {
                    togetherReviewSummarySection
                } else {
                    togetherReadingSection
                }
            } else {
                relayCommentsSection
            }
        }
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var periodLineUnderTitle: String {
        if isTogetherBook {
            let start = formatDateYMD(book.startDate)
            guard let iso = viewModel.togetherReadingCompletedAtISO, !iso.isEmpty else {
                return start
            }
            return "\(start) ~ \(formatDateYMD(iso))"
        }
        return "\(formatDate(book.startDate)) ~ \(formatDate(book.endDate))"
    }

    private var relayCommentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(viewModel.topComments) { comment in
                HStack(spacing: 8) {
                    Text(comment.nickname)
                        .font(.pretendard(size: 11, weight: .regular))
                        .foregroundColor(Color("grey600"))
                    Text("\"\(comment.comment)\"")
                        .font(.pretendard(size: 11, weight: .regular))
                        .foregroundColor(Color("grey800"))
                        .lineLimit(1)
                }
            }
        }
    }

    private var togetherReadingSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            TrackerReadingRateBar(
                myReadingRate: viewModel.togetherMyReadingRate ?? 0,
                groupReadingRate: viewModel.togetherGroupReadingRate ?? 0
            )
            .padding(.top, 4)

            Button {
                if viewModel.togetherShowsReviewButton {
                    navigateToTogetherReviewIfPossible()
                    return
                }
                showTogetherFinishDialog = true
            } label: {
                Text(viewModel.togetherShowsReviewButton ? "후기 작성하기" : "다 읽었어요")
                    .font(.pretendard(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color("grey900"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
        }
    }

    private var togetherReviewSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let first = primaryTogetherComment {
                togetherCommentRow(first)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isTogetherCommentsExpanded.toggle()
                }
            } label: {
                Image("ic_chevron")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .rotationEffect(.degrees(isTogetherCommentsExpanded ? 180 : 0))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            if isTogetherCommentsExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(expandedTogetherComments) { comment in
                        togetherCommentRow(comment)
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    private var primaryTogetherComment: LibraryTopComment? {
        if let uid = TokenManager.shared.userId {
            return viewModel.togetherComments.first(where: { $0.id == String(uid) })
        }
        return viewModel.togetherComments.first
    }

    private var expandedTogetherComments: [LibraryTopComment] {
        guard let primary = primaryTogetherComment else { return viewModel.togetherComments }
        return viewModel.togetherComments.filter { $0.id != primary.id }
    }

    private func togetherCommentRow(_ comment: LibraryTopComment) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(comment.nickname)
                .font(.pretendard(size: 11, weight: .regular))
                .foregroundColor(Color("grey600"))
            Text("\"\(comment.comment)\"")
                .font(.pretendard(size: 11, weight: .regular))
                .foregroundColor(Color("grey800"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var listHeader: some View {
        HStack {
            Text(viewModel.cardCountText)
                .font(.pretendard(size: 14, weight: .regular))
                .foregroundColor(Color("grey700"))
            Spacer()
            HStack(spacing: 4) {
                sortButton(title: "최신순", selected: viewModel.sortType == .latest) {
                    viewModel.sortType = .latest
                }
                Text("|")
                    .font(.pretendard(size: 14, weight: .regular))
                    .foregroundColor(Color("grey500"))
                sortButton(title: "페이지순", selected: viewModel.sortType == .page) {
                    viewModel.sortType = .page
                }
            }
        }
    }

    private var cardsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(viewModel.sortedCards) { card in
                LibraryReadingCardItem(
                    card: card,
                    onToggleBookmark: {
                        Task { await viewModel.toggleBookmark(cardId: card.id) }
                    },
                    onTap: {
                        guard card.isBookmarkable else { return }
                        container.navigationRouter.push(to: .libraryCardDetail(cardId: card.id, userBookId: book.userBookId))
                    }
                )
                .id("\(card.id)-\(card.isBookmarked)")
            }
        }
    }

    private var emptyCard: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("아직 독서카드가 없어요")
                    .font(.pretendard(size: 16, weight: .medium))
                    .foregroundColor(Color("grey900"))
                Text("마음에 드는 내용을 기록으로 남겨요.")
                    .font(.pretendard(size: 14, weight: .regular))
                    .foregroundColor(Color("grey600"))
            }

            Button("독서카드 추가하기") {
                navigateToCardAddIfPossible()
            }
                .font(.pretendard(size: 15, weight: .regular))
                .foregroundColor(Color("main200"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color("main100"))
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var addCardButton: some View {
        Button("독서카드 추가하기") {
            navigateToCardAddIfPossible()
        }
            .font(.pretendard(size: 18, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(Color("grey900"))
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func navigateToCardAddIfPossible() {
        guard let uid = book.userBookId else { return }
        container.navigationRouter.push(to: .libraryCardAdd(userBookId: uid))
    }

    private func navigateToTogetherReviewIfPossible() {
        guard let userBookId = book.userBookId else {
            viewModel.toastMessage = "후기를 작성할 수 없습니다."
            return
        }
        container.navigationRouter.push(to: .togetherReview(userBookId: userBookId, bookTitle: book.title))
    }

    private func sortButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.pretendard(size: 14, weight: selected ? .medium : .regular))
                .foregroundColor(selected ? Color("grey700") : Color("grey500"))
        }
        .buttonStyle(.plain)
    }

    private func formatDate(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "-" }
        return value.replacingOccurrences(of: "-", with: ". ") + "."
    }

    /// `yyyy-MM-dd` 또는 ISO8601 앞부분만 사용해 `yyyy. MM. dd.` 형태로 표시합니다.
    private func formatDateYMD(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "-" }
        let dateOnly = String(value.prefix { $0 != "T" && $0 != " " })
        return dateOnly.replacingOccurrences(of: "-", with: ". ") + "."
    }
}

private struct TogetherFinishReadingDialog: View {
    let onDismiss: () -> Void
    let onConfirmFinish: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(alignment: .leading, spacing: 16) {
                Text("독서 종료")
                    .font(.pretendard(size: 20, weight: .medium))
                    .foregroundColor(Color("grey900"))

                Text("독서를 종료하면 더 이상 독서카드를 추가할 수 없어요. 독서를 종료할까요?")
                    .font(.pretendard(size: 16, weight: .regular))
                    .foregroundColor(Color("grey700"))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Button("취소", action: onDismiss)
                        .font(.pretendard(size: 15, weight: .medium))
                        .foregroundColor(Color("grey700"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color("grey100"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    Button("종료", action: onConfirmFinish)
                        .font(.pretendard(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color("grey900"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top, 8)
            }
            .padding(24)
            .frame(maxWidth: 340)
            .background(Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 32)
        }
    }
}

private struct HeaderCircleButton: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(Color("grey700"))
            .frame(width: 40, height: 40)
    }
}

private struct StarRow: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...5, id: \.self) { idx in
                Image(systemName: symbolName(for: idx))
                    .font(.system(size: 10))
                    .foregroundColor(Color("main100"))
            }
        }
    }

    private func symbolName(for idx: Int) -> String {
        if rating >= Double(idx) { return "star.fill" }
        if rating >= Double(idx) - 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }
}

#Preview {
    LibraryCardListView(
        book: LibraryBook(
            id: 1,
            userBookId: 1,
            groupId: 1,
            groupType: nil,
            title: "괴테는 모든 것을 말했다",
            author: "스즈키 유이",
            coverImageURL: nil,
            hostNickname: "noshel",
            startDate: "2025-12-18",
            endDate: "2026-01-12",
            status: .completed,
            rating: 3.5,
            isCreatedByMe: true,
            togetherMyReadingRate: nil,
            togetherGroupReadingRate: nil,
            togetherReadingCompletedAtISO: nil
        ),
        libraryService: LibraryService(interceptor: AuthInterceptor(authService: AuthService())),
        groupService: GroupService(interceptor: AuthInterceptor(authService: AuthService())),
        trackerService: TrackerService(interceptor: AuthInterceptor(authService: AuthService()))
    )
    .environmentObject(DIContainer())
}
