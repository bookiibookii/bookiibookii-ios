import Foundation
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

/// 안드로이드 FcmTokenRegistrar + BookiiMessagingService 대응.
/// - 설정 토글 ON: 권한 요청 → FCM 토큰 등록
/// - 설정 토글 OFF / 로그아웃: 토큰 비활성화
/// - 포그라운드 수신 시 배너 표시, 탭 시 redirectType 라우팅
@MainActor
final class PushNotificationManager: NSObject {
    static let shared = PushNotificationManager()

    private static let preferenceKey = "push_notification_enabled"
    private static let tokenKey = "push_device_token"

    private(set) var isPushEnabled: Bool

    private var notificationService: NotificationService?
    private var pendingUserInfo: [AnyHashable: Any]?
    private weak var navigationRouter: NavigationRouter?

    private override init() {
        if UserDefaults.standard.object(forKey: Self.preferenceKey) == nil {
            UserDefaults.standard.set(true, forKey: Self.preferenceKey)
        }
        isPushEnabled = UserDefaults.standard.bool(forKey: Self.preferenceKey)
        super.init()
    }

    func configure(notificationService: NotificationService, navigationRouter: NavigationRouter) {
        self.notificationService = notificationService
        self.navigationRouter = navigationRouter

        if FirebaseApp.app() == nil,
           Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }

        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        if isPushEnabled, TokenManager.shared.hasAccessToken {
            Task { await registerIfNeeded() }
        }
    }

    func handlePendingRedirectIfNeeded() {
        guard let userInfo = pendingUserInfo,
              let router = navigationRouter,
              TokenManager.shared.hasAccessToken else { return }
        pendingUserInfo = nil
        if let redirect = NotificationRedirectRouter.fromUserInfo(userInfo) {
            NotificationRedirectDispatcher.dispatch(redirect, router: router)
        }
    }

    // MARK: - Preference

    func setPushEnabled(_ enabled: Bool) async {
        isPushEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Self.preferenceKey)

        if enabled {
            await registerIfNeeded()
        } else {
            await deactivateCurrentToken()
        }
    }

    func registerAfterLogin() {
        guard isPushEnabled else { return }
        Task { await registerIfNeeded() }
    }

    func deactivateOnLogout() async {
        await deactivateCurrentToken()
    }

    // MARK: - Token

    private func registerIfNeeded() async {
        guard isPushEnabled,
              TokenManager.shared.hasAccessToken,
              let notificationService else { return }

        let granted = await requestAuthorization()
        guard granted else {
            isPushEnabled = false
            UserDefaults.standard.set(false, forKey: Self.preferenceKey)
            return
        }

        UIApplication.shared.registerForRemoteNotifications()

        do {
            let token = try await fetchFCMToken()
            UserDefaults.standard.set(token, forKey: Self.tokenKey)
            try await notificationService.registerDeviceToken(token: token)
        } catch {
            print("푸시 토큰 등록 실패: \(error)")
        }
    }

    private func deactivateCurrentToken() async {
        guard let notificationService,
              let token = UserDefaults.standard.string(forKey: Self.tokenKey),
              !token.isEmpty else {
            UserDefaults.standard.removeObject(forKey: Self.tokenKey)
            return
        }

        do {
            try await notificationService.deactivateDeviceToken(token: token)
        } catch {
            print("푸시 토큰 해제 실패: \(error)")
        }
        UserDefaults.standard.removeObject(forKey: Self.tokenKey)
    }

    private func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    private func fetchFCMToken() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            Messaging.messaging().token { token, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let token, !token.isEmpty {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "PushNotificationManager",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Empty FCM token"]
                    ))
                }
            }
        }
    }

    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let router = navigationRouter else {
            pendingUserInfo = userInfo
            return
        }
        guard TokenManager.shared.hasAccessToken else {
            pendingUserInfo = userInfo
            return
        }
        if let redirect = NotificationRedirectRouter.fromUserInfo(userInfo) {
            NotificationRedirectDispatcher.dispatch(redirect, router: router)
        }
    }
}

extension PushNotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound, .badge])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        Task { @MainActor in
            handleNotificationTap(userInfo: userInfo)
            completionHandler()
        }
    }
}

extension PushNotificationManager: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken, !fcmToken.isEmpty else { return }
        Task { @MainActor in
            guard isPushEnabled, TokenManager.shared.hasAccessToken else { return }
            UserDefaults.standard.set(fcmToken, forKey: Self.tokenKey)
            do {
                try await notificationService?.registerDeviceToken(token: fcmToken)
            } catch {
                print("FCM 토큰 갱신 등록 실패: \(error)")
            }
        }
    }
}
