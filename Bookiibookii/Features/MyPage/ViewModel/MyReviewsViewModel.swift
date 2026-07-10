import Foundation
import Combine

@MainActor
final class MyReviewsViewModel: ObservableObject {
    @Published var selectedTab: MyReviewTab
    @Published private(set) var writtenReviews: [WrittenReviewItem] = []
    @Published private(set) var writtenTotalCount = 0
    @Published private(set) var receivedReviews: [ReceivedReviewItem] = []
    @Published private(set) var receivedPositiveCount = 0
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published var errorMessage: String?

    let nickname: String

    private let userService: UserService
    private let profileNickname: String?
    private var writtenPage = 0
    private var receivedPage = 0
    private var writtenHasNext = false
    private var receivedHasNext = false
    private let pageSize = 20

    init(userService: UserService, initialTab: MyReviewTab, nickname: String, profileNickname: String? = nil) {
        self.userService = userService
        self.selectedTab = initialTab
        self.nickname = nickname
        self.profileNickname = profileNickname
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        switch selectedTab {
        case .written:
            await loadWritten(reset: true)
        case .received:
            await loadReceived(reset: true)
        }
    }

    func selectTab(_ tab: MyReviewTab) async {
        guard selectedTab != tab else { return }
        selectedTab = tab

        switch tab {
        case .written where writtenReviews.isEmpty:
            await loadWritten(reset: true)
        case .received where receivedReviews.isEmpty:
            await loadReceived(reset: true)
        default:
            break
        }
    }

    func loadMoreIfNeeded(currentItemId: Int) async {
        guard !isLoading, !isLoadingMore else { return }

        switch selectedTab {
        case .written:
            guard writtenHasNext, currentItemId == writtenReviews.last?.id else { return }
            await loadWritten(reset: false)
        case .received:
            guard receivedHasNext, currentItemId == receivedReviews.last?.id else { return }
            await loadReceived(reset: false)
        }
    }

    private func loadWritten(reset: Bool) async {
        if reset {
            writtenPage = 0
            writtenHasNext = false
        } else {
            isLoadingMore = true
            defer { isLoadingMore = false }
        }

        do {
            let result: WrittenReviewsResult
            if let profileNickname {
                result = try await userService.getProfileWrittenReviews(
                    nickname: profileNickname,
                    page: writtenPage,
                    size: pageSize
                )
            } else {
                result = try await userService.getWrittenReviews(page: writtenPage, size: pageSize)
            }
            if reset {
                writtenReviews = result.content
            } else {
                writtenReviews.append(contentsOf: result.content)
            }
            writtenTotalCount = result.totalCount
            writtenHasNext = result.pageInfo.hasNext
            if result.pageInfo.hasNext {
                writtenPage += 1
            }
        } catch {
            if reset {
                writtenReviews = []
                writtenTotalCount = 0
            }
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func loadReceived(reset: Bool) async {
        if reset {
            receivedPage = 0
            receivedHasNext = false
        } else {
            isLoadingMore = true
            defer { isLoadingMore = false }
        }

        do {
            let result: ReceivedReviewsResult
            if let profileNickname {
                result = try await userService.getProfileReceivedReviews(
                    nickname: profileNickname,
                    page: receivedPage,
                    size: pageSize
                )
            } else {
                result = try await userService.getReceivedReviews(page: receivedPage, size: pageSize)
            }
            if reset {
                receivedReviews = result.content
            } else {
                receivedReviews.append(contentsOf: result.content)
            }
            receivedPositiveCount = result.positiveCount
            receivedHasNext = result.pageInfo.hasNext
            if result.pageInfo.hasNext {
                receivedPage += 1
            }
        } catch {
            if reset {
                receivedReviews = []
                receivedPositiveCount = 0
            }
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
