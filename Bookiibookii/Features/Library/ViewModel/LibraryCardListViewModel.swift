import Combine
import Foundation

@MainActor
final class LibraryCardListViewModel: ObservableObject {
    enum SortType {
        case latest
        case page
    }

    @Published private(set) var topComments: [LibraryTopComment] = []
    @Published private(set) var togetherComments: [LibraryTopComment] = []
    @Published private(set) var cards: [LibraryCard] = []
    @Published private(set) var isLoading = false
    @Published var sortType: SortType = .latest

    /// 함께읽기 메타: `GET /api/library/books` 에서 동일 `groupId` 책을 찾아 갱신.
    @Published private(set) var togetherMyReadingRate: Int?
    @Published private(set) var togetherGroupReadingRate: Int?
    @Published private(set) var togetherReadingCompletedAtISO: String?

    /// 후기 작성 후 라이브러리 응답에서 다시 받아온 책 별점(`rating`).
    /// `nil`이면 초기 `book.rating` 을 그대로 사용합니다.
    @Published private(set) var refreshedBookRating: Double?

    @Published var toastMessage: String?

    private let groupId: Int
    private let isTogetherGroup: Bool
    private let libraryService: LibraryService
    private let groupService: GroupService
    private let trackerService: TrackerService

    init(
        book: LibraryBook,
        libraryService: LibraryService,
        groupService: GroupService,
        trackerService: TrackerService
    ) {
        self.groupId = book.groupId
        self.isTogetherGroup = (book.groupType ?? "").uppercased() == "TOGETHER"
        self.libraryService = libraryService
        self.groupService = groupService
        self.trackerService = trackerService
        togetherMyReadingRate = book.togetherMyReadingRate
        togetherGroupReadingRate = book.togetherGroupReadingRate
        togetherReadingCompletedAtISO = book.togetherReadingCompletedAtISO

        // 서버 `/api/library/books`가 함께읽기 독서율/완독시각 필드를 아직 내려주지 않아,
        // 완독 결과를 로컬에 저장해두고 재진입 시 복원합니다.
        if isTogetherGroup, let cached = TogetherReadingLocalStore.snapshot(
            userId: TokenManager.shared.userId,
            groupId: groupId
        ) {
            if (togetherMyReadingRate ?? 0) < cached.readingRate {
                togetherMyReadingRate = cached.readingRate
            }
            if (togetherReadingCompletedAtISO ?? "").isEmpty {
                togetherReadingCompletedAtISO = cached.completedAtISO
            }
        }
    }

    /// 완독 처리 후에는 `후기 작성하기` 라벨로 전환 (또는 이미 100%인 경우 / 본인이 후기를 이미 남긴 경우).
    var togetherShowsReviewButton: Bool {
        if let iso = togetherReadingCompletedAtISO, !iso.isEmpty { return true }
        if (togetherMyReadingRate ?? 0) >= 100 { return true }
        // `/api/cards/group/{groupId}` 의 togetherComments에서 본인 후기가 이미 있으면 후기 단계로 진입.
        if let uid = TokenManager.shared.userId,
           togetherComments.contains(where: { $0.id == String(uid) && $0.hasWrittenComment }) {
            return true
        }
        return false
    }

