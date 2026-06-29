import Foundation

// 안드로이드 common/BookTitle.kt 대응
extension String {
    /// 책 제목에서 부제목을 제거한 표시용 제목.
    /// 알라딘 도서 제목은 `"본제목 - 부제목"`(스페이스-하이픈-스페이스) 형식이라 첫 `" - "` 앞부분만 남긴다.
    /// 단어 내 하이픈("K-팝" 등)은 건드리지 않는다. 구분자가 없으면 원본 유지.
    /// 표시 전용 — 검색/네비/매칭용 원본 제목은 그대로 두고 UI 출력 시에만 적용.
    func stripBookSubtitle() -> String {
        guard let range = self.range(of: " - ") else { return self }
        return String(self[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
    }
}
