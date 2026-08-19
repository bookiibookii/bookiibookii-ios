import SwiftUI

struct LibraryCardDetailView: View {
    private enum ImageLayout {
        case overlay
        case split
    }

    private enum TextTheme {
        case t1
        case t2
    }

    private struct FlyingReaction: Identifiable {
        let id = UUID()
        let reaction: LibraryCardReaction
        let xOffset: CGFloat
        var yOffset: CGFloat = 0
        var opacity: Double = 1
    }

    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: LibraryCardDetailViewModel
    @State private var imageLayout: ImageLayout = .overlay
    @State private var textTheme: TextTheme = .t1
    @State private var flyingReactions: [FlyingReaction] = []
    @State private var isActionMenuPresented = false
    @State private var showsDeleteConfirm = false
    @State private var isShareSheetPresented = false
    @AppStorage("coach_mark.library_card_detail.v1.completed")
    private var hasCompletedCoachMark = false
    @State private var isCoachMarkPresented = false
    @State private var coachMarkTargetFrames: [CoachMarkTarget: CGRect] = [:]

    private let showsMoreActions: Bool

    /// 안드로이드와 동일: PHOTO overlay→OVERLAY / split→SPLIT, TEXT t1→SPLIT / t2→OVERLAY
    private var currentShareLayout: String {
        guard let detail = viewModel.detail else { return "OVERLAY" }
        switch detail.cardType {
        case .image:
            return imageLayout == .overlay ? "OVERLAY" : "SPLIT"
        case .text:
            return textTheme == .t1 ? "SPLIT" : "OVERLAY"
        }
    }

