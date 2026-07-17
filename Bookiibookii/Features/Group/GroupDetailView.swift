import SwiftUI

// 그룹 상세 화면. 안드 GroupDetailScreen.kt(GroupDetailScreen/Content/InfoSection) 대응.
// 진입: GroupView/HomeView/NotificationView에서 fullScreenCover(item:)로 표시 → 로컬 @State 해제로 닫힘.
struct GroupDetailView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: GroupDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editGroupId: Int? = nil
    @State private var showAddressManagement = false
    @StateObject private var commentVM: GroupCommentViewModel
    // 콘텐츠 높이로 계산되는 peek detent 값. 시트가 측정해 써넣는다.
    @State private var peekHeight: CGFloat = 170
    @State private var sheetDetent: PresentationDetent = .height(170)
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
        .sheet(isPresented: isCommentSheetPresented) {
            GroupCommentSheet(
                viewModel: commentVM,
                peekHeight: $peekHeight,
                onProfileTap: { selectedProfileNickname = NicknameRoute(nickname: $0) },
                onInputFocus: { sheetDetent = .fraction(0.6) }
            )
            .presentationDetents([.height(peekHeight), .fraction(0.6)], selection: $sheetDetent)
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
            .presentationBackground(Color("white"))
            .presentationBackgroundInteraction(.enabled(upThrough: .height(peekHeight)))
            .interactiveDismissDisabled(true)
            .onChange(of: peekHeight) { old, new in
                if sheetDetent == .height(old) { sheetDetent = .height(new) }
            }
            // 답글 진입 시 시트를 펼쳐 대상 댓글과 입력창이 함께 보이게 한다.
            // 포커스/키보드는 CommentInputTextView가 focusTrigger로 처리.
            .onChange(of: commentVM.state.replyRequestId) { _, newValue in
                if newValue > 0 { sheetDetent = .fraction(0.6) }
            }
            // 시트가 상세 위에 뜨므로 댓글 토스트도 시트 안에서 표시해야 보인다
            .toast($commentVM.toast)
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
        // 상세는 모달 루트라 router.push가 안 되므로 주소관리도 fullScreenCover로 present.
        .fullScreenCover(isPresented: $showAddressManagement) {
            AddressManagementView(
                locationService: container.api.location,
                initialTab: viewModel.addressManagementTab
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
        .toast($viewModel.toast)
    }

    // 다른 모달(다이얼로그/풀스크린커버)이 열려 있는 동안에는 시트를 내린다.
    // UIKit이 한 번에 하나만 present할 수 있고, 네이티브 시트가 오버레이 다이얼로그를 가리기 때문.
    private var isCommentSheetPresented: Binding<Bool> {
        Binding(
            get: {
                viewModel.phase == .loaded
                    && !viewModel.showApplyDialog
                    && !viewModel.showDeleteDialog
                    && !viewModel.showAddressRequiredDialog
                    && !viewModel.showApplicants
                    && editGroupId == nil
                    && !showAddressManagement
                    && selectedProfileNickname == nil
            },
            // 사용자 드래그로는 닫히지 않고(interactiveDismissDisabled) 위 조건으로만 결정되므로 set은 무시
            set: { _ in }
        )
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
                        exchangePlaceAddress: detail.detailAddress?.isEmpty == false ? detail.detailAddress : nil,
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
            .padding(.bottom, peekHeight)
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
                        showAddressManagement = true
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
