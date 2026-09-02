import Foundation
import Security

// 안드로이드 TokenManager (SharedPreferences) → iOS Keychain 대응
final class TokenManager: @unchecked Sendable {
    static let shared = TokenManager()

    private init() {
        // 앱 삭제 후 재설치 시 Keychain은 남아있으므로, UserDefaults로 최초 실행을 감지해 초기화
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "bookii.launched")
        if isFirstLaunch {
            Key.allCases.forEach { delete($0) }
            UserDefaults.standard.set(true, forKey: "bookii.launched")
        }
    }

    enum Key: String {
        case accessToken  = "bookii.access_token"
        case refreshToken = "bookii.refresh_token"
        case userId       = "bookii.user_id"
        case onboardingDone = "bookii.onboarding_done"
    }

    var hasAccessToken: Bool { !(accessToken?.isEmpty ?? true) }

    var accessToken: String? {
        get { read(.accessToken) }
        set { write(newValue, key: .accessToken) }
    }

    var refreshToken: String? {
        get { read(.refreshToken) }
        set { write(newValue, key: .refreshToken) }
    }

    var userId: Int? {
        get { read(.userId).flatMap(Int.init) }
        set { write(newValue.map(String.init), key: .userId) }
    }

    var isOnboardingDone: Bool {
        get { read(.onboardingDone) == "true" }
        set { write(newValue ? "true" : "false", key: .onboardingDone) }
    }

    func saveLoginResult(_ result: LoginResult) {
        accessToken = result.accessToken
        refreshToken = result.refreshToken
        userId = result.userId
        isOnboardingDone = result.isOnboardingDone
    }

    /// 토큰만 삭제한다. 온보딩 완료 여부는 남겨 재로그인 시 인트로가 다시 노출되지 않게 한다.
    /// (계정이 바뀌어도 로그인 응답 값으로 덮어써진다.)
    func clear() {
        Key.allCases
            .filter { $0 != .onboardingDone }
            .forEach { delete($0) }
        // 계정이 바뀌어도 이전 사용자의 이미지가 기기에 남지 않도록 함께 비운다.
        ImageCacheCleaner.clearAll()
    }

    // MARK: - Keychain helpers
    private func read(_ key: Key) -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func write(_ value: String?, key: Key) {
        guard let value else { delete(key); return }
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue
        ]
        if SecItemUpdate(query as CFDictionary, [kSecValueData: data] as CFDictionary) == errSecItemNotFound {
            SecItemAdd(query.merging([kSecValueData: data]) { $1 } as CFDictionary, nil)
        }
    }

    private func delete(_ key: Key) {
        SecItemDelete([
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue
        ] as CFDictionary)
    }
}

extension TokenManager.Key: CaseIterable {}