    init(
        cardId: Int,
        userBookId: Int?,
        showsMoreActions: Bool = true,
        libraryService: LibraryService
    ) {
        self.showsMoreActions = showsMoreActions
        _viewModel = StateObject(
            wrappedValue: LibraryCardDetailViewModel(cardId: cardId, libraryService: libraryService)
        )
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color("uiBg").ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let detail = viewModel.detail {
                    detailContent(detail)
                } else {
                    Text("독서카드를 불러오지 못했어요.")
                        .pretendardText(size: 16)
                        .foregroundColor(Color("grey600"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            if isActionMenuPresented {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isActionMenuPresented = false
                    }

                cardActionMenu
                    .padding(.top, 68)
                    .padding(.trailing, 16)
            }

            if isShareSheetPresented, let detail = viewModel.detail {
                LibraryCardShareSheet(
                    detail: detail,
                    shareLayout: currentShareLayout,
                    libraryService: container.api.library,
                    onClose: { isShareSheetPresented = false }
                )
                .transition(.opacity)
                .zIndex(2)
            }

            if isCoachMarkPresented {
                CoachMarkOverlay(
                    kind: .libraryCardDetail,
                    targetFrames: coachMarkTargetFrames
                ) {
                    hasCompletedCoachMark = true
                    withAnimation(.easeOut(duration: 0.2)) {
                        isCoachMarkPresented = false
                    }
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .coordinateSpace(name: CoachMarkCoordinateSpace.libraryCardDetail)
        .onPreferenceChange(CoachMarkFramePreferenceKey.self) { frames in
            coachMarkTargetFrames = frames
        }
        .task {
            await viewModel.load()
            guard !hasCompletedCoachMark, viewModel.detail != nil else { return }

            // 데이터가 렌더된 뒤에 표시해야 첫 페이지가 카드 액션 위치를 안내한다.
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            isCoachMarkPresented = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .libraryCardMutationFinished)) { _ in
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
        .alert("독서카드 숨기기", isPresented: $showsDeleteConfirm) {
            Button("취소", role: .cancel) {}
            Button("숨기기", role: .destructive) {
                Task {
                    if await viewModel.deleteCard() {
                        container.navigationRouter.pop()
                    }
                }
            }
        } message: {
            Text("이 독서카드를 숨길까요?\n내 화면에서만 보이지 않아요.")
        }
    }

    private func requestHideCard() {
        guard let detail = viewModel.detail else { return }
        if detail.isBookmarked {
            viewModel.toastMessage = "북마크된 독서카드는 삭제할 수 없어요."
            return
        }
        showsDeleteConfirm = true
    }

    private var header: some View {
        HStack(spacing: 0) {
            HStack {
                Button {
                    container.navigationRouter.pop()
                } label: {
                    Image("ic_back")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
            }
            .frame(width: 88)

            Spacer(minLength: 0)

            Text("독서카드")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                if !showsMoreActions {
                    Color.clear
                        .frame(width: 40, height: 40)
                }

                Button {
                    guard viewModel.detail != nil else { return }
                    isActionMenuPresented = false
                    isShareSheetPresented = true
                } label: {
                    Image("ic_share")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.detail == nil)
                .coachMarkTargetFrame(
                    .libraryShare,
                    in: CoachMarkCoordinateSpace.libraryCardDetail
                )

                if showsMoreActions, let detail = viewModel.detail {
                    if detail.isMine {
                        Button {
                            isActionMenuPresented.toggle()
                        } label: {
                            Image("ic_meetball")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .frame(width: 40, height: 40)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            requestHideCard()
                        } label: {
                            Image("ic_trash")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .frame(width: 40, height: 40)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(width: 88)
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color("grey200"))
                .frame(height: 1)
        }
    }

    private var cardActionMenu: some View {
        VStack(spacing: 0) {
            cardActionMenuItem(
                title: "수정하기",
                iconName: "ic_pencil",
                action: openEditCard
            )

            cardActionMenuItem(
                title: "삭제하기",
                iconName: "ic_trash",
                action: {
                    isActionMenuPresented = false
                    requestHideCard()
                }
            )
        }
        .frame(width: 160)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color("grey200"), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 4)
    }

    private func cardActionMenuItem(
        title: String,
        iconName: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .pretendardText(size: 14, weight: .medium)
                    .foregroundColor(Color("grey700"))

                Spacer()

                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func openEditCard() {
        guard let detail = viewModel.detail,
              let userBookId = detail.memberBookId else {
            viewModel.toastMessage = "독서카드를 수정할 수 없어요."
            return
        }

        isActionMenuPresented = false
        container.navigationRouter.push(
            to: .libraryCardEdit(
                cardId: detail.cardId,
                userBookId: userBookId,
                bookTitle: detail.bookTitle ?? "-",
                cardType: detail.cardType,
                totalPages: detail.totalPages
            )
        )
    }

    private func detailContent(_ detail: LibraryCardDetail) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                metadataSection(detail)

                cardWithReactionAnimation(detail)

                if detail.cardType == .image {
                    imageLayoutButtons
                        .frame(maxWidth: .infinity)
                } else {
                    textThemeButtons
                        .frame(maxWidth: .infinity)
                }

                reactionButtons(detail)
            }
            .padding(.bottom, 48)
        }
    }

    private func metadataSection(_ detail: LibraryCardDetail) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                GeometryReader { proxy in
                    let ratio = min(
                        max(CGFloat(detail.page) / CGFloat(max(detail.totalPages ?? detail.page, 1)), 0),
                        1
                    )

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color("grey200"))
                            .frame(height: 10)
                        Capsule()
                            .fill(Color("main200"))
                            .frame(width: max(10, proxy.size.width * ratio), height: 10)
                    }
                }
                .frame(height: 10)

                Text(detail.cardType == .text ? "| 최신순" : "| 페이지순")
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey700"))
            }

            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    CardCreatorProfileImage(urlString: detail.creatorProfileImageURL)

                    Text(detail.creatorName)
                        .pretendardText(size: 16, weight: .medium)
                        .foregroundColor(Color("grey800"))

                    Spacer()

                    Button {
                        Task { await viewModel.toggleBookmark() }
                    } label: {
                        Image("ic_bookmark_fill")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(
                                detail.isBookmarked ? Color("main200") : Color("grey300")
                            )
                            .frame(width: 24, height: 24)
                            .frame(width: 32, height: 32)
                            .background(
                                detail.isBookmarked ? Color("main100") : Color("grey100")
                            )
                            .clipShape(Circle())
                            .overlay {
                                Circle()
                                    .stroke(
                                        detail.isBookmarked ? Color("main200") : Color("grey200"),
                                        lineWidth: 0.5
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                    .coachMarkTargetFrame(
                        .libraryBookmark,
                        in: CoachMarkCoordinateSpace.libraryCardDetail
                    )
                }

                HStack(spacing: 8) {
                    Text(detail.bookTitle ?? "-")
                        .pretendardText(size: 16, weight: .semibold)
                        .foregroundColor(Color("grey800"))
                        .lineLimit(1)

                    Text("p.\(detail.page)")
                        .pretendardText(size: 16)
                        .foregroundColor(Color("grey700"))

                    Spacer(minLength: 8)

                    Text(formatDate(detail.createdAt))
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey500"))
                }
            }
        }
        .padding(16)
        .background(Color("white"))
    }

