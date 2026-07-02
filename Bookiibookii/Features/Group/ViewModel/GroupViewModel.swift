import Foundation
import SwiftUI
import Combine

// 안드 GroupSearchViewModel 이식. 한 화면에서 필터모드↔검색모드 전환.
// - searchKeyword 비어있음 = 필터 모드 (GET /api/groups)
// - searchKeyword 있음     = 검색 모드 (GET /api/groups/search)
@MainActor
final class GroupViewModel: ObservableObject {

    enum LoadPhase { case idle, loading, loadingMore, failed }

    // 검색
    @Published var searchText: String = ""            // 검색바 입력값(제출 전 포함)
    @Published private(set) var searchKeyword: String = ""  // 제출되어 현재 결과를 만든 검색어

    // 필터 (검색 모드에선 비움). 비어있으면 전체
    @Published private(set) var tradeTypes: [String] = []   // DIRECT / DELIVERY
    @Published private(set) var regions: [String] = []
    @Published private(set) var categories: [String] = []   // 예: KOREAN_NOVEL

    // 리스트 상태
    @Published private(set) var items: [GroupItemDto] = []
    @Published private(set) var totalCount: Int? = nil
    @Published private(set) var currentPage: Int = 0
    @Published private(set) var hasNext: Bool = false
    @Published private(set) var loadPhase: LoadPhase = .idle
    @Published private(set) var loadingMore: Bool = false
    @Published private(set) var errorMessage: String? = nil

    @Published var toast: String? = nil

    private let service: GroupService
    private let sort: GroupSort = .latest        // 안드: 정렬 UI 없음, LATEST 고정
    private let pageSize: Int = 10
    private var didLoad = false

    var isSearchMode: Bool { !searchKeyword.trimmingCharacters(in: .whitespaces).isEmpty }

    init(service: GroupService, initialKeyword: String? = nil) {
        self.service = service
        if let kw = initialKeyword?.trimmingCharacters(in: .whitespaces), !kw.isEmpty {
            self.searchText = kw
            self.searchKeyword = kw
        }
    }

    // 최초 등장 시 1회 로드
    func onAppear() async {
        guard !didLoad else { return }
        didLoad = true
        await load()
    }

    // 검색바 입력 변경(제출 전이라 API 호출 안 함)
    func onQueryChange(_ value: String) { searchText = value }

    // 검색 제출. 빈 검색어면 검색 해제 → 필터(전체) 목록, 아니면 필터 초기화 후 검색.
    // totalCount는 비우지 않음(헤더 깜빡임 방지)
    func onSearch() async {
        let keyword = searchText.trimmingCharacters(in: .whitespaces)
        if keyword.isEmpty {
            searchKeyword = ""
        } else {
            searchKeyword = keyword
            tradeTypes = []
            regions = []
            categories = []
        }
        await load()
    }

    // 필터 변경 → 검색 해제 후 첫 페이지부터 재조회
    func applyTradeTypes(_ next: [String]) async {
        tradeTypes = next; searchText = ""; searchKeyword = ""
        await load()
    }
    func applyRegions(_ next: [String]) async {
        regions = next; searchText = ""; searchKeyword = ""
        await load()
    }
    func applyCategories(_ next: [String]) async {
        categories = next; searchText = ""; searchKeyword = ""
        await load()
    }

    func retry() async { await load() }

    // 첫 페이지 로드
    private func load() async {
        loadPhase = .loading
        errorMessage = nil
        do {
            if searchKeyword.isEmpty {
                let r = try await service.fetchGroups(
                    tradeTypes: tradeTypes.isEmpty ? nil : tradeTypes,
                    regions: regions.isEmpty ? nil : regions,
                    categories: categories.isEmpty ? nil : categories,
                    sort: sort, page: 0, size: pageSize
                )
                items = r.groupList ?? []
                currentPage = r.currentPage
                hasNext = r.hasNext
                totalCount = r.totalCount
            } else {
                let r = try await service.searchGroups(keyword: searchKeyword, sort: sort, page: 0, size: pageSize)
                items = r.groupList
                currentPage = r.currentPage
                hasNext = r.hasNext
                totalCount = r.totalCount
            }
            loadPhase = .idle
        } catch is CancellationError {
            loadPhase = .idle
        } catch let e as URLError where e.code == .cancelled {
            loadPhase = .idle
        } catch let e as GroupServiceError {
            loadPhase = .failed
            errorMessage = searchKeyword.isEmpty ? "목록을 불러오지 못했어요" : "검색에 실패했어요"
            #if DEBUG
            print("‼️ [GroupVM] service error:", e)
            #endif
        } catch {
            loadPhase = .failed
            errorMessage = "네트워크 오류가 발생했어요"
            #if DEBUG
            print("‼️ [GroupVM] load failed:", type(of: error), "→", error)
            #endif
        }
    }

    // 다음 페이지 이어붙이기(무한 스크롤). 실패는 조용히 멈춤
    func loadMore() async {
        // 안드 loadMore 가드와 동일: 첫 페이지 로딩 중이 아니고 추가 로딩 중이 아닐 때 (실패 상태에서도 재개 가능)
        guard hasNext, loadPhase != .loading, !loadingMore else { return }
        loadingMore = true
        let nextPage = currentPage + 1
        do {
            if searchKeyword.isEmpty {
                let r = try await service.fetchGroups(
                    tradeTypes: tradeTypes.isEmpty ? nil : tradeTypes,
                    regions: regions.isEmpty ? nil : regions,
                    categories: categories.isEmpty ? nil : categories,
                    sort: sort, page: nextPage, size: pageSize
                )
                items += (r.groupList ?? [])
                currentPage = r.currentPage
                hasNext = r.hasNext
            } else {
                let r = try await service.searchGroups(keyword: searchKeyword, sort: sort, page: nextPage, size: pageSize)
                items += r.groupList
                currentPage = r.currentPage
                hasNext = r.hasNext
            }
        } catch {
            // 조용히 멈춤(기존 목록 유지)
        }
        loadingMore = false
    }
}
