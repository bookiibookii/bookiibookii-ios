import Foundation
import Combine

// 안드로이드 TrkMainViewModel 대응.
// host/guest 리스트와 탭별 phase를 단일 VM에서 보유.
@MainActor
final class TrackerViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case loading
        case refreshing
        case failed(String)
        case loaded
    }

    @Published private(set) var hostItems: [TrackerItem] = []
    @Published private(set) var guestItems: [TrackerItem] = []
    @Published private(set) var hostPhase: Phase = .idle
    @Published private(set) var guestPhase: Phase = .idle
    @Published var selectedTab: TrackerTab = .myGroup
    @Published var toast: String? = nil
    @Published private(set) var isOpeningLibraryCards: Bool = false
    @Published var libraryBookToOpen: LibraryBook?

    private let service: TrackerService
    private let libraryService: LibraryService

    init(service: TrackerService, libraryService: LibraryService) {
        self.service = service
        self.libraryService = libraryService
    }

    // MARK: - 파생값

    var currentItems: [TrackerItem] {
        switch selectedTab {
        case .myGroup: return hostItems
        case .joined:  return guestItems
        }
    }

    var currentPhase: Phase {
        switch selectedTab {
        case .myGroup: return hostPhase
        case .joined:  return guestPhase
        }
    }

    // MARK: - 진입 / 탭 전환

    func onAppear() async {
        // 최초 진입 시 선택 탭만 로드. 이미 .loaded면 skip.
        await loadIfNeeded(tab: selectedTab)
    }

    func selectTab(_ tab: TrackerTab) async {
        guard tab != selectedTab else { return }
        selectedTab = tab
        await loadIfNeeded(tab: tab)
    }

    /// 함께읽기 그룹 카드 탭 → 안드 `getLibraryBooks()` + groupId 매칭으로 LibraryBook 획득.
    /// View가 onChange로 push 후 `libraryBookToOpen`을 nil로 리셋한다.
    func openLibraryCards(groupId: Int) async {
        guard !isOpeningLibraryCards else { return }
        isOpeningLibraryCards = true
        defer { isOpeningLibraryCards = false }
        do {
            let books = try await libraryService.fetchLibraryBooks()
            guard let match = books.first(where: { $0.groupId == groupId }) else {
                toast = "독서카드 정보를 찾을 수 없습니다."
                return
            }
            libraryBookToOpen = match
        } catch {
            toast = (error as? LocalizedError)?.errorDescription
                ?? "네트워크 오류, 다시 시도해주세요"
        }
    }

    func refresh() async {
        // SwiftUI .refreshable이 view 업데이트 도중 Task를 취소해서
        // URLSession.data(for:)가 -999(cancelled)로 끊기는 케이스가 있음.
        // detached Task로 분리해서 refreshable의 cancellation과 끊는다.
        let tab = selectedTab
        let task = Task.detached { [weak self] in
            await self?.reload(tab: tab, isRefresh: true)
        }
        _ = await task.value
    }

    // MARK: - Private

    private func loadIfNeeded(tab: TrackerTab) async {
        let phase: Phase
        switch tab {
        case .myGroup: phase = hostPhase
        case .joined:  phase = guestPhase
        }
        switch phase {
        case .idle, .failed:
            await reload(tab: tab, isRefresh: false)
        case .loading, .refreshing, .loaded:
            return
        }
    }

    private func reload(tab: TrackerTab, isRefresh: Bool) async {
        // 리프레시면 기존 리스트 유지 + phase만 변경, 초기 로드면 loading
        setPhase(tab: tab, phase: isRefresh ? .refreshing : .loading)
        do {
            let items: [TrackerItem]
            switch tab {
            case .myGroup: items = try await service.fetchHostTrackers()
            case .joined:  items = try await service.fetchGuestTrackers()
            }
            switch tab {
            case .myGroup: hostItems = items
            case .joined:  guestItems = items
            }
            setPhase(tab: tab, phase: .loaded)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? "불러오기에 실패했어요"
            setPhase(tab: tab, phase: .failed(message))
            // 기존 리스트가 있었다면 토스트로 알림 (리스트 자체는 유지)
            let hadItems: Bool = {
                switch tab {
                case .myGroup: return !hostItems.isEmpty
                case .joined:  return !guestItems.isEmpty
                }
            }()
            if hadItems {
                toast = message
            }
        }
    }

    private func setPhase(tab: TrackerTab, phase: Phase) {
        switch tab {
        case .myGroup: hostPhase = phase
        case .joined:  guestPhase = phase
        }
    }
}
