import SwiftUI

// 그룹 상세 화면. 안드 GroupDetailScreen.kt(GroupDetailScreen/Content/InfoSection) 대응.
// 진입: GroupView/HomeView/NotificationView에서 fullScreenCover(item:)로 표시 → 로컬 @State 해제로 닫힘.
struct GroupDetailView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: GroupDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editGroupId: Int? = nil

    init(groupId: Int, groupService: GroupService) {
        _viewModel = StateObject(
            wrappedValue: GroupDetailViewModel(groupId: groupId, service: groupService)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            GroupDetailHeader(
                showEditMenu: viewModel.detail?.buttonStatus == "MANAGE",
                onBack: { dismiss() },
                onEdit: { editGroupId = viewModel.groupId },
                onDelete: { viewModel.showDeleteDialog = true }
            )

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
        .overlay { dialogOverlay }
        .fullScreenCover(isPresented: $viewModel.showApplicants) {
            GroupApplicantView(viewModel: viewModel)
        }
        // 상세는 fullScreenCover 모달 루트라 NavigationStack이 없어 router.push가 화면 전환을 못 함.
        // 그래서 에디터도 fullScreenCover로 present(상세 자신의 진입 방식과 동일).
        .fullScreenCover(item: $editGroupId) { groupId in
            GroupEditorView(
                groupId: groupId,
                groupService: container.api.group,
                locationService: container.api.location
            )
            .environmentObject(container)
        }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss { dismiss() }
        }
        .task {
            viewModel.attachLocationService(container.api.location)
            await viewModel.onAppear()
        }
        .toast($viewModel.toast)
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
                        slots: detail.participantSlots
                    )
                }
                .padding(16)
            }
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
                        viewModel.manageAddress()
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