    private func cardWithReactionAnimation(_ detail: LibraryCardDetail) -> some View {
        ZStack {
            if detail.cardType == .image {
                imageCard(detail)
            } else {
                textCard(detail)
            }

            GeometryReader { proxy in
                ForEach(flyingReactions) { item in
                    Image(item.reaction.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .position(
                            x: proxy.size.width - 68 + item.xOffset,
                            y: proxy.size.height - 32
                        )
                        .offset(y: item.yOffset)
                        .opacity(item.opacity)
                }
            }
            .allowsHitTesting(false)
            .padding(.horizontal, 16)
        }
        .frame(height: 464)
    }

    @ViewBuilder
    private func imageCard(_ detail: LibraryCardDetail) -> some View {
        switch imageLayout {
        case .overlay:
            ZStack(alignment: .topLeading) {
                CardDetailRemoteImage(urlString: detail.imageURL)

                CardDetailRemoteImage(urlString: detail.imageURL)
                    .blur(radius: 6)
                    .mask {
                        LinearGradient(
                            colors: [.black, .black.opacity(0.25), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    }

                LinearGradient(
                    stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white.opacity(0.9), location: 0.16),
                        .init(color: .clear, location: 0.48)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Text(detail.memo)
                    .pretendardText(size: 16)
                    .foregroundColor(Color("grey800"))
                    .lineLimit(5)
                    .padding(20)
            }
            .frame(height: 464)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.1), radius: 10)
            .padding(.horizontal, 16)

        case .split:
            VStack(spacing: 0) {
                CardDetailRemoteImage(urlString: detail.imageURL)
                    .frame(height: 336)

                Text(detail.memo)
                    .pretendardText(size: 16)
                    .foregroundColor(Color("grey800"))
                    .lineLimit(5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(20)
                    .background(Color("white"))
            }
            .frame(height: 464)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.1), radius: 10)
            .padding(.horizontal, 16)
        }
    }

    private var imageLayoutButtons: some View {
        HStack(spacing: 12) {
            cardLayoutOptionButton(
                imageName: "ic_overlay",
                isSelected: imageLayout == .overlay,
                action: { imageLayout = .overlay }
            )
            cardLayoutOptionButton(
                imageName: "ic_split",
                isSelected: imageLayout == .split,
                action: { imageLayout = .split }
            )
        }
        .padding(.vertical, 10)
    }

    private var textThemeButtons: some View {
        HStack(spacing: 12) {
            cardLayoutOptionButton(
                imageName: "ic_t1",
                isSelected: textTheme == .t1,
                action: { textTheme = .t1 }
            )
            cardLayoutOptionButton(
                imageName: "ic_t2",
                isSelected: textTheme == .t2,
                action: { textTheme = .t2 }
            )
        }
        .padding(.vertical, 10)
    }

    /// Figma·안드로이드 `CardVersionDot`과 동일: 32pt 미리보기 + 선택 링(진한/연한 테두리), 46pt 터치 영역.
    private func cardLayoutOptionButton(
        imageName: String,
        isSelected: Bool,
        action: () -> Void
    ) -> some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .overlay {
                    Circle()
                        .strokeBorder(
                            isSelected
                                ? Color.black.opacity(0.6)
                                : Color("grey200").opacity(0.4),
                            lineWidth: 2
                        )
                }
                .frame(width: 46, height: 46)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func textCard(_ detail: LibraryCardDetail) -> some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                textGradient

