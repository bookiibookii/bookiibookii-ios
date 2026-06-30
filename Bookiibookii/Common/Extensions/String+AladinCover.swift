import Foundation

// 안드 BookCover.toAladinCover 대응.
// 알라딘 표지 URL의 사이즈 토큰(coversum/cover/cover{n})을 지정 사이즈로 교체해 고화질로 표시.
// 일부 응답(예: 베스트셀러)이 저해상도로 내려와도 cover500으로 올려 표시.
// 경로 마지막 세그먼트(파일명) 바로 앞의 토큰만 교체. 알라딘 URL이 아니면 원본 그대로.
// TODO: 백엔드에서 고화질로 내려주면 제거.
extension String {
    private static let aladinCoverSizeRegex = try? NSRegularExpression(
        pattern: #"/(coversum|cover\d+|cover)/(?=[^/]+$)"#
    )

    func toAladinCover(_ size: String) -> String {
        guard contains("image.aladin.co.kr"),
              let regex = Self.aladinCoverSizeRegex else { return self }
        let range = NSRange(startIndex..., in: self)
        return regex.stringByReplacingMatches(in: self, range: range, withTemplate: "/\(size)/")
    }
}
