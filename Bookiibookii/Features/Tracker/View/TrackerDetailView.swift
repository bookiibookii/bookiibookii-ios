import SwiftUI

// 트래커 상세(교환 현황) 순수 프레젠테이션. 상태/액션 배선은 TrackerDetailRoute(Task 4).
struct TrackerDetailScreen: View {
    let state: TrackerDetailUiState
    let onBack: () -> Void
    let onMessage: () -> Void
    let onEditPeriod: () -> Void
    let onGoToLibrary: () -> Void
    let onReport: () -> Void
    let onPrimaryAction: () -> Void
    let onSecondaryAction: () -> Void

    @State private var showMenu = false

    var body: some View {
        VStack(spacing: 0) {
            TrackerDetailHeader(
                showMenu: $showMenu,
                onBack: onBack, onMessage: onMessage
            )
            // 미트볼 메뉴 드롭다운이 헤더 경계 아래(콘텐츠 영역)로 넘쳐 그려지므로,
            // 헤더를 ScrollView보다 위에 합성해 드롭다운이 가려지지 않게 함.
            .zIndex(1)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    VStack(spacing: 20) {
                        groupInfoSection
                        twoProfileSection
                        actionButtons
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(Color("white"))

                    TrackerStepList(steps: state.steps)
                        .padding(.horizontal, 16)
                }
            }
        }
        .background(Color("uiBg"))
        .overlay { menuOverlay }
    }

    // MARK: 미트볼 더보기 메뉴 — 스크림을 화면 전체 콘텐츠 영역에 깔아 바깥 어디를 눌러도 닫히게 함
    @ViewBuilder
    private var menuOverlay: some View {
        if showMenu {
            ZStack(alignment: .topTrailing) {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture { showMenu = false }
                    .ignoresSafeArea()
                TrackerMoreMenuDropdown(
                    isHost: state.isHost,
                    onEditPeriod: { showMenu = false; onEditPeriod() },
                    onGoToLibrary: { showMenu = false; onGoToLibrary() },
                    onReport: { showMenu = false; onReport() }
                )
                .padding(.trailing, 16).padding(.top, 56)
            }
        }
    }

    // MARK: 그룹 정보(그룹명 · dDay칩 · statusLabel · 4단계 진행바)
    private var groupInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(state.groupName)
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey900"))
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 8) {
                        Text(state.dDay)
                            .pretendardText(size: 11, weight: .medium)
                            .foregroundColor(Color("grey700"))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color("grey100")))
                        Text(state.statusLabel)
                            .pretendardText(size: 16)
                            .foregroundColor(Color("grey800"))
                    }
                    Spacer(minLength: 8)
                    StatusProgressBar(
                        label: state.currentStepLabel,
                        style: state.currentStepLabelStyle,
                        position: state.currentStepPosition
                    )
                }
                .padding(.bottom, 16)
                Rectangle().fill(Color("grey100")).frame(height: 0.8)
            }
        }
    }

    // MARK: 양쪽 프로필 + 교환 커넥터
    private var twoProfileSection: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 16) {
                DetailProfileColumn(profile: state.myProfile, showProgress: state.showReadingProgress)
                DetailProfileColumn(profile: state.partnerProfile, showProgress: state.showReadingProgress)
            }
            ExchangeConnector(label: state.exchangeLabel)
                .padding(.top, 52)
        }
    }

    // MARK: 액션 버튼 (메인 카드와 동일 규칙)
    @ViewBuilder
    private var actionButtons: some View {
        if state.secondaryAction.label.isEmpty {
            CardButton(text: state.primaryAction.label, style: state.primaryEnabled ? .main : .grey, action: onPrimaryAction)
                .disabled(!state.primaryEnabled)
                .frame(maxWidth: .infinity)
        } else {
            HStack(spacing: 12) {
                CardButton(text: state.secondaryAction.label, style: state.secondaryEnabled ? .white : .grey, action: onSecondaryAction)
                    .disabled(!state.secondaryEnabled)
                CardButton(text: state.primaryAction.label, style: state.primaryEnabled ? .main : .grey, action: onPrimaryAction)
                    .disabled(!state.primaryEnabled)
            }
        }
    }
}

