import SwiftUI

// 안드로이드 NotificationActivity + System/Keyword Fragment 대응
// 상단 네비 + 탭 세그먼트(시스템/키워드) + 리스트(무한스크롤).
// 탭 시 읽음 처리(PATCH /api/notifications/{id}/read)만 수행. 이동 처리는 후속 작업.
struct NotificationView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var systemVM: NotificationViewModel
    @StateObject private var keywordVM: NotificationViewModel

    @State private var selectedTab: NotificationCategory = .system

    init(notificationService: NotificationService) {
        _systemVM = StateObject(wrappedValue: NotificationViewModel(service: notificationService, category: .system))
        _keywordVM = StateObject(wrappedValue: NotificationViewModel(service: notificationService, category: .keyword))
    }

    var body: some View {
        VStack(spacing: 0) {
            navBar
            Divider().background(Color("grey200"))
            tabBar
            contentArea
        }
        .background(Color("grey100").ignoresSafeArea())
        .task {
            await systemVM.loadFirstPage()
            await keywordVM.loadFirstPage()
        }
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
            Text("알림")
                .font(.pretendard(size: 20, weight: .medium))
                .foregroundColor(Color("grey900"))
            Spacer()

            // TODO: 키워드 설정 화면 (NotificationKeywordSettingActivity 대응) — 후속
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color("white"))
    }

    // MARK: - 탭

    private var tabBar: some View {
        HStack(spacing: 10) {
            tabButton(title: "시스템 알림", category: .system)
            tabButton(title: "키워드 알림", category: .keyword)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(Color("grey100"))
    }

    private func tabButton(title: String, category: NotificationCategory) -> some View {
        let isSelected = selectedTab == category
        return Button {
            selectedTab = category
        } label: {
            Text(title)
                .font(.pretendard(size: 14, weight: .medium))
                .foregroundColor(isSelected ? Color("white") : Color("grey900"))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color("grey900") : Color("white"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.clear : Color("grey200"), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 콘텐츠

    @ViewBuilder
    private var contentArea: some View {
        let vm = selectedTab == .system ? systemVM : keywordVM
        if vm.phase == .loading && vm.items.isEmpty {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if vm.items.isEmpty {
            ScrollView { NotificationEmptyCard().padding(20) }
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(Array(vm.items.enumerated()), id: \.element.id) { idx, item in
                        NotificationCard(item: item, bookTitle: "") {
                            Task { await vm.markAsRead(item.id) }
                        }
                        .onAppear {
                            if idx >= vm.items.count - 3 {
                                Task { await vm.loadNextPageIfNeeded() }
                            }
                        }
                    }
                    if vm.isLoadingMore {
                        ProgressView().padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
    }
}
