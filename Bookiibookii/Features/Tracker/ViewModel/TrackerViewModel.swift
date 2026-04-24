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

    private let service: TrackerService

    init(service: TrackerService) {
        self.service = service
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

    func refresh() async {
        await reload(tab: selectedTab, isRefresh: true)
    }

    // MARK: - Private

    private func loadIfNeeded(tab: TrackerTab) async {
        let phase: Phase
        switch tab {
        case .myGroup: phase = hostPhase
        case .joined:  phase = guestPhase
        }
        if case .loaded = phase { return }
        await reload(tab: tab, isRefresh: false)
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