// MARK: - 헤더 (뒤로 · "교환 현황" · 메시지 · 미트볼→드롭다운)
private struct TrackerDetailHeader: View {
    @Binding var showMenu: Bool
    let onBack: () -> Void
    let onMessage: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("교환 현황")
                    .pretendardText(size: 20, weight: .medium)
                    .foregroundColor(Color("grey900"))
                HStack(spacing: 0) {
                    Button(action: onBack) {
                        Image("ic_chevron").renderingMode(.template).resizable().scaledToFit()
                            .frame(width: 28, height: 28).foregroundColor(Color("grey900"))
                            .frame(width: 40, height: 40).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                    Spacer()
                    HStack(spacing: 8) {
                        Button(action: onMessage) {
                            Image("ic_message").resizable().scaledToFit()
                                .frame(width: 32, height: 32).frame(width: 40, height: 40).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                        Button { showMenu = true } label: {
                            Image("ic_meetball").resizable().scaledToFit()
                                .frame(width: 32, height: 32).frame(width: 40, height: 40).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 68)
            Rectangle().fill(Color("grey200")).frame(height: 1)
        }
        .background(Color("white"))
    }
}

// MARK: - 4단계 진행바 (dot들 + 현재 단계 칩)
private struct StatusProgressBar: View {
    let label: String
    let style: TrackerStepLabelStyle
    let position: Int

    var body: some View {
        let safePos = min(max(position, 1), 4)
        let bg = style == .main ? Color("main100") : Color("sub100")
        let fg = style == .main ? Color("main200") : Color("sub200")
        HStack(spacing: 4) {
            ForEach(0..<(safePos - 1), id: \.self) { _ in dot }
            Text(label)
                .pretendardText(size: 10)
                .foregroundColor(fg)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(bg))
            ForEach(0..<(4 - safePos), id: \.self) { _ in dot }
        }
    }

    private var dot: some View {
        Circle().fill(Color("grey100")).frame(width: 8, height: 8)
    }
}

// MARK: - 프로필 컬럼 (표지 80x104 + 닉네임/책제목 + 진행바 + 프로필 오버레이)
private struct DetailProfileColumn: View {
    let profile: TrackerProfileItem
    let showProgress: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 8) {
                BookCover(imageUrl: profile.bookCoverUrl)
                    .frame(width: 80, height: 104)
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text(profile.nickname).pretendardText(size: 14).foregroundColor(Color("grey700"))
                        Text(profile.bookTitle.stripBookSubtitle())
                            .pretendardText(size: 16, weight: .medium).foregroundColor(Color("grey800"))
                            .lineLimit(1).truncationMode(.tail)
                    }
                    if showProgress {
                        VStack(alignment: .leading, spacing: 6) {
                            DetailProgressBar(percent: profile.progressPercent)
                            Text(profile.progressLabelOverride ?? "\(profile.progressPercent)%")
                                .pretendardText(size: 14).foregroundColor(Color("grey800"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 12)

            ProfilePlaceholder(imageUrl: profile.profileImageUrl, size: 44, innerStroke: true)
                .offset(x: 27, y: 0)
        }
    }
}

private struct DetailProgressBar: View {
    let percent: Int
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color("grey200"))
                Rectangle().fill(Color("grey800"))
                    .frame(width: proxy.size.width * CGFloat(min(max(percent, 0), 100)) / 100)
            }
        }
        .frame(height: 6)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - 교환 방식 커넥터 (점선 + 라벨 박스)
private struct ExchangeConnector: View {
    let label: String
    var body: some View {
        ZStack {
            Line().stroke(Color("grey300"), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .frame(height: 1)
            Text(label)
                .pretendardText(size: 11, weight: .medium)
                .foregroundColor(Color("grey400"))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color("white")))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color("grey200"), lineWidth: 1))
        }
        .frame(width: 113)
    }
}

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return p
    }
}

// stateful: VM 주입 + 액션 디스패치 + 다이얼로그 호스트 + 네비 배선
struct TrackerDetailRoute: View {
    @EnvironmentObject private var container: DIContainer
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel: TrackerDetailViewModel
    private let groupId: Int

    init(groupId: Int, trackerService: TrackerService, locationService: LocationService) {
        self.groupId = groupId
        _viewModel = StateObject(wrappedValue: TrackerDetailViewModel(
            trackerService: trackerService, locationService: locationService, groupId: groupId
        ))
    }

