import Foundation
import SwiftUI
import Combine

@MainActor
final class GroupViewModel: ObservableObject {
    // MARK: - 필터 상태 (빈 컬렉션 == 전체)
    @Published var groupTypes: Set<GroupTypeFilter> = []
    @Published var categories: Set<CategoryFilter> = []
    @Published var region: RegionSelection = .all
    @Published var sort: GroupSort = .recommend

    // MARK: - 리스트 상태
    @Published private(set) var items: [GroupItemDto] = []
    @Published private(set) var page: Int = 0
    @Published private(set) var hasNext: Bool = false
    @Published private(set) var phase: Phase = .idle

    @Published var toast: String? = nil

    enum Phase { case idle, loading, loadingMore, refreshing, failed }

    private let service: GroupService
    private let pageSize: Int = 20

    init(service: GroupService) {
        self.service = service
    }

    // MARK: - 엔트리 포인트

    /// 화면 최초 등장 시 호출. 이미 로드된 상태면 무시.
    func onAppear() async {
        guard items.isEmpty && phase == .idle else { return }
        await loadFirstPage(phase: .loading)
    }

    /// Pull-to-refresh
    func refresh() async {
        await loadFirstPage(phase: .refreshing)
    }

    /// 필터/정렬 변경 시 내부 호출
    private func reload() async {
        await loadFirstPage(phase: .loading)
    }

    /// 무한 스크롤 (마지막 셀 `.onAppear`에서 호출)
    func loadNextPage() async {
        guard hasNext, phase == .idle else { return }
        phase = .loadingMore
        do {
            let result = try await fetch(page: page + 1)
            items.append(contentsOf: result.groupList ?? [])
            page = result.currentPage
            hasNext = result.hasNext
            phase = .idle
        } catch {
            phase = .idle   // 복구 가능하도록 idle로 복귀
            toast = "추가 로드 실패"
        }
    }

    // MARK: - 필터/정렬 적용

    func applyGroupTypes(_ next: Set<GroupTypeFilter>) async {
        guard next != groupTypes else { return }
        groupTypes = next
        await reload()
    }

    func applyCategories(_ next: Set<CategoryFilter>) async {
        guard next != categories else { return }
        categories = next
        await reload()
    }

    func applyRegion(_ next: RegionSelection) async {
        guard next != region else { return }
        region = next
        await reload()
    }

    func changeSort(_ next: GroupSort) async {
        guard next != sort else { return }
        sort = next
        await reload()
    }

    // MARK: - placeholder

    func showComingSoon(_ label: String = "준비 중입니다") {
        toast = label
    }

    // MARK: - 내부 로드 로직

    private func loadFirstPage(phase startPhase: Phase) async {
        phase = startPhase
        do {
            let result = try await fetch(page: 0)
            items = result.groupList ?? []
            page = result.currentPage
            hasNext = result.hasNext
            phase = .idle
        } catch is CancellationError {
            phase = .idle
        } catch let urlError as URLError where urlError.code == .cancelled {
            phase = .idle
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet {
            phase = .failed
            toast = "네트워크 연결을 확인해주세요"
        } catch let serviceError as GroupServiceError {
            phase = .failed
            toast = serviceError.errorDescription ?? "불러오기 실패"
        } catch {
            phase = .failed
            toast = error.localizedDescription
        }
    }

    private func fetch(page: Int) async throws -> GroupPageResult {
        try await service.fetchGroups(
            groupTypes: queryGroupTypes(),
            tradeTypes: queryTradeTypes(),
            meetPlace: region.serverMeetPlace,
            categories: queryCategories(),
            sort: sort,
            page: page,
            size: pageSize
        )
    }

    // MARK: - 쿼리 빌드 (안드로이드 loadGroupData 그대로)

    private func queryGroupTypes() -> [String]? {
        if groupTypes.isEmpty { return nil }
        var types = Set<String>()
        if groupTypes.contains(.together) { types.insert("TOGETHER") }
        if groupTypes.contains(.delivery) || groupTypes.contains(.direct) { types.insert("RELAY") }
        return types.isEmpty ? nil : Array(types)
    }

    private func queryTradeTypes() -> [String]? {
        var types: [String] = []
        if groupTypes.contains(.delivery) { types.append("DELIVERY") }
        if groupTypes.contains(.direct)   { types.append("DIRECT") }
        return types.isEmpty ? nil : types
    }

    private func queryCategories() -> [String]? {
        categories.isEmpty ? nil : categories.map(\.rawValue)
    }
}
