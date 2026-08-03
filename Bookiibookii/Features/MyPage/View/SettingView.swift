import SwiftUI

struct SettingView: View {
    @EnvironmentObject private var container: DIContainer

    @State private var isPushNotificationEnabled = PushNotificationManager.shared.isPushEnabled
    @State private var showPushPermissionAlert = false
    @State private var showLogoutPopup = false
    @State private var isProcessingLogout = false
    @State private var accountErrorMessage: String?

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return "v\(version)"
    }

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        notificationSection
                        customerCenterSection
                        termsSection
                        versionSection
                        accountSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }

            if showLogoutPopup {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture {
                        guard !isProcessingLogout else { return }
                        showLogoutPopup = false
                    }

                LogoutPopupView(
                    onCancel: {
                        guard !isProcessingLogout else { return }
                        showLogoutPopup = false
                    },
                    onConfirm: {
                        Task { await performLogout() }
                    }
                )
                .padding(.horizontal, 20)
            }

            if isProcessingLogout {
                Color.black.opacity(0.15).ignoresSafeArea()
                ProgressView()
            }
        }
        .alert("안내", isPresented: Binding(
            get: { accountErrorMessage != nil },
            set: { if !$0 { accountErrorMessage = nil } }
        )) {
            Button("확인", role: .cancel) { accountErrorMessage = nil }
        } message: {
            Text(accountErrorMessage ?? "")
        }
        .alert("알림 권한이 꺼져 있어요", isPresented: $showPushPermissionAlert) {
            Button("설정으로 이동") { openSystemSettings() }
            Button("취소", role: .cancel) {}
        } message: {
            Text("iOS 설정에서 부키부키 알림을 허용해야 푸시 알림을 받을 수 있어요.")
        }
        // OS에서 알림을 꺼둔 채 돌아온 경우, 토글이 켜져 보이는 것을 막는다
        .task {
            await PushNotificationManager.shared.syncWithSystemPermission()
            isPushNotificationEnabled = PushNotificationManager.shared.isPushEnabled
        }
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

            Text("설정")
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

    // MARK: - Sections

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("알림")

            settingCard(verticalPadding: 12) {
                HStack(spacing: 12) {
                    settingIcon("ic_alert_32")

                    VStack(alignment: .leading, spacing: 2) {
                        Text("푸시 알림 설정")
                            .pretendardText(size: 16, weight: .medium)
                            .foregroundColor(Color("grey900"))
                        Text("서비스 알림을 받습니다.")
                            .pretendardText(size: 12, weight: .regular)
                            .foregroundColor(Color("grey600"))
                    }

                    Spacer(minLength: 8)

                    Toggle("", isOn: $isPushNotificationEnabled)
                        .labelsHidden()
                        .tint(Color("main200"))
                        .onChange(of: isPushNotificationEnabled) { _, enabled in
                            Task {
                                // 이미 거절한 상태에서는 시스템 팝업이 다시 뜨지 않으므로 설정 앱으로 안내한다
                                if enabled, await PushNotificationManager.shared.systemPermission() == .denied {
                                    showPushPermissionAlert = true
                                    isPushNotificationEnabled = false
                                    return
                                }
                                await PushNotificationManager.shared.setPushEnabled(enabled)
                                isPushNotificationEnabled = PushNotificationManager.shared.isPushEnabled
                            }
                        }
                }
            }
        }
    }

    private var customerCenterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("고객센터")

            Button {
                container.navigationRouter.push(to: .notice)
            } label: {
                navigationRow(
                    iconName: "ic_alert_32",
                    title: "공지사항",
                    subtitle: "부키부키의 새로운 소식을 확인하세요!"
                )
            }
            .buttonStyle(.plain)

            Button {
                container.navigationRouter.push(to: .faq)
            } label: {
                navigationRow(
                    iconName: "ic_info",
                    title: "자주 묻는 질문 / 신고하기",
                    subtitle: "문의 또는 불편사항이 있으신가요?"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var termsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("이용 약관")

            Button {
                container.navigationRouter.push(to: .legalDocument(.termsOfService))
            } label: {
                chevronRow("서비스 이용 약관")
            }
            .buttonStyle(.plain)

            Button {
                container.navigationRouter.push(to: .legalDocument(.privacyPolicy))
            } label: {
                chevronRow("개인정보 처리 방침")
            }
            .buttonStyle(.plain)
        }
    }

    private var versionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("버전 정보")

            settingCard {
                Text(appVersion)
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey500"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("계정 관리")

            Button {
                showLogoutPopup = true
            } label: {
                settingCard {
                    Text("로그아웃")
                        .pretendardText(size: 16, weight: .medium)
                        .foregroundColor(Color("grey900"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)
            .disabled(isProcessingLogout)

            Button {
                container.navigationRouter.push(to: .accountWithdrawal)
            } label: {
                settingCard {
                    Text("회원 탈퇴")
                        .pretendardText(size: 16, weight: .medium)
                        .foregroundColor(Color("pointRed"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)
            .disabled(isProcessingLogout)
        }
    }

    // MARK: - Components

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .pretendardText(size: 16, weight: .semibold)
            .foregroundColor(Color("grey900"))
    }

    private func settingCard<Content: View>(
        verticalPadding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("white"))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color("grey100"), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func settingIcon(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
    }

    private func navigationRow(iconName: String, title: String, subtitle: String) -> some View {
        settingCard(verticalPadding: 12) {
            HStack(spacing: 12) {
                settingIcon(iconName)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .pretendardText(size: 16, weight: .medium)
                        .foregroundColor(Color("grey900"))
                    Text(subtitle)
                        .pretendardText(size: 12, weight: .regular)
                        .foregroundColor(Color("grey600"))
                }

                Spacer(minLength: 8)

                Image("ic_chevron_r")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
        }
    }

    private func chevronRow(_ title: String) -> some View {
        settingCard {
            HStack {
                Text(title)
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey900"))

                Spacer(minLength: 8)

                Image("ic_chevron_r")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
        }
    }

    // MARK: - Account Actions

    private func performLogout() async {
        isProcessingLogout = true
        defer { isProcessingLogout = false }

        await PushNotificationManager.shared.deactivateOnLogout()

        if let token = TokenManager.shared.accessToken {
            await container.api.auth.logout(accessToken: token)
        }
        TokenManager.shared.clear()
        showLogoutPopup = false
        container.navigationRouter.hardReset(to: .login)
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    SettingView()
        .environmentObject(DIContainer())
}
