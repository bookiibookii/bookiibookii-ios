import SwiftUI

// 그룹 생성/수정 통합 화면. 안드 group/ui/editor/GroupEditorScreen.kt(Route+Screen) 대응.
struct GroupEditorView: View {
    @StateObject private var viewModel: GroupEditorViewModel
    @EnvironmentObject private var container: DIContainer
    // 에디터는 홈에서 push, 그룹 상세에서 fullScreenCover로 진입한다.
    // router.pop()은 push 진입만 닫고 cover는 못 닫으므로, 양쪽 모두에서 동작하는 dismiss 사용.
    @Environment(\.dismiss) private var dismiss

    init(groupId: Int?, groupService: GroupService, locationService: LocationService) {
        _viewModel = StateObject(wrappedValue: GroupEditorViewModel(
            groupId: groupId,
            service: groupService,
            locationService: locationService
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            GroupEditorHeader(
                title: viewModel.isEdit ? "그룹 수정" : "그룹 만들기",
                onBack: { dismiss() }
            )

            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        if !viewModel.isEdit {
                            BookSearchSection(
                                query: $viewModel.bookSearchQuery,
                                results: viewModel.bookSearchResults,
                                bookSelected: viewModel.isbn13 != nil,
                                error: viewModel.bookSearchError,
                                onQueryChange: viewModel.onBookSearchQueryChange,
                                onSearchClick: viewModel.searchBooks,
                                onClearClick: viewModel.onClearBookSearch,
                                onBookSelect: viewModel.onBookSelect
                            )
                        }
                        GroupNameSection(value: $viewModel.groupName)
                    }

                    if !viewModel.isEdit {
                        GroupEditorSectionDivider()
                        VStack(spacing: 16) {
                            ExchangeTypeSection(
                                selected: viewModel.tradeType,
                                onSelect: viewModel.onTradeTypeSelect
                            )
                            if let type = viewModel.tradeType {
                                AddressSection(
                                    tradeType: type,
                                    places: viewModel.places,
                                    selectedPlaceId: viewModel.selectedPlaceId,
                                    onPlaceSelect: viewModel.onPlaceSelect,
                                    onManageAddress: { type in
                                        container.navigationRouter.push(to: .addressManagement(initialTab: type.addressManagementTab))
                                    }
                                )
                            }
                        }
                    }

                    GroupEditorSectionDivider()
                    ReadingPeriodSection(
                        selectedIndex: viewModel.readingPeriodIndex,
                        onSelect: viewModel.onReadingPeriodSelect
                    )

                    GroupEditorSectionDivider()
                    GroupRuleSection(
                        selectedRule: viewModel.ruleStyle,
                        onRuleSelect: viewModel.onRuleStyleSelect,
                        customRules: viewModel.customRules,
                        onAddCustomRule: viewModel.onAddCustomRule,
                        onCustomRuleChange: viewModel.onCustomRuleChange,
                        onRemoveCustomRule: viewModel.onRemoveCustomRule
                    )

                    GroupEditorSectionDivider()
                    GroupIntroSection(value: $viewModel.groupComment)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 92)
            }

            VStack(spacing: 8) {
                if let submitError = viewModel.submitError {
                    Text(submitError)
                        .pretendardText(size: 14)
                        .foregroundColor(Color("pointRed"))
                }
                FooterButton(
                    text: viewModel.isEdit ? "그룹 수정" : "그룹 만들기",
                    enabled: viewModel.canSubmit && viewModel.isDirty && !viewModel.submitting,
                    isLoading: viewModel.submitting,
                    action: {
                        // 20자 그룹명 가드는 View 레이어(안드 Route onSubmit 래핑 대응, canSubmit과 별개)
                        if viewModel.groupName.count > 20 {
                            viewModel.toast = .failure("그룹명은 20자 이하로 작성해주세요")
                        } else {
                            Task { await viewModel.submit() }
                        }
                    }
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .onAppear { viewModel.reloadPlaces() }
        .background(Color("white"))
        .toast($viewModel.toast)
        .dismissKeyboardOnTap()
        .onChange(of: viewModel.createdEvent) { _, created in
            if created { dismiss() }   // 생성 성공 → 뒤로가기(상세 자동이동 안 함)
        }
        .onChange(of: viewModel.updatedGroupId) { _, updated in
            if updated != nil { dismiss() }   // 수정 성공 → 뒤로가기
        }
        .onChange(of: viewModel.prefillFailed) { _, failed in
            if let failed {
                viewModel.toast = .failure(failed)   // 프리필 실패 → 토스트 후 뒤로가기
                dismiss()
            }
        }
    }
}

// MARK: - Header (안드 270-301행)

private struct GroupEditorHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color("black"))
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                Text(title)
                    .pretendardText(size: 20, weight: .medium)
                    .foregroundColor(Color("grey900"))
            }
            .padding(.horizontal, 16)
            .frame(height: 68)
            .background(Color("white"))

            Rectangle()
                .fill(Color("grey200"))
                .frame(height: 1)
        }
    }
}
