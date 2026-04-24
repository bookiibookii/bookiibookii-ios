import Foundation
import Combine

@MainActor
final class NotificationViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case failed
    }

    let category: NotificationCategory

    @Published private(set) var items: [NotificationItemDto] = []
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasNext = false
    @Published private(set) var nextCursor: String?

    private let service: NotificationService
    private let pageSize: Int

    init(service: NotificationService, category: NotificationCategory, pageSize: Int = 20) {
        self.service = service
        self.category = category
        self.pageSize = pageSize
    }

    /// 첫 페이지 로드 (재호출 시 리스트 리셋).
    func loadFirstPage() async {
        phase = .loading
        items = []
        nextCursor = nil
        hasNext = false

        do {
            let result = try await service.fetchNotifications(
                category: category,
                cursor: nil,
                size: pageSize
            )
            items = result.items
            nextCursor = result.nextCursor
            hasNext = result.hasNext
            phase = .loaded
        } catch {
            phase = .failed
        }
    }

    /// 스크롤 바닥 도달 시 다음 페이지.
    func loadNextPageIfNeeded() async {
        guard phase != .loading, !isLoadingMore, hasNext,
              let cursor = nextCursor, !cursor.isEmpty else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let result = try await service.fetchNotifications(
                category: category,
                cursor: cursor,
                size: pageSize
            )
            items.append(contentsOf: result.items)
            nextCursor = result.nextCursor
            hasNext = result.hasNext
        } catch {
            // 페이지 추가 실패는 화면 전체를 에러로 바꾸지 않음. 안드로이드와 동일.
        }
    }

    /// 탭한 알림 읽음 처리.
    /// 낙관적 업데이트로 탭 즉시 UI 반영 → 이후 서버 응답으로 최종값 덮어씀.
    /// 실패 시 UI는 그대로 두되 디버그 로그만 남긴다(안드로이드 동작과 동일).
    func markAsRead(_ id: Int) async {
        guard let idx = items.firstIndex(where: { $0.id == id }),
              items[idx].isRead == false else { return }

        let original = items[idx]
        items[idx] = NotificationItemDto(
            id: original.id,
            type: original.type,
            title: original.title,
            message: original.message,
            isRead: true,
            createdAt: original.createdAt,
            readAt: original.readAt
        )

        do {
            let updated = try await service.markAsRead(notificationId: id)
            if let newIdx = items.firstIndex(where: { $0.id == id }) {
                items[newIdx] = updated
            }
        } catch {
            #if DEBUG
            print("[NotificationViewModel] markAsRead failed for id=\(id):", error)
            #endif
        }
    }
}
