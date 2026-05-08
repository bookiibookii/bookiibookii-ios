import Foundation

/// 교환독서 후기에서 파트너에게 부여할 수 있는 8개 배지.
/// 안드 LibraryBookDetailRelayWriteFragment.mapUiTextToBadgeCode 기준.
struct ReviewBadge: Identifiable, Hashable {
    let id: String      // 서버 코드 (KINDNESS, FAST_SHIPPING, ...)
    let label: String   // 사용자 노출 텍스트

    static let all: [ReviewBadge] = [
        ReviewBadge(id: "KINDNESS",         label: "친절하고 매너가 좋아요"),
        ReviewBadge(id: "GOOD_HANDWRITING", label: "글씨가 예뻐요"),
        ReviewBadge(id: "SWEET_COMMENT",    label: "코멘트가 다정해요"),
        ReviewBadge(id: "INSIGHTFUL",       label: "책에 대한 인사이트가 넘쳐요"),
        ReviewBadge(id: "FAST_SHIPPING",    label: "책을 빠르게 보내줬어요"),
        ReviewBadge(id: "FUNNY",            label: "코멘트가 재미있어요"),
        ReviewBadge(id: "CLEAN_CONDITION",  label: "책을 깨끗하고 깔끔하게 읽어요"),
        ReviewBadge(id: "PUNCTUAL",         label: "약속을 잘 지켜요"),
    ]
}