    var body: some View {
        TrackerDetailScreen(
            state: viewModel.state,
            onBack: { container.navigationRouter.pop() },
            onMessage: goToComment,
            onEditPeriod: {
                let original = viewModel.state.dDayCount.flatMap {
                    Calendar.current.date(byAdding: .day, value: $0, to: Calendar.current.startOfDay(for: Date()))
                }
                viewModel.coordinator.openReadingPeriod(groupId: groupId, originalEndDate: original)
            },
            onGoToLibrary: {
                container.navigationRouter.selectedTab = .library
                container.navigationRouter.popToRoot()
            },
            onReport: { openURL(TrackerExternalLink.reportChannel) },
            onPrimaryAction: { dispatch(viewModel.state.primaryAction) },
            onSecondaryAction: { dispatch(viewModel.state.secondaryAction) }
        )
        .task { await viewModel.load() }
        .onChange(of: viewModel.state.notFound) { _, notFound in
            if notFound { ComErrorRouter.present(.groupClosed) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .comErrorRetry)) { _ in
            Task { await viewModel.load() }
        }
        .trackerDialogHost(
            viewModel.coordinator,
            cardFor: { _ in
                TrackerCardModel(
                    groupId: groupId, groupName: viewModel.state.groupName, displayBookTitle: "", bookTitle: "",
                    progressLabel: "", dDay: "",
                    left: viewModel.state.myProfile,
                    right: viewModel.state.partnerProfile,
                    isHost: viewModel.state.isHost
                )
            },
            onNavigateComment: { _ in goToComment() }
        )
    }

    // 상단바 메시지 아이콘 / 카드 액션 / 다이얼로그가 모두 같은 댓글 화면으로 진입
    private func goToComment() {
        container.navigationRouter.push(to: .trackerComment(groupId: groupId, title: viewModel.state.groupName))
    }

    private func dispatch(_ action: TrackerAction) {
        dispatchTrackerAction(
            action, groupId: groupId, coordinator: viewModel.coordinator,
            nav: TrackerNavActions(
                onNavigateBookReview: { gid, edit in container.navigationRouter.push(to: .trackerBookReview(groupId: gid, isEdit: edit)) },
                onNavigatePartnerReview: { gid in container.navigationRouter.push(to: .trackerPartnerReview(groupId: gid)) },
                onNavigateComment: { _ in goToComment() },
                onWriteReadingCard: { gid in
                    let title = viewModel.state.myProfile.bookTitle
                    Task {
                        if let book = await resolveTrackerLibraryBook(libraryService: container.api.library, groupId: gid, bookTitle: title) {
                            container.navigationRouter.push(to: .libraryCards(book: book))
                        }
                    }
                }
            )
        )
    }
}

#Preview {
    TrackerDetailScreen(
        state: TrackerDetailUiState(
            groupName: "김영하 도장깨기 하실 분",
            dDay: "D-2",
            statusLabel: "살인자의 기억법... · 운송장 등록",
            currentStepLabel: "내 책 읽기",
            currentStepLabelStyle: .main,
            currentStepPosition: 1,
            myProfile: TrackerProfileItem(nickname: "나", bookTitle: "살인자의 기억법", bookCoverUrl: nil, profileImageUrl: nil, progressPercent: 100, isOwnerBook: true),
            partnerProfile: TrackerProfileItem(nickname: "noshel", bookTitle: "작별인사", bookCoverUrl: nil, profileImageUrl: nil, progressPercent: 0, isOwnerBook: false),
            exchangeLabel: "택배 교환",
            primaryAction: .writeBookReview,
            secondaryAction: .writeReadingCard,
            isHost: true,
            steps: [
                TrackerStep(title: "파트너 책 읽기", description: "작별인사를 읽고 진행률을 기록해주세요", status: .inProgress(chipText: "D-2")),
                TrackerStep(title: "교환", description: "파트너와 책을 교환해주세요", status: .completed),
            ]
        ),
        onBack: {}, onMessage: {}, onEditPeriod: {}, onGoToLibrary: {}, onReport: {},
        onPrimaryAction: {}, onSecondaryAction: {}
    )
}
