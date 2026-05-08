import Foundation

/// 함께읽기(`TOGETHER`) 그룹의 완독 처리 결과를 로컬에 저장합니다.
///
/// 서버 `/api/library/books` 응답 DTO에는 현재 `myReadingRate / completedAt` 필드가
/// 포함되어 있지 않아, 화면을 닫았다가 다시 열면 서버에서 다시 받아올 수 없습니다.
/// (서버를 변경하지 않는 정책이라, `MatchedMember.currentReadingRate`를 직접 읽을 수 있는
/// 별도 GET API도 없는 상태입니다.)
///
/// `PATCH /api/groups/{groupId}/together/members/me/complete` 응답(`currentReadingRate`,
/// `completedAt`)을 사용자별 + 그룹별 키에 저장해, 재진입 시에도 "후기 작성하기" 라벨/
/// 100% 게이지가 유지되도록 합니다. 후기 작성 자체는 서버 `togetherComments` 데이터에서
/// 본인 작성 여부(`hasWrittenComment`)로 추가로 판정합니다.
struct TogetherReadingLocalStore {
    private static let userDefaults = UserDefaults.standard
    private static let storageKey = "TogetherReadingLocalStore.v1"

    struct Snapshot: Codable, Equatable {
        let readingRate: Int
        let completedAtISO: String
    }

    /// 토큰별 + groupId 별로 저장. 사용자가 바뀌거나 다른 그룹과 섞이지 않도록 분리합니다.
    private static func key(userId: Int?, groupId: Int) -> String {
        let uid = userId.map(String.init) ?? "anonymous"
        return "\(uid)::\(groupId)"
    }

    static func snapshot(userId: Int?, groupId: Int) -> Snapshot? {
        let map = loadMap()
        return map[key(userId: userId, groupId: groupId)]
    }

    static func save(userId: Int?, groupId: Int, snapshot: Snapshot) {
        var map = loadMap()
        map[key(userId: userId, groupId: groupId)] = snapshot
        saveMap(map)
    }

    static func clear(userId: Int?, groupId: Int) {
        var map = loadMap()
        map.removeValue(forKey: key(userId: userId, groupId: groupId))
        saveMap(map)
    }

    private static func loadMap() -> [String: Snapshot] {
        guard let data = userDefaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: Snapshot].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private static func saveMap(_ map: [String: Snapshot]) {
        guard let data = try? JSONEncoder().encode(map) else { return }
        userDefaults.set(data, forKey: storageKey)
    }
}
