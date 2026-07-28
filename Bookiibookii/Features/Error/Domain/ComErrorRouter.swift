import Foundation

extension Notification.Name {
  /// 안드로이드 `ComRetryBus.emitRetry()` 대응 — 에러 화면 [다시 시도] 후 구독 화면이 재조회.
  static let comErrorRetry = Notification.Name("comErrorRetry")
}

/// 안드로이드 `ErrorActivity` 라우팅 + `AuthInterceptor.routeComError` 대응.
@MainActor
enum ComErrorRouter {
    private static let cooldown: TimeInterval = 3
    private static var lastPresentedAt: Date?

    static weak var navigationRouter: NavigationRouter?

    static func configure(navigationRouter: NavigationRouter) {
        self.navigationRouter = navigationRouter
    }

    static func unlockRouting() {
        lastPresentedAt = nil
    }

    static func present(_ type: BookiiErrorType) {
        let now = Date()
        if let lastPresentedAt, now.timeIntervalSince(lastPresentedAt) < cooldown {
            return
        }
        lastPresentedAt = now
        navigationRouter?.presentedComError = type
    }

    static func dismiss() {
        navigationRouter?.presentedComError = nil
    }
}
