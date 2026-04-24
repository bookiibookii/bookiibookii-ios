import Foundation
import SwiftUI
import Combine

@MainActor
final class GroupSearchViewModel: ObservableObject {

    enum Phase { case before, results }
    enum LoadPhase { case idle, loading, loadingMore, failed }

    @Published var searchText: String = ""

    @Published private(set) var phase: Phase = .before
    @Published private(set) var popularKeywords: [String] = []
    @Published var isPopularExpanded: Bool = false
    @Published private(set) var recentSearches: [String] = []

    @Published private(set) var searchResults: [GroupItemDto] = []
    @Published private(set) var resultCount: Int = 0
    @Published var resultSort: GroupSort = .latest
    @Published private(set) var loadPhase: LoadPhase = .idle
    @Published private(set) var hasNext: Bool = false
    @Published private(set) var currentPage: Int = 0

    @Published var toast: String? = nil

    private let service: GroupService
    private let historyManager: SearchHistoryManager

    var visiblePopularKeywords: [String] {
        isPopularExpanded ? popularKeywords : Array(popularKeywords.prefix(3))
    }

    init(service: GroupService) {
        self.service = service
        self.historyManager = SearchHistoryManager()
    }

    func onAppear() async {
        recentSearches = historyManager.load()
        await loadPopularKeywords()
    }

    func togglePopularExpanded() {
        withAnimation(.easeOut(duration: 0.2)) { isPopularExpanded.toggle() }
    }

    func removeRecentSearch(_ keyword: String) {
        historyManager.remove(keyword)
        recentSearches = historyManager.load()
    }

    func submitSearch(_ keyword: String) async {
        let trimmed = keyword.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        searchText = trimmed
        historyManager.add(trimmed)
        recentSearches = historyManager.load()
        phase = .results
        resultSort = .latest
        await loadFirstPage()
    }

    func changeResultSort(_ sort: GroupSort) async {
        guard sort != resultSort else { return }
        resultSort = sort
        await loadFirstPage()
    }

    func loadNextPage() async {
        guard hasNext, loadPhase == .idle else { return }
        loadPhase = .loadingMore
        do {
            let result = try await service.searchGroups(keyword: searchText, sort: resultSort, page: currentPage + 1)
            searchResults.append(contentsOf: result.groupList)
            currentPage = result.currentPage
            hasNext = result.hasNext
        } catch {
            toast = "추가 로드 실패"
        }
        loadPhase = .idle
    }

    func clearSearch() {
        searchText = ""
        phase = .before
        searchResults = []
        resultCount = 0
        hasNext = false
        currentPage = 0
        loadPhase = .idle
    }

    private func loadPopularKeywords() async {
        popularKeywords = (try? await service.fetchPopularKeywords()) ?? []
    }

    private func loadFirstPage() async {
        loadPhase = .loading
        searchResults = []
        do {
            let result = try await service.searchGroups(keyword: searchText, sort: resultSort, page: 0)
            searchResults = result.groupList
            resultCount = result.totalCount
            currentPage = result.currentPage
            hasNext = result.hasNext
            loadPhase = .idle
        } catch let e as GroupServiceError {
            loadPhase = .failed
            toast = e.errorDescription ?? "검색 실패"
        } catch {
            loadPhase = .failed
            toast = "검색 실패"
        }
    }
}
