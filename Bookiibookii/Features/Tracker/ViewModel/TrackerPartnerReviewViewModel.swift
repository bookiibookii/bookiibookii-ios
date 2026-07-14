import SwiftUI
import Combine

@MainActor
final class TrackerPartnerReviewViewModel: ObservableObject {
    @Published var state = TrackerPartnerReviewUiState()

    private let groupId: Int
    private let trackerService: TrackerService

    init(groupId: Int, trackerService: TrackerService) {
        self.groupId = groupId
        self.trackerService = trackerService
    }

    func load() async {
        state.loading = true
        state.error = nil
        do {
            let dto = try await trackerService.fetchDetail(groupId: groupId)
            state.groupName = dto.groupName ?? ""
            state.myNickname = dto.myBook?.currentReaderNickname ?? ""
            state.myBookTitle = dto.myBook?.title ?? ""
            state.myBookCoverUrl = dto.myBook?.image
            state.myProfileImageUrl = dto.myBook?.currentReaderProfileImageUrl
            state.partnerNickname = dto.partnerBook?.currentReaderNickname ?? ""
            state.partnerBookTitle = dto.partnerBook?.title ?? ""
            state.partnerBookCoverUrl = dto.partnerBook?.image
            state.partnerProfileImageUrl = dto.partnerBook?.currentReaderProfileImageUrl
            state.loading = false
        } catch {
            state.error = "정보를 불러오지 못했어요"
            state.loading = false
        }
    }

    // reaction: BOOM_UP | BOOM_DOWN | nil, comment: 필수
    func submitReview(reaction: String?, comment: String, onSuccess: @escaping () -> Void) {
        // 더블탭 가드
        if state.submitting { return }
        Task {
            state.submitting = true
            do {
                _ = try await trackerService.createMemberReview(
                    groupId: groupId, reaction: reaction, comment: comment
                )
                state.submitting = false
                onSuccess()
            } catch {
                state.submitting = false
            }
        }
    }
}
