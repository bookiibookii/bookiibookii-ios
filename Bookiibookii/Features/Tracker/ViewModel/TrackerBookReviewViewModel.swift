import SwiftUI
import Combine

@MainActor
final class TrackerBookReviewViewModel: ObservableObject {
    @Published var state = TrackerBookReviewUiState()

    private let groupId: Int
    private let isEdit: Bool   // true면 제출 시 PATCH(수정), false면 POST(작성)
    private let trackerService: TrackerService

    // 수정 모드에서 PATCH 대상 reviewId (프리필 때 reviews/book/me 로 확보)
    private var editReviewId: Int?

    init(groupId: Int, isEdit: Bool = false, trackerService: TrackerService) {
        self.groupId = groupId
        self.isEdit = isEdit
        self.trackerService = trackerService
    }

    func load() async {
        state.loading = true
        state.error = nil
        do {
            let dto = try await trackerService.fetchDetail(groupId: groupId)
            // EXCHANGE_REVIEW_WRITING은 파트너 책 후기, 그 외(REVIEW_WRITING)는 내 책
            let isPartnerReview = dto.displayStatus == "EXCHANGE_REVIEW_WRITING"
            let book = isPartnerReview ? dto.partnerBook : dto.myBook
            // 수정 모드면 화면에 표시 중인 책과 같은 책의 내 리뷰를 골라 프리필
            let myReview = isEdit ? await fetchMyBookReview(bookTitle: book?.title) : nil
            editReviewId = myReview?.reviewId
            state.bookTitle = book?.title ?? ""
            state.bookImageUrl = book?.image
            state.initialStar = myReview?.rating ?? 0
            state.initialComment = myReview?.content ?? ""
            state.loading = false
        } catch {
            state.error = "정보를 불러오지 못했어요"
            state.loading = false
        }
    }

    // 내 책 리뷰 목록 조회 후 표시 중인 책 제목과 일치하는 항목 1건 선별. 실패/없으면 nil.
    private func fetchMyBookReview(bookTitle: String?) async -> BookReviewItem? {
        guard let bookTitle, !bookTitle.isEmpty else { return nil }
        do {
            let res = try await trackerService.fetchMyBookReviews(groupId: groupId)
            return res.reviews?.first { $0.bookTitle == bookTitle }
        } catch {
            return nil
        }
    }

    func submitReview(star: Double, comment: String?, onSuccess: @escaping () -> Void) {
        // 더블탭 가드 — 제출 진행 중이면 중복 호출/중복 네비 차단
        if state.submitting { return }
        Task {
            state.submitting = true
            do {
                if isEdit {
                    guard let reviewId = editReviewId else {
                        state.submitting = false
                        return
                    }
                    _ = try await trackerService.updateBookReview(
                        groupId: groupId, reviewId: reviewId, star: star, comment: comment
                    )
                } else {
                    _ = try await trackerService.createBookReview(
                        groupId: groupId, star: star, comment: comment
                    )
                }
                state.submitting = false
                onSuccess()
            } catch {
                // 실패 시 무시 (에러 UI는 다음 단계에서)
                state.submitting = false
            }
        }
    }
}
