import SwiftUI

struct AccountWithdrawalView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: AccountWithdrawalViewModel
    @State private var showConfirmPopup = false

    init(userService: UserService) {
        _viewModel = StateObject(wrappedValue: AccountWithdrawalViewModel(userService: userService))
    }

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        titleSection
                        instructionText
                        reasonList
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }

            VStack {
                Spacer()
                FooterButton(
                    text: "다음",
                    enabled: viewModel.canProceed,
                    isLoading: false,
                    action: { showConfirmPopup = true }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }

            if viewModel.isLoadingProfile || viewModel.isSubmitting {
                Color.black.opacity(0.15).ignoresSafeArea()
                ProgressView()
            }

            if showConfirmPopup {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture {
                        guard !viewModel.isSubmitting else { return }
                        showConfirmPopup = false
                    }

                WithdrawPopupView(
                    onCancel: {
                        guard !viewModel.isSubmitting else { return }
                        showConfirmPopup = false
                    },
                    onConfirm: {
                        Task { await submitWithdrawal() }
                    }
                )
                .padding(.horizontal, 20)
            }

            if viewModel.showActiveGroupRestriction {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture {
                        viewModel.showActiveGroupRestriction = false
                    }

                WithdrawRestrictedPopupView {
                    viewModel.showActiveGroupRestriction = false
                }
                .padding(.horizontal, 20)
            }
        }
        .alert("안내", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task { await viewModel.loadProfile() }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { container.navigationRouter.pop() } label: {
                Image("ic_back")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("회원 탈퇴")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Divider().overlay(Color("grey200"))
        }
    }

    // MARK: - Content

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Text(viewModel.nickname.isEmpty ? " " : viewModel.nickname)
                    .pretendardText(size: 28, weight: .semibold)
                    .foregroundColor(Color("main200"))
                Text("님과 이별인가요?")
                    .pretendardText(size: 28, weight: .regular)
                    .foregroundColor(Color("grey900"))
            }

            Text("너무 아쉬워요.")
                .pretendardText(size: 28, weight: .regular)
                .foregroundColor(Color("grey900"))
        }
        .padding(.vertical, 8)
    }

    private var instructionText: some View {
        Text("서비스 개선을 위하여 사유를 선택해주세요.")
            .pretendardText(size: 16, weight: .regular)
            .foregroundColor(Color("grey700"))
    }

    private var reasonList: some View {
        VStack(spacing: 8) {
            ForEach(WithdrawalReason.allCases, id: \.self) { reason in
                reasonRow(reason)
            }

            if viewModel.selectedReason == .customInput {
                customReasonField
            }
        }
    }

    private func reasonRow(_ reason: WithdrawalReason) -> some View {
        let isSelected = viewModel.selectedReason == reason

        return Button {
            viewModel.selectedReason = reason
            if reason != .customInput {
                viewModel.customReason = ""
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color("main105") : Color("main100"))
                        .frame(width: 28, height: 28)
                    Image("ic_check")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color("main200"))
                }

                Text(reason.displayName)
                    .pretendardText(size: 15, weight: .regular)
                    .foregroundColor(isSelected ? Color("main200") : Color("grey900"))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 56)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color("main100") : Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Color("main105") : Color("grey200"), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var customReasonField: some View {
        ZStack(alignment: .topLeading) {
            if viewModel.customReason.isEmpty {
                Text("탈퇴 사유를 입력해주세요.")
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey500"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
            }

            TextField("", text: $viewModel.customReason, axis: .vertical)
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey800"))
                .lineLimit(4...8)
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .onChange(of: viewModel.customReason) { _, newValue in
                    if newValue.count > 500 {
                        viewModel.customReason = String(newValue.prefix(500))
                    }
                }
        }
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color("grey300"), lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func submitWithdrawal() async {
        let succeeded = await viewModel.withdraw()
        if viewModel.showActiveGroupRestriction {
            showConfirmPopup = false
            return
        }
        guard succeeded else { return }

        showConfirmPopup = false
        TokenManager.shared.clear()
        container.navigationRouter.hardReset(to: .login)
    }
}

#Preview {
    AccountWithdrawalView(userService: UserService(interceptor: AuthInterceptor(authService: AuthService())))
        .environmentObject(DIContainer())
}
