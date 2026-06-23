import SwiftUI

// 안드로이드 NotificationKeywordSettingActivity + activity_notification_keyword_setting.xml 대응.
struct KeywordSettingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: KeywordSettingViewModel

    @State private var input: String = ""
    @FocusState private var inputFocused: Bool

    init(keywordService: KeywordService) {
        _viewModel = StateObject(wrappedValue: KeywordSettingViewModel(service: keywordService))
    }

    var body: some View {
        VStack(spacing: 0) {
            navBar
            Divider().background(Color("grey200"))

            inputRow
                .padding(.horizontal, 20)
                .padding(.top, 16)

            countAndSortRow
                .padding(.horizontal, 20)
                .padding(.top, 12)

            keywordList
        }
        .background(Color("grey100").ignoresSafeArea())
        .task { await viewModel.onAppear() }
        .overlay(alignment: .bottom) { toastOverlay }
        .onTapGesture { inputFocused = false }
    }

    // MARK: - 네비게이션 바

    private var navBar: some View {
        HStack(alignment: .center, spacing: 0) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color("grey900"))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            Spacer()
            Text("키워드 알림 설정")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))
            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color("white"))
    }

    // MARK: - 입력 + 추가 버튼

    private var inputRow: some View {
        HStack(spacing: 8) {
            TextField("알림 받을 키워드를 입력해주세요", text: $input)
                .pretendardText(size: 14)
                .foregroundColor(Color("grey900"))
                .focused($inputFocused)
                .submitLabel(.done)
                .disabled(isOverLimit)
                .onSubmit { Task { await submit() } }
                .onChange(of: input) { _, newValue in
                    // 공백/이모지 등 허용 외 문자는 입력 자체를 차단
                    let sanitized = KeywordSettingViewModel.sanitizeInput(newValue)
                    if sanitized != newValue { input = sanitized }

                    if input.count > KeywordSettingViewModel.maxLength {
                        viewModel.toastMessage = "키워드는 최대 \(KeywordSettingViewModel.maxLength)자까지 입력할 수 있어요."
                    }
                }
                .padding(.leading, 16)

            Button {
                Task { await submit() }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isAddEnabled ? Color("white") : Color("grey500"))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(isAddEnabled ? Color("grey900") : Color("grey200")))
            }
            .buttonStyle(.plain)
            .disabled(!isAddEnabled)
            .padding(.trailing, 8)
        }
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("white"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color("grey200"), lineWidth: 1)
        )
    }

    private var isOverLimit: Bool { viewModel.items.count >= KeywordSettingViewModel.maxCount }

    private var isAddEnabled: Bool {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && !isOverLimit
    }

    private func submit() async {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        await viewModel.addKeyword(trimmed)
        input = ""
    }

    // MARK: - 카운트 + 정렬

    private var countAndSortRow: some View {
        HStack {
            HStack(spacing: 0) {
                Text("\(viewModel.items.count)")
                    .pretendardText(size: 12)
                    .foregroundColor(Color("grey500"))
                Text(" / \(KeywordSettingViewModel.maxCount) 개")
                    .pretendardText(size: 12)
                    .foregroundColor(Color("grey500"))
            }
            Spacer()
            HStack(spacing: 8) {
                sortButton(title: "최신순", sort: .latest)
                Text("|")
                    .pretendardText(size: 12)
                    .foregroundColor(Color("grey300"))
                sortButton(title: "ㄱ-ㄴ-ㄷ 순", sort: .alphabetical)
            }
        }
    }

    private func sortButton(title: String, sort: KeywordSort) -> some View {
        let isActive = viewModel.sort == sort
        return Button {
            Task { await viewModel.changeSort(sort) }
        } label: {
            Text(title)
                .pretendardText(size: 12, weight: isActive ? .bold : .regular)
                .foregroundColor(isActive ? Color("main200") : Color("grey500"))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 리스트

    @ViewBuilder
    private var keywordList: some View {
        if viewModel.isLoading && viewModel.items.isEmpty {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.items.isEmpty {
            Spacer()
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.items) { item in
                        KeywordRow(item: item) {
                            Task { await viewModel.delete(item.keywordId) }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - 토스트

    @ViewBuilder
    private var toastOverlay: some View {
        if let message = viewModel.toastMessage {
            Text(message)
                .pretendardText(size: 13)
                .foregroundColor(Color("white"))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color("grey900").opacity(0.9)))
                .padding(.bottom, 40)
                .transition(.opacity)
                .task(id: message) {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    withAnimation { viewModel.toastMessage = nil }
                }
        }
    }
}

// MARK: - 키워드 Row

private struct KeywordRow: View {
    let item: KeywordItemDto
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(item.content)
                .pretendardText(size: 14)
                .foregroundColor(Color("grey900"))
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color("grey500"))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("white"))
        )
    }
}