                VStack(alignment: .leading, spacing: 8) {
                    textBookTitleChip(title: detail.bookTitle ?? "")

                    Image("ic_quote")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(textTheme == .t1 ? Color("main100") : .white.opacity(0.85))
                        .frame(width: 28, height: 28)
                        .padding(.top, 4)

                    Text(displayQuotation(detail.quotation ?? detail.memo))
                        .font(.custom("MaruBuri-Bold", size: 20))
                        .foregroundColor(textTheme == .t1 ? Color("main200") : .white)
                        .lineSpacing(8)
                        .lineLimit(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(20)
            }
            .frame(height: 336)

            Text(detail.memo)
                .pretendardText(size: 16)
                .foregroundColor(Color("grey800"))
                .lineLimit(5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(20)
                .background(Color("white"))
        }
        .frame(height: 464)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.1), radius: 10)
        .padding(.horizontal, 16)
    }

    private func textBookTitleChip(title: String) -> some View {
        HStack(spacing: 8) {
            Image("ic_logo_symbol")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
                .frame(width: 16, height: 16)

            Text(title)
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(textTheme == .t1 ? Color("main200") : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            if textTheme == .t2 {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color("main100"), lineWidth: 1)
            }
        }
    }

    private func displayQuotation(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("“") || trimmed.hasPrefix("\"") || trimmed.hasPrefix("「") {
            return trimmed
        }
        return "“\(trimmed)”"
    }

    private var textGradient: LinearGradient {
        switch textTheme {
        case .t1:
            return LinearGradient(
                colors: [Color("white"), Color("main105")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .t2:
            return LinearGradient(
                colors: [
                    Color(red: 1, green: 0.31, blue: 0.09),
                    Color("main200"),
                    Color("main100")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func reactionButtons(_ detail: LibraryCardDetail) -> some View {
        HStack(spacing: 16) {
            ForEach(LibraryCardReaction.allCases) { reaction in
                reactionButton(
                    reaction,
                    active: detail.activeReactions.contains(reaction)
                )
            }
        }
        .padding(.horizontal, 16)
    }

    private func reactionButton(
        _ reaction: LibraryCardReaction,
        active: Bool
    ) -> some View {
        Button {
            Task {
                if await viewModel.toggleReaction(reaction) == true {
                    playReactionAnimation(reaction)
                }
            }
        } label: {
            VStack(spacing: 8) {
                Image(reaction.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .frame(maxWidth: .infinity)
                    .frame(height: 63)
                    .background(Color("white"))
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(active ? Color("main200") : Color.clear, lineWidth: 2)
                    }

                Text(reaction.title)
                    .pretendardText(size: 14, weight: .medium)
                    .foregroundColor(active ? Color("main200") : Color("grey800"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func playReactionAnimation(_ reaction: LibraryCardReaction) {
        let offsets: [CGFloat] = [-40, 0, -40, 0]

        for index in offsets.indices {
            let item = FlyingReaction(
                reaction: reaction,
                xOffset: offsets[index]
            )
            flyingReactions.append(item)

            let delay = Double(index) * 0.13
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.9).delay(delay)) {
                    guard let itemIndex = flyingReactions.firstIndex(where: { $0.id == item.id }) else {
                        return
                    }
                    flyingReactions[itemIndex].yOffset = -CGFloat(105 + index * 55)
                    flyingReactions[itemIndex].opacity = 0
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 1) {
                flyingReactions.removeAll { $0.id == item.id }
            }
        }
    }

    private func formatDate(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "-" }

        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = parser.date(from: value) ?? {
            parser.formatOptions = [.withInternetDateTime]
            return parser.date(from: value)
        }()

        guard let date else {
            return String(value.prefix(10)).replacingOccurrences(of: "-", with: ". ") + "."
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy. MM. dd."
        return formatter.string(from: date)
    }
}

private struct CardCreatorProfileImage: View {
    let urlString: String?

    var body: some View {
        ProfilePlaceholder(imageUrl: urlString, size: 32)
    }
}

private struct CardDetailRemoteImage: View {
    let urlString: String?

    var body: some View {
        AsyncImage(url: URL(string: urlString ?? "")) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                Color("grey200")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}

extension Notification.Name {
    static let libraryCardMutationFinished = Notification.Name("libraryCardMutationFinished")
    static let libraryCardEngagementChanged = Notification.Name("libraryCardEngagementChanged")
    static let libraryGroupReviewUpdated = Notification.Name("libraryGroupReviewUpdated")
}
