import SwiftUI

struct TrackerMainScreen: View {
    let state: TrackerMainUiState
    let onProfileTap: () -> Void
    let onNotificationTap: () -> Void
    let onCreateGroupTap: () -> Void
    let onCardClick: (Int) -> Void
    let onPrimaryAction: (Int) -> Void
    let onSecondaryAction: (Int) -> Void
    let onRefresh: () async -> Void

    var body: some View {
        VStack(spacing: 0) {
            BookiiTopBar(
                title: "트래커",
                hasNotificationBadge: state.hasNewNotification,
                onProfileTap: onProfileTap,
                onNotificationTap: onNotificationTap
            )
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        TrackerNoticeBanner(nickname: state.nickname)
                        if !state.cards.isEmpty {
                            TrackerNotificationCard(
                                notifications: state.notifications,
                                onItemClick: onCardClick
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color("white"))

                    VStack(spacing: 12) {
                        TrackerCountBoard(
                            total: state.totalCount,
                            reading: state.readingCount,
                            exchanging: state.exchangingCount,
                            review: state.reviewCount
                        )
                        if state.hasLoadedOnce && state.cards.isEmpty {
                            TrackerEmptyCard(onCreateGroupClick: onCreateGroupTap)
                        } else {
                            ForEach(state.cards) { card in
                                TrackerMainCard(
                                    card: card,
                                    onCardClick: { onCardClick(card.groupId) },
                                    onPrimaryAction: { onPrimaryAction(card.groupId) },
                                    onSecondaryAction: { onSecondaryAction(card.groupId) }
                                )
                            }
                        }
                        Spacer().frame(height: 192)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .refreshable { await onRefresh() }
        }
        .background(Color("uiBg"))
    }
}

// stateful: VM 주입 + 카드 버튼 액션 분기(다이얼로그 열기/네비 디스패치)
struct TrackerMainRoute: View {
    @StateObject private var viewModel: TrackerMainViewModel
    var onProfileTap: () -> Void
    var onNotificationTap: () -> Void
    var onCreateGroupTap: () -> Void

    init(
        viewModel: TrackerMainViewModel,
        onProfileTap: @escaping () -> Void = {},
        onNotificationTap: @escaping () -> Void = {},
        onCreateGroupTap: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onProfileTap = onProfileTap
        self.onNotificationTap = onNotificationTap
        self.onCreateGroupTap = onCreateGroupTap
    }

    var body: some View {
        TrackerMainScreen(
            state: viewModel.state,
            onProfileTap: onProfileTap,
            onNotificationTap: onNotificationTap,
            onCreateGroupTap: onCreateGroupTap,
            onCardClick: { _ in },   // PR-A 플레이스홀더 (상세 화면은 #5·#8)
            onPrimaryAction: { groupId in
                guard let card = viewModel.state.cards.first(where: { $0.groupId == groupId }) else { return }
                dispatchTrackerAction(
                    card.primaryAction,
                    groupId: groupId,
                    coordinator: viewModel.coordinator,
                    nav: TrackerNavActions()
                )
            },
            onSecondaryAction: { groupId in
                guard let card = viewModel.state.cards.first(where: { $0.groupId == groupId }) else { return }
                dispatchTrackerAction(
                    card.secondaryAction,
                    groupId: groupId,
                    coordinator: viewModel.coordinator,
                    nav: TrackerNavActions()
                )
            },
            onRefresh: { await viewModel.onAppear() }
        )
        .task { await viewModel.onAppear() }
        .trackerDialogHost(viewModel.coordinator, cardFor: { id in viewModel.state.cards.first { $0.groupId == id } })
    }
}
