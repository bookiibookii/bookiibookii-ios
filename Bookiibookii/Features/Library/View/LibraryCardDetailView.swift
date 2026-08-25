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
    @State private var scrolledCardID: Int?
    @AppStorage("coach_mark.library_card_detail.v1.completed")
    private var hasCompletedCoachMark = false
    @State private var isCoachMarkPresented = false
    @State private var coachMarkTargetFrames: [CoachMarkTarget: CGRect] = [:]

    private let showsMoreActions: Bool

    /// Figma LIB-03: 카드 348×464, 좌측 16·우측 peek로 다음 카드 노출.
    /// 안드로이드 HorizontalPager contentPadding(32)과 동일하게 양옆 32.
    private static let carouselHorizontalInset: CGFloat = 32
    private static let carouselSpacing: CGFloat = 16
    private static let cardDesignWidth: CGFloat = 348
    private static let cardDesignHeight: CGFloat = 464
    private static let cardAspectRatio: CGFloat = cardDesignWidth / cardDesignHeight
    private static let splitTopRatio: CGFloat = 336 / 464
    private static let splitBottomRatio: CGFloat = 128 / 464

    @State private var carouselViewportWidth: CGFloat = 0

    private var cardWidth: CGFloat {
        let width = carouselViewportWidth > 0
            ? carouselViewportWidth
            : UIScreen.main.bounds.width
        return max(0, width - Self.carouselHorizontalInset * 2)
    }

    private var cardHeight: CGFloat {
        cardWidth / Self.cardAspectRatio
    }

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
        cards: [LibraryCard],
        initialIndex: Int,
        sortLabel: String,
        showsMoreActions: Bool = true,
        libraryService: LibraryService
    ) {
        self.showsMoreActions = showsMoreActions
        _viewModel = StateObject(
            wrappedValue: LibraryCardDetailViewModel(
                cards: cards,
                initialIndex: initialIndex,
                sortLabel: sortLabel,
                libraryService: libraryService
            )
        )
        let safeIndex = cards.isEmpty
            ? nil
            : cards[min(max(0, initialIndex), cards.count - 1)].id
        _scrolledCardID = State(initialValue: safeIndex)
    }

    init(cardId: Int, libraryService: LibraryService) {
        self.showsMoreActions = true
        _viewModel = StateObject(
            wrappedValue: LibraryCardDetailViewModel(
                cardId: cardId,
                libraryService: libraryService
            )
        )
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color("uiBg").ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if viewModel.isLoading && viewModel.cards.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let card = viewModel.currentCard {
                    detailContent(card)
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
                    targetFrames: coachMarkTargetFrames,
                    onCompleted: {
                        hasCompletedCoachMark = true
                        withAnimation(.easeOut(duration: 0.2)) {
                            isCoachMarkPresented = false
                        }
                    }
                )
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
            if scrolledCardID == nil {
                scrolledCardID = viewModel.currentCard?.id
            }
            guard !hasCompletedCoachMark, viewModel.currentCard != nil else { return }

            // 데이터가 렌더된 뒤에 표시해야 첫 페이지가 카드 액션 위치를 안내한다.
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            isCoachMarkPresented = true
        }
        .onChange(of: scrolledCardID) { _, newID in
            guard let newID,
                  let index = viewModel.cards.firstIndex(where: { $0.id == newID }) else { return }
            guard index != viewModel.currentIndex else { return }
            viewModel.selectIndex(index)
            flyingReactions = []
            imageLayout = .overlay
            textTheme = .t1
            isActionMenuPresented = false
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

    private func detailContent(_ card: LibraryCard) -> some View {
        VStack(spacing: 0) {
            metadataSection(card)

            cardCarousel
                .padding(.top, 16)

            if card.cardType == .image {
                imageLayoutButtons
                    .frame(maxWidth: .infinity)
            } else {
                textThemeButtons
                    .frame(maxWidth: .infinity)
            }

            Spacer(minLength: 0)

            reactionButtons(card)
                .padding(.bottom, 20)
        }
    }

    private var cardCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: Self.carouselSpacing) {
                ForEach(viewModel.cards) { card in
                    cardPage(card)
                        .frame(width: cardWidth, height: cardHeight)
                        .id(card.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(.horizontal, Self.carouselHorizontalInset, for: .scrollContent)
        .scrollPosition(id: $scrolledCardID)
        .frame(height: cardHeight)
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: CardCarouselWidthKey.self, value: geo.size.width)
            }
        )
        .onPreferenceChange(CardCarouselWidthKey.self) { width in
            guard width > 0, abs(width - carouselViewportWidth) > 0.5 else { return }
            carouselViewportWidth = width
        }
    }

    private func cardPage(_ card: LibraryCard) -> some View {
        ZStack {
            if card.cardType == .image {
                imageCard(card.asDetail)
            } else {
                textCard(card.asDetail)
            }

            if card.id == viewModel.currentCard?.id {
                GeometryReader { proxy in
                    ForEach(flyingReactions) { item in
                        Image(item.reaction.iconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .position(
                                x: proxy.size.width - 52 + item.xOffset,
                                y: proxy.size.height - 32
                            )
                            .offset(y: item.yOffset)
                            .opacity(item.opacity)
                    }
                }
                .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func metadataSection(_ card: LibraryCard) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color("grey200"))
                            .frame(height: 10)
                        Capsule()
                            .fill(Color("main200"))
                            .frame(
                                width: max(10, proxy.size.width * viewModel.progress),
                                height: 10
                            )
                    }
                }
                .frame(height: 10)

                Text("| \(viewModel.sortLabel)")
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey700"))
            }

            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    CardCreatorProfileImage(urlString: card.creatorProfileImageURL)

                    Text(card.creatorName)
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
                                card.isBookmarked ? Color("main200") : Color("grey300")
                            )
                            .frame(width: 24, height: 24)
                            .frame(width: 32, height: 32)
                            .background(
                                card.isBookmarked ? Color("main100") : Color("grey100")
                            )
                            .clipShape(Circle())
                            .overlay {
                                Circle()
                                    .stroke(
                                        card.isBookmarked ? Color("main200") : Color("grey200"),
                                        lineWidth: 0.5
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(!card.isBookmarkable)
                    .coachMarkTargetFrame(
                        .libraryBookmark,
                        in: CoachMarkCoordinateSpace.libraryCardDetail
                    )
                }

                HStack(spacing: 8) {
                    Text(card.bookTitle ?? "-")
                        .pretendardText(size: 16, weight: .semibold)
                        .foregroundColor(Color("grey800"))
                        .lineLimit(1)

                    Text("p.\(card.page)")
                        .pretendardText(size: 16)
                        .foregroundColor(Color("grey700"))

                    Spacer(minLength: 8)

                    Text(formatDate(card.createdAt))
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey500"))
                }
            }
        }
        .padding(16)
        .background(Color("white"))
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.1), radius: 10)

        case .split:
            GeometryReader { geo in
                VStack(spacing: 0) {
                    CardDetailRemoteImage(urlString: detail.imageURL)
                        .frame(height: geo.size.height * Self.splitTopRatio)

                    Text(detail.memo)
                        .pretendardText(size: 16)
                        .foregroundColor(Color("grey800"))
                        .lineLimit(5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(20)
                        .background(Color("white"))
                        .frame(height: geo.size.height * Self.splitBottomRatio)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.1), radius: 10)
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
        action: @escaping () -> Void
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
        GeometryReader { geo in
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
                .frame(height: geo.size.height * Self.splitTopRatio)

                ZStack(alignment: .topLeading) {
                    Color("white")

                    Text(detail.memo)
                        .pretendardText(size: 16)
                        .foregroundColor(Color("grey800"))
                        .lineLimit(5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(20)
                }
                .frame(height: geo.size.height * Self.splitBottomRatio)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.1), radius: 10)
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

    private func reactionButtons(_ card: LibraryCard) -> some View {
        HStack(spacing: 16) {
            ForEach(LibraryCardReaction.allCases) { reaction in
                reactionButton(
                    reaction,
                    active: card.activeReactions.contains(reaction)
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

private struct CardCarouselWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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
        // scaledToFill이 부모(348×464 카드) 밖으로 레이아웃을 밀어내지 않도록 컨테이너 고정
        Color("grey200")
            .overlay {
                AsyncImage(url: URL(string: urlString ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        EmptyView()
                    }
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
