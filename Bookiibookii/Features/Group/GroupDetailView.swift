import SwiftUI

// 그룹 상세 화면. 안드 GroupDetailScreen.kt(GroupDetailScreen/Content/InfoSection) 대응.
// 진입: GroupView/HomeView/NotificationView에서 fullScreenCover(item:)로 표시 → 로컬 @State 해제로 닫힘.
struct GroupDetailView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: GroupDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editGroupId: Int? = nil
    @StateObject private var commentVM: GroupCommentViewModel
    @StateObject private var keyboard = KeyboardObserver()
    @State private var sheetExpanded = false
    @State private var dragAccum: CGFloat = 0
    // 홈 인디케이터 세이프에어리어 인셋(키보드 없을 때 캡처). 입력창을 키보드에 딱 붙이기 위한 보정값.
    @State private var homeIndicatorInset: CGFloat = 0
    @State private var selectedProfileNickname: NicknameRoute?
    // 삭제 성공으로 상세가 닫힐 때 호출(진입 화면의 목록 재조회용). 삭제 외 뒤로가기에서는 호출 안 됨.
    private let onDeleted: (() -> Void)?

    init(groupId: Int, groupService: GroupService, onDeleted: (() -> Void)? = nil) {
        _viewModel = StateObject(
            wrappedValue: GroupDetailViewModel(groupId: groupId, service: groupService)
        )
        _commentVM = StateObject(
            wrappedValue: GroupCommentViewModel(groupId: groupId, service: groupService)
        )
        self.onDeleted = onDeleted
    }

    var body: some View {
        VStack(spacing: 0) {
            GroupDetailHeader(
                showEditMenu: viewModel.detail?.buttonStatus == "MANAGE",
                onBack: { dismiss() },
                onEdit: { editGroupId = viewModel.groupId },
                onDelete: { viewModel.showDeleteDialog = true }
            )
            // 미트볼 메뉴 드롭다운이 헤더 경계 아래(콘텐츠 영역)로 넘쳐 그려지므로,
            // 헤더를 콘텐츠 ZStack보다 위에 합성해 드롭다운이 가려지지 않게 함.
            .zIndex(1)

            ZStack {
                switch viewModel.phase {
                case .idle, .loading:
                    ProgressView()
                        .tint(Color("main200"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failed:
                    failedContent
                case .loaded:
                    if let detail = viewModel.detail {
                        loadedContent(detail)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("grey100"))
        }
        .background(Color("white"))
        .ignoresSafeArea(.keyboard)
        .dismissKeyboardOnTap()
        .overlay(alignment: .bottom) {
            if viewModel.phase == .loaded {
                GroupCommentSheet(
                    viewModel: commentVM,
                    expanded: sheetExpanded,
                    keyboardHeight: effectiveKeyboardInset,
                    onExpand: { withAnimation { sheetExpanded = true } },
                    onProfileTap: { selectedProfileNickname = NicknameRoute(nickname: $0) }
                )
                .frame(height: sheetHeight)
                .gesture(
                    DragGesture()
                        .onChanged { value in dragAccum = value.translation.height }
                        .onEnded { _ in
                            let trigger: CGFloat = 50
                            if dragAccum < -trigger { withAnimation { sheetExpanded = true } }
                            else if dragAccum > trigger { withAnimation { sheetExpanded = false } }
                            dragAccum = 0
                        }
                )
                .animation(.easeInOut(duration: 0.25), value: sheetHeight)
                // 오버레이는 위 VStack의 .ignoresSafeArea(.keyboard) 밖이라, 시트 자신이 키보드 회피를
                // 꺼야 함. 안 그러면 SwiftUI가 시트를 통째로 밀어올린 뒤 입력창까지 또 올려 이중으로 뜬다.
                .ignoresSafeArea(.keyboard)
            }
        }
        .overlay { dialogOverlay }
        .fullScreenCover(isPresented: $viewModel.showApplicants) {
            GroupApplicantView(
                viewModel: viewModel,
                onProfileTap: { selectedProfileNickname = NicknameRoute(nickname: $0) }
            )
        }
        // 상세는 fullScreenCover 모달 루트라 NavigationStack이 없어 router.push가 화면 전환을 못 함.
        // 그래서 에디터도 fullScreenCover로 present(상세 자신의 진입 방식과 동일).
        // 에디터가 닫히면(수정 성공/취소 무관) 상세를 재조회해 변경사항 반영.
        .fullScreenCover(item: $editGroupId, onDismiss: { viewModel.retry() }) { groupId in
            GroupEditorView(
                groupId: groupId,
                groupService: container.api.group,
                locationService: container.api.location
            )
            .environmentObject(container)
        }
        .fullScreenCover(item: $selectedProfileNickname) { route in
            NavigationStack {
                OtherProfileView(
                    nickname: route.nickname,
                    userService: container.api.user,
                    onClose: { selectedProfileNickname = nil }
                )
                .environmentObject(container)
            }
        }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss {
                onDeleted?()
                dismiss()
            }
        }
        .task {
            viewModel.attachLocationService(container.api.location)
            await viewModel.onAppear()
            await commentVM.load()
        }
        .onAppear {
            // 키보드 없는 시점에 홈 인디케이터 인셋 캡처(키보드 뜨면 0으로 보고돼 부정확).
            homeIndicatorInset = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }?.safeAreaInsets.bottom ?? 0
        }
        .toast($viewModel.toast)
        .toast($commentVM.toast)
    }

    // 3단계 높이 — keyboard(600) > expanded(544) > peek(170). 안드 sheetHeight 대응.
    private var sheetHeight: CGFloat {
        if keyboard.height > 0 { return 600 }
        return sheetExpanded ? 544 : 170
    }

    // 시트는 세이프에어리어 하단에 붙으므로, 키보드 전체 높이에서 홈 인디케이터 인셋을 빼야
    // 입력창이 키보드 바로 위에 딱 붙는다(안 빼면 그 인셋만큼 떠 보임).
    private var effectiveKeyboardInset: CGFloat {
        keyboard.height > 0 ? max(0, keyboard.height - homeIndicatorInset) : 0
    }

    // MARK: - 에러 상태

    private var failedContent: some View {
        VStack(spacing: 16) {
            Text("불러오기 실패")
                .pretendardText(size: 14)
                .foregroundColor(Color("grey500"))
            Button {
                viewModel.retry()
            } label: {
                Text("다시 시도")
                    .pretendardText(size: 14, weight: .medium)
                    .foregroundColor(Color("main200"))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 로드됨 (스크롤 본문)

    private func loadedContent(_ detail: GroupDetailDto) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                infoSection(detail)
                VStack(spacing: 16) {
                    GroupDetailDescriptionCard(
                        title: "그룹 소개",
                        body: detail.groupComment ?? "",
                        // 택배 교환은 주소 정보를 노출하지 않음. 직접 교환만 희망 장소 표시
                        exchangePlaceName: detail.tradeType == "DELIVERY" ? nil : detail.address,
                        exchangePlaceAddress: detail.detailAddress.isEmpty ? nil : detail.detailAddress,
                        exchangePlaceLabel: "교환 희망 장소"
                    )
                    GroupDetailDescriptionCard(
                        title: "그룹 규칙",
                        body: detail.rules.enumerated()
                            .map { "\($0.offset + 1). \($0.element.content)" }
                            .joined(separator: "\n")
                    )
                    GroupDetailMembersCard(
                        matchedCount: detail.matchedCount,
                        maxCapacity: detail.maxCapacity,
                        slots: detail.participantSlots,
                        onProfileTap: { selectedProfileNickname = NicknameRoute(nickname: $0) }
                    )
                }
                .padding(16)
            }
            .padding(.bottom, 170)
        }
    }

    // 그룹 정보 카드 + 하단 액션 버튼 (안드 GroupDetailInfoSection 대응)
    private func infoSection(_ detail: GroupDetailDto) -> some View {
        VStack(spacing: 16) {
            GroupDetailBookInfo(detail: detail)
            if let action = viewModel.actionButton {
                CardButton(
                    text: action.text,
                    style: action.style,
                    height: 48,
                    action: { viewModel.handleActionTap() }
                )
            }
        }
        .padding(16)
        .background(Color("white"))
    }

    // MARK: - 다이얼로그

    @ViewBuilder
    private var dialogOverlay: some View {
        if viewModel.showApplyDialog {
            dialogBackdrop {
                GroupApplyDialog(
                    query: Binding(
                        get: { viewModel.bookSearchQuery },
                        set: { viewModel.onBookQueryChange($0) }
                    ),
                    results: viewModel.bookSearchResults,
                    bookSelected: viewModel.selectedISBN != nil,
                    applyMsg: Binding(
                        get: { viewModel.applyMsg },
                        set: { viewModel.onApplyMsgChange($0) }
                    ),
                    loading: viewModel.bookSearchLoading,
                    canSubmit: viewModel.canSubmit,
                    onSearch: { viewModel.searchBooks() },
                    onClear: { viewModel.clearBookSearch() },
                    onSelect: { viewModel.selectBook($0) },
                    onSubmit: { viewModel.submitApply() },
                    onDismiss: {
                        viewModel.showApplyDialog = false
                        viewModel.resetApplyDialog()
                    }
                )
                .padding(.horizontal, 24)
            }
        } else if viewModel.showDeleteDialog {
            dialogBackdrop {
                GroupDeleteDialog(
                    groupName: viewModel.detail?.groupName ?? "",
                    onDismiss: { viewModel.showDeleteDialog = false },
                    onConfirm: {
                        viewModel.showDeleteDialog = false
                        viewModel.confirmDelete()
                    }
                )
                .padding(.horizontal, 24)
            }
        } else if viewModel.showAddressRequiredDialog {
            dialogBackdrop {
                GroupAddressRequiredDialog(
                    onDismiss: { viewModel.showAddressRequiredDialog = false },
                    onManageAddress: {
                        viewModel.showAddressRequiredDialog = false
                        container.navigationRouter.push(to: .addressManagement(initialTab: viewModel.addressManagementTab))
                    }
                )
                .padding(.horizontal, 24)
            }
        }
    }

    @ViewBuilder
    private func dialogBackdrop<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            content()
        }
    }
}
