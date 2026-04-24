import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    enum GroupPhase: Equatable {
        case idle
        case loading
        case loaded
        case failed
    }

    @Published private(set) var recommendedGroups: [RecommendedGroupDto] = []
    @Published private(set) var groupPhase: GroupPhase = .idle

    @Published private(set) var recommendedBookmates: [RecommendedBookmateDto] = []
    @Published private(set) var matePhase: GroupPhase = .idle

    private let recommendationService: RecommendationService
    private var didLoadInitial = false

    init(recommendationService: RecommendationService) {
        self.recommendationService = recommendationService
    }

    /// 홈 진입 최초 1회 로드 (그룹 + 부키메이트 병렬).
    func onAppear() async {
        guard !didLoadInitial else { return }
        didLoadInitial = true
        async let groups: Void = loadRecommendedGroups(refresh: false)
        async let mates: Void = loadRecommendedBookmates()
        _ = await (groups, mates)
    }

    /// 그룹 섹션 새로고침 버튼 탭.
    func refreshRecommendedGroups() async {
        await loadRecommendedGroups(refresh: true)
    }

    private func loadRecommendedGroups(refresh: Bool) async {
        groupPhase = .loading
        do {
            let list = try await recommendationService.fetchRecommendedGroups(refresh: refresh)
            recommendedGroups = list
            groupPhase = .loaded
        } catch {
            recommendedGroups = []
            groupPhase = .failed
        }
    }

    private func loadRecommendedBookmates() async {
        matePhase = .loading
        do {
            let list = try await recommendationService.fetchRecommendedBookmates()
            recommendedBookmates = Array(list.prefix(5))
            matePhase = .loaded
        } catch {
            recommendedBookmates = []
            matePhase = .failed
        }
    }
}
