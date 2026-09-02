import Kingfisher

/// 로그아웃·탈퇴 시 Kingfisher 이미지 캐시를 비운다.
///
/// 독서카드 사진처럼 사적인 이미지가 디스크에 남아, 같은 기기에서 다른 계정으로
/// 로그인했을 때까지 이전 사용자의 파일이 유지되는 것을 막는다.
enum ImageCacheCleaner {
    static func clearAll() {
        let cache = KingfisherManager.shared.cache
        cache.clearMemoryCache()
        cache.clearDiskCache()
    }
}
