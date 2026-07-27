import SwiftUI

// 안드로이드 KeywordSettingScreen + Figma HOM-02-02 대응.
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

            inputSection
                .padding(.top, 12)

            keywordList
                .padding(.top, 12)
        }
        .background(Color("uiBg").ignoresSafeArea())
        .task { await viewModel.onAppear() }
        .overlay(alignment: .bottom) { toastOverlay }
        .onTapGesture { inputFocused = false }
    }

    // MARK: - 네비게이션 바

    private var navBar: some View {
        HStack(alignment: .center, spacing: 0) {
            Button { dismiss() } label: {
                Image("ic_back")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
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
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color("grey200")).frame(height: 1)
        }
    }

    // MARK: - 입력 + 카운트

    private var inputSection: some View {
        VStack(spacing: 0) {
            inputRow
                .padding(.horizontal, 16)

            HStack(spacing: 4) {
                Text("\(viewModel.items.count)")
                    .pretendardText(size: 14, weight: .regular)
                    .foregroundColor(Color("grey500"))
                Text("/\(KeywordSettingViewModel.maxCount) 개")
                    .pretendardText(size: 14, weight: .regular)
                    .foregroundColor(Color("grey500"))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var inputRow: some View {
        HStack(spacing: 8) {
            TextField("알림 받을 키워드를 입력해주세요", text: $input)
                .pretendardText(size: 16, weight: .regular)
                .foregroundColor(Color("grey900"))
                .focused($inputFocused)
                .submitLabel(.done)
                .disabled(isOverLimit || viewModel.isAdding)
                .onSubmit { Task { await submit() } }
                .onChange(of: input) { _, newValue in
                    let sanitized = KeywordSettingViewModel.sanitizeInput(newValue)
                    if sanitized != newValue { input = sanitized }

                    if input.count > KeywordSettingViewModel.maxLength {
                        viewModel.toastMessage = "키워드는 최대 \(KeywordSettingViewModel.maxLength)자까지 입력할 수 있어요."
                    }
                }

            Button {
                Task { await submit() }
            } label: {
                Image("ic_plus")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(Color("grey500"))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color("grey100")))
            }
            .buttonStyle(.plain)
            .disabled(!isAddEnabled || viewModel.isAdding)
        }
        .padding(.leading, 20)
        .padding(.trailing, 8)
        .frame(height: 48)
        .background(Color("white"))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                bottomLeadingRadius: 20,
                bottomTrailingRadius: 30,
                topTrailingRadius: 30,
                style: .continuous
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                bottomLeadingRadius: 20,
                bottomTrailingRadius: 30,
                topTrailingRadius: 30,
                style: .continuous
            )
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
        let success = await viewModel.addKeyword(trimmed)
        if success { input = "" }
    }

    // MARK: - 리스트

    @ViewBuilder
    private var keywordList: some View {
        if viewModel.isLoading && viewModel.items.isEmpty {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.items.isEmpty {
            Text("등록된 키워드가 없어요.")
                .pretendardText(size: 16, weight: .regular)
                .foregroundColor(Color("grey600"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color("white"))
                )
                .padding(.horizontal, 16)
            Spacer()
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.items) { item in
                        KeywordRow(item: item) {
                            Task { await viewModel.delete(item.keywordId) }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - 토스트 (Figma: 흰 카드 + 체크 아이콘)

    @ViewBuilder
    private var toastOverlay: some View {
        if let message = viewModel.toastMessage {
            let isSuccess = message == "키워드가 등록되었습니다."
            HStack(spacing: 8) {
                if isSuccess {
                    Image("ic_check")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(Color("main200"))
                        .frame(width: 24, height: 24)
                }

                Text(message)
                    .pretendardText(size: 14, weight: .regular)
                    .foregroundColor(Color("grey700"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color("white"))
                    .shadow(color: Color.black.opacity(0.1), radius: 17.5, x: 0, y: 0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color("grey200"), lineWidth: 1)
            )
            .padding(.horizontal, 36)
            .padding(.bottom, 40)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .task(id: message) {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
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
                .pretendardText(size: 16, weight: .regular)
                .foregroundColor(Color("grey900"))
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 0)
            Button(action: onDelete) {
                Image("ic_trash")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color("grey500"))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color("white"))
        )
    }
}
