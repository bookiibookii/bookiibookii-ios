import Foundation
import SwiftUI
import Combine

/// 교환독서 후기 작성 화면 상태 + 제출 로직.
/// 안드 LibraryBookDetailRelayWriteFragment 대응.
@MainActor
final class ReviewWriteViewModel: ObservableObject {
    // MARK: - Inputs (groupId만 받고 userBookId/책 메타는 서버에서 도출)
    let groupId: Int

    // MARK: - 헤더 카드 정보 (group detail)
    @Published private(set) var bookTitle: String = ""
    @Published private(set) var bookAuthor: String = ""
    @Published private(set) var bookImageUrl: String? = nil
    @Published private(set) var hostNickname: String = ""
    @Published private(set) var hostProfileImageUrl: String? = nil
    @Published private(set) var startDate: String? = nil
    @Published private(set) var partnerName: String = "상대방"

    // MARK: - 입력 상태
    @Published var bookRating: Double = 0       // 0.5 단위, 0~5
    @Published var partnerRating: Double = 0    // 0.5 단위, 0~5
    @Published var bookComment: String = ""
    @Published var partnerComment: String = ""
    @Published var selectedBadgeIds: Set<String> = []

    // MARK: - 비동기 상태
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isSubmitting: Bool = false
    @Published private(set) var isSubmitted: Bool = false
    @Published var toastMessage: String? = nil

    private(set) var userBookId: Int? = nil

    private let groupService: GroupService
    private let libraryService: LibraryService

    init(
        groupId: Int,
        groupService: GroupService,
        libraryService: LibraryService
    ) {
        self.groupId = groupId
        self.groupService = groupService
        self.libraryService = libraryService
    }

    #if DEBUG
    /// SwiftUI preview 전용 — 네트워크 없이 화면에 기본 값을 채워준다.
    static func preview(
        bookTitle: String = "괴테는 모든 것을 말했다.",
        bookAuthor: String = "스즈키 유이 (소설)",
        hostNickname: String = "noshel",
        partnerName: String = "별빛"
    ) -> ReviewWriteViewModel {
        let vm = ReviewWriteViewModel(
            groupId: 0,
            groupService: GroupService(interceptor: AuthInterceptor(authService: AuthService())),
            libraryService: LibraryService(interceptor: AuthInterceptor(authService: AuthService()))
        )
        vm.bookTitle = bookTitle
        vm.bookAuthor = bookAuthor
        vm.hostNickname = hostNickname
        vm.partnerName = partnerName
        vm.startDate = "2025-12-18"
        return vm
    }
    #endif

    // MARK: - 별점 토글
    /// 안드 setupStarRating: 같은 인덱스의 half가 이미 켜져 있으면 full, 아니면 half로 토글.
    func tapBookStar(index: Int) {
        guard !isSubmitted else { return }
        bookRating = nextRating(current: bookRating, index: index)
    }

    func tapPartnerStar(index: Int) {
        guard !isSubmitted else { return }
        partnerRating = nextRating(current: partnerRating, index: index)
    }

    private func nextRating(current: Double, index: Int) -> Double {
        let half = Double(index) + 0.5
        let full = Double(index) + 1.0
        return current == half ? full : half
    }

    // MARK: - 태그
    func toggleBadge(_ badge: ReviewBadge) {
        guard !isSubmitted else { return }
        if selectedBadgeIds.contains(badge.id) {
            selectedBadgeIds.remove(badge.id)
        } else {
            selectedBadgeIds.insert(badge.id)
        }
    }

    // MARK: - 제출 가능 여부
    var canSubmit: Bool {
        !isSubmitting
            && !isSubmitted
            && bookRating > 0
            && partnerRating > 0
            && !selectedBadgeIds.isEmpty
    }

    // MARK: - 초기 데이터 로드
    /// 그룹 상세 + 라이브러리 책 목록을 병렬 호출해
    /// 책/파트너 정보, userBookId를 한번에 채운다.
    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        async let detailTask: GroupDetailDto? = try? groupService.fetchGroupDetail(groupId: groupId)
        async let booksTask: [LibraryBook] = (try? libraryService.fetchLibraryBooks()) ?? []

        let detail = await detailTask
        let books = await booksTask

        if let detail {
            applyDetail(detail)
        }
        userBookId = books.first(where: { $0.groupId == groupId })?.userBookId
    }

    private func applyDetail(_ data: GroupDetailDto) {
        bookTitle = data.bookTitle
        bookAuthor = data.author
        bookImageUrl = data.bookImage
        hostNickname = data.hostNickname
        hostProfileImageUrl = data.hostProfileImageUrl
        startDate = data.startDate
        partnerName = data.participantSlots?.first(where: { !$0.isMe })?.nickname ?? "상대방"
    }

    // MARK: - 제출
    func submit() async -> Bool {
        guard canSubmit, let userBookId else {
            if userBookId == nil {
                toastMessage = "해당 그룹의 책 정보를 찾을 수 없습니다."
            }
            return false
        }
        isSubmitting = true
        defer { isSubmitting = false }

        let body = RelayReviewRequestBody(
            bookRating: bookRating,
            bookComment: bookComment,
            partnerRating: partnerRating,
            partnerComment: partnerComment,
            badgeCodes: Array(selectedBadgeIds)
        )

        do {
            try await libraryService.submitRelayReview(userBookId: userBookId, body: body)
            isSubmitted = true
            toastMessage = "리뷰 작성이 완료되었습니다."
            return true
        } catch {
            toastMessage = (error as? LocalizedError)?.errorDescription ?? "네트워크 오류가 발생했습니다."
            return false
        }
    }
}
