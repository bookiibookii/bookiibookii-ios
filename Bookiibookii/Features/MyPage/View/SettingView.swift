//
//  SettingView.swift
//  Bookiibookii
//
//  Created by 한태빈 on 4/24/26.
//

import SwiftUI

struct SettingView: View {
    @EnvironmentObject private var container: DIContainer
    @State private var isPushNotificationEnabled = false
    @State private var showLogoutPopup = false
    @State private var showWithdrawPopup = false

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                CustomNavigationBar(
                    title: "설정",
                    onBack: { container.navigationRouter.pop() },
                    rightButton: .none
                )

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        notificationSection
                        customerCenterSection
                        termsSection
                        versionSection
                        accountSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }

            if showLogoutPopup || showWithdrawPopup {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showLogoutPopup = false
                        showWithdrawPopup = false
                    }
            }

            if showLogoutPopup {
                LogoutPopupView(
                    onCancel: { showLogoutPopup = false },
                    onConfirm: {
                        showLogoutPopup = false
                        // TODO: 로그아웃 API 연결
                    }
                )
                .padding(.horizontal, 24)
            }

            if showWithdrawPopup {
                WithdrawPopupView(
                    onCancel: { showWithdrawPopup = false },
                    onConfirm: {
                        showWithdrawPopup = false
                        // TODO: 회원탈퇴 API 연결
                    }
                )
                .padding(.horizontal, 24)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("알림")
            card {
                HStack(spacing: 12) {
                    iconBadge(iconName: "bell")

                    VStack(alignment: .leading, spacing: 2) {
                        Text("푸시 알림 받기")
                            .font(.pretendard(size: 15, weight: .medium))
                            .foregroundColor(Color("grey900"))
                        Text("서비스 알림을 받습니다.")
                            .font(.pretendard(size: 12, weight: .regular))
                            .foregroundColor(Color("grey600"))
                    }

                    Spacer()

                    Toggle("", isOn: $isPushNotificationEnabled)
                        .labelsHidden()
                        .tint(Color("main200"))
                }
            }
        }
    }

    private var customerCenterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("고객센터")
            Button {
                container.navigationRouter.push(to: .notice)
            } label: {
                settingRow(
                    iconName: "bell",
                    title: "공지사항",
                    subtitle: "새로운 소식을 확인하세요!"
                )
            }
            .buttonStyle(.plain)
            Button {
                container.navigationRouter.push(to: .questoin)
            } label: {
                settingRow(
                    iconName: "chat",
                    title: "문의하기",
                    subtitle: "서비스 관련 문의는 여기서!"
                )
            }
            .buttonStyle(.plain)
            settingRow(
                iconName: "info",
                title: "신고하기",
                subtitle: "악성 유저를 신고해주세요!"
            )
        }
    }

    private var termsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("이용 약관")
            plainRow("서비스 이용 약관")
            plainRow("개인정보 처리방침")
        }
    }

    private var versionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("버전 정보")
            plainRow("v1.0.0")
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("계정관리")
            Button {
                showLogoutPopup = true
                showWithdrawPopup = false
            } label: {
                actionRow("로그아웃", color: Color("grey900"))
            }
            .buttonStyle(.plain)

            Button {
                showWithdrawPopup = true
                showLogoutPopup = false
            } label: {
                actionRow("회원 탈퇴", color: Color(red: 1.0, green: 0.302, blue: 0.302))
            }
            .buttonStyle(.plain)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.pretendard(size: 16, weight: .medium))
            .foregroundColor(Color("grey900"))
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("white"))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color("grey100"), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func iconBadge(iconName: String) -> some View {
        ZStack {
            Circle()
                .fill(Color("grey100"))
                .frame(width: 40, height: 40)
            Image(iconName)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
        }
    }

    private func settingRow(iconName: String, title: String, subtitle: String) -> some View {
        card {
            HStack(spacing: 12) {
                iconBadge(iconName: iconName)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.pretendard(size: 15, weight: .medium))
                        .foregroundColor(Color("grey900"))
                    Text(subtitle)
                        .font(.pretendard(size: 12, weight: .regular))
                        .foregroundColor(Color("grey600"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("grey700"))
            }
        }
    }

    private func plainRow(_ text: String) -> some View {
        card {
            Text(text)
                .font(.pretendard(size: 15, weight: .regular))
                .foregroundColor(Color("grey600"))
        }
    }

    private func actionRow(_ text: String, color: Color) -> some View {
        card {
            Text(text)
                .font(.pretendard(size: 15, weight: .medium))
                .foregroundColor(color)
        }
    }
}

#Preview {
    SettingView()
        .environmentObject(DIContainer())
}
