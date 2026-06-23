import SwiftUI
import UIKit

/// - `lineHeight = fontSize × 1.4` (행간)
/// - `letterSpacing = -0.01em` (자간)
extension View {
    /// 폰트 + 자간 + 행간을 한 번에 적용
    func pretendardText(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        let uiLineHeight = (UIFont(name: "Pretendard Variable", size: size)
            ?? .systemFont(ofSize: size)).lineHeight
        return self
            .font(.pretendard(size: size, weight: weight))
            .tracking(size * -0.01)
            .lineSpacing(max(0, size * 1.4 - uiLineHeight))
    }
}
