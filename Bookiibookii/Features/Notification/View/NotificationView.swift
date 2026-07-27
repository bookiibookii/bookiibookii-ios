import SwiftUI

// 안드로이드 NotificationScreen + Figma HOM-02-01 대응
// 상단 네비 + 탭(시스템/키워드) + 리스트(무한스크롤).
// + → 키워드 알림 설정. 키워드 알림(KEYWORD_GROUP_CREATED)만 그룹 상세 이동.
struct NotificationView: View {
    @EnvironmentObject private var container: DIContainer

    @StateObject private var systemVM: NotificationViewModel
    @StateObject private var keywordVM: NotificationViewModel

    @State private var selectedTab: NotificationCategory = .system
    @State private var showKeywordSetting = false
    @State private var selectedGroupId: Int? = nil
    @State private var toast: ToastMessage? = nil

    private let keywordService: KeywordService
    private let groupService: GroupService

    init(
        notificationService: NotificationService,
        keywordService: KeywordService,
        groupService: GroupService
    ) {
        _systemVM = StateObject(wrappedValue: NotificationViewModel(service: notificationService, category: .system))
        _keywordVM = StateObject(wrappedValue: NotificationViewModel(service: notificationService, category: .keyword))
        self.keywordService = keywordService
        self.groupService = groupService
    }

    var body: some View {
        VStack(spacing: 0) {
            navBar
            tabBar
            contentArea
        }
        .background(Color("uiBg").ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task {
            await systemVM.loadFirstPage()
            await keywordVM.loadFirstPage()
        }
        .fullScreenCover(isPresented: $showKeywordSetting) {
            KeywordSettingView(keywordService: keywordService)
        }
        .fullScreenCover(item: $selectedGroupId) { groupId in
            GroupDetailView(groupId: groupId, groupService: groupService)
        }
        .toast($toast)
    }

    // MARK: - 네비게이션 바

    private var navBar: some View {
        HStack(alignment: .center, spacing: 0) {
            Button { container.navigationRouter.pop() } label: {
                Image("ic_back")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("알림")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))

            Spacer()

            Button { showKeywordSetting = true } label: {
                Image("ic_plus_32")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color("grey200")).frame(height: 1)
        }
    }

    // MARK: - 탭

    private var tabBar: some View {
        HStack(spacing: 12) {
            tabButton(title: "시스템 알림", category: .system)
            tabButton(title: "키워드 알림", category: .keyword)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color("uiBg"))
    }

    private func tabButton(title: String, category: NotificationCategory) -> some View {
        let isSelected = selectedTab == category
        return Button {
            selectedTab = category
        } label: {
            Text(title)
                .pretendardText(size: 16, weight: .regular)
                .foregroundColor(isSelected ? Color("white") : Color("grey900"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(isSelected ? Color("main200") : Color("white"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(isSelected ? Color.clear : Color("grey200"), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 탭 처리

    private func handleTap(vm: NotificationViewModel, item: NotificationItemDto) {
        Task { await vm.markAsRead(item.id) }

        if let redirect = NotificationRedirectRouter.fromPayload(item.payload) {
            NotificationRedirectDispatcher.dispatch(redirect, router: container.navigationRouter)
            return
        }

        // redirectType이 없는 구형 KEYWORD 알림 폴백
        if item.type == "KEYWORD_GROUP_CREATED", let groupId = item.payload?.groupId {
            selectedGroupId = groupId
        }
    }

    @ViewBuilder
    private var contentArea: some View {
        let vm = selectedTab == .system ? systemVM : keywordVM
        if vm.phase == .loading && vm.items.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if vm.items.isEmpty {
            ScrollView {
                NotificationEmptyCard()
                    .padding(.horizontal, 16)
                    .padding(.top, 0)
                    .padding(.bottom, 16)
            }
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(Array(vm.items.enumerated()), id: \.element.id) { idx, item in
                        NotificationCard(item: item, bookTitle: item.payload?.bookTitle ?? "") {
                            handleTap(vm: vm, item: item)
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
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }
}