    var cardCountText: String { "\(cards.count) 개" }
    var shouldShowTogetherReviewSummary: Bool {
        guard isTogetherGroup, togetherShowsReviewButton else { return false }
        guard let uid = TokenManager.shared.userId else { return false }
        return togetherComments.contains(where: { $0.id == String(uid) && $0.hasWrittenComment })
    } 
    var sortedCards: [LibraryCard] {
        switch sortType {
        case .latest:
            return cards.sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
        case .page:
            return cards.sorted { $0.page < $1.page }
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        if isTogetherGroup {
            // `TrackerCard`와 동일한 출처(`/api/groups/me/trackers`)에서 독서율을 받아옵니다.
            // 라이브러리 책 목록 응답에는 해당 필드가 없으므로 트래커 API를 사용합니다.
            await refreshTogetherRatesFromTrackers()
            // 라이브러리 응답은 (서버에 필드가 추가될 경우를 대비한) 폴백 경로로 유지합니다.
            await refreshTogetherSnapshotFromLibrary()
        }

        do {
            try await reloadCardsOnly()
        } catch {
            topComments = []
            cards = []
        }
    }

    /// `/api/groups/{groupId}/together/members/me/complete` 호출 후 상태를 동기화합니다.
    /// 서버 응답(`currentReadingRate`, `completedAt`)을 신뢰하고, 라이브러리 스냅샷이
    /// 빈 값으로 덮어쓰지 못하도록 호출하지 않습니다. 결과는 로컬에도 저장해 재진입 시 유지합니다.
    func confirmTogetherReadingFinished() async {
        do {
            let result = try await groupService.completeTogetherReading(groupId: groupId)
            let resolvedRate: Int = result.currentReadingRate ?? max(togetherMyReadingRate ?? 0, 100)
            let resolvedISO: String = {
                if let iso = result.completedAt, !iso.isEmpty { return iso }
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return formatter.string(from: Date())
            }()

            togetherMyReadingRate = resolvedRate
            togetherReadingCompletedAtISO = resolvedISO

            TogetherReadingLocalStore.save(
                userId: TokenManager.shared.userId,
                groupId: groupId,
                snapshot: .init(readingRate: resolvedRate, completedAtISO: resolvedISO)
            )

            // 그룹 평균 독서율도 갱신 (다른 멤버 진행률 변화 반영).
            await refreshTogetherRatesFromTrackers()
            try await reloadCardsOnly()
        } catch {
            toastMessage = error.localizedDescription
        }
    }

    private func reloadCardsOnly() async throws {
        let result = try await libraryService.fetchLibraryCards(groupId: groupId)
        topComments = result.topComments
        togetherComments = result.togetherComments
        cards = result.cards

        // 함께읽기에서 본인이 이미 후기를 남긴 상태라면(서버 영구 신호), 독서율 100%/완독 상태도
        // 동기화하고 로컬 캐시에 저장해 화면 재진입/캐시 초기화 후에도 일관되게 표시합니다.
        if isTogetherGroup,
           let uid = TokenManager.shared.userId,
           togetherComments.contains(where: { $0.id == String(uid) && $0.hasWrittenComment }) {
            togetherMyReadingRate = max(togetherMyReadingRate ?? 0, 100)
            if (togetherReadingCompletedAtISO ?? "").isEmpty {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                togetherReadingCompletedAtISO = formatter.string(from: Date())
            }
            TogetherReadingLocalStore.save(
                userId: uid,
                groupId: groupId,
                snapshot: .init(
                    readingRate: togetherMyReadingRate ?? 100,
                    completedAtISO: togetherReadingCompletedAtISO ?? ""
                )
            )
        }
    }

    /// (함께읽기 제거) 트래커 API에서 독서율을 받아오던 경로 — 트래커 전면 재작업으로 비활성화.
    private func refreshTogetherRatesFromTrackers() async {
        // 트래커 연동 제거됨: 별도 동작 없음.
    }

    /// 서버 라이브러리 응답에 함께읽기 독서율/완독시각 필드가 추가되면 자동으로 반영되도록
    /// 두지만, 현재는 응답에 해당 필드가 없으므로 nil로 덮어쓰지 않도록 가드합니다.
    /// `rating` 은 후기 작성 직후 갱신된 값을 받아오는 용도로 항상 반영합니다.
    private func refreshTogetherSnapshotFromLibrary() async {
        do {
            let books = try await libraryService.fetchLibraryBooks()
            guard let match = books.first(where: { $0.groupId == groupId }) else { return }
            if let rate = match.togetherMyReadingRate {
                togetherMyReadingRate = rate
            }
            if let groupRate = match.togetherGroupReadingRate {
                togetherGroupReadingRate = groupRate
            }
            if let iso = match.togetherReadingCompletedAtISO, !iso.isEmpty {
                togetherReadingCompletedAtISO = iso
            }
            if let rating = match.rating {
                refreshedBookRating = rating
            }
        } catch {}
    }

    func toggleBookmark(cardId: Int) async {
        guard let index = cards.firstIndex(where: { $0.id == cardId }) else { return }
        guard cards[index].isBookmarkable else { return }
        let previous = cards[index].isBookmarked
        let optimistic = !previous

        func replacingCard(at i: Int, bookmarked: Bool) -> [LibraryCard] {
            cards.enumerated().map { idx, card in
                guard idx == i else { return card }
                return LibraryCard(
                    id: card.id,
                    isBookmarkable: card.isBookmarkable,
                    bookTitle: card.bookTitle,
                    page: card.page,
                    memo: card.memo,
                    imageURL: card.imageURL,
                    creatorName: card.creatorName,
                    isBookmarked: bookmarked,
                    createdAt: card.createdAt,
                    messageCount: card.messageCount
                )
            }
        }

        cards = replacingCard(at: index, bookmarked: optimistic)

        do {
            let serverValue = try await libraryService.toggleLibraryCardBookmark(cardId: cardId)
            guard let idx = cards.firstIndex(where: { $0.id == cardId }) else { return }
            cards = replacingCard(at: idx, bookmarked: serverValue)
        } catch {
            guard let idx = cards.firstIndex(where: { $0.id == cardId }) else { return }
            cards = replacingCard(at: idx, bookmarked: previous)
        }
    }
}
