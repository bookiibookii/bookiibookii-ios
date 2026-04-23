import SwiftUI

extension Font {
    /// Pretendard Variable 폰트. 가변 폰트이므로 weight 파라미터로 굵기 지정.
    /// 시스템 폰트 대체가 필요할 경우 registered name은 "Pretendard Variable"
    static func pretendard(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("Pretendard Variable", size: size).weight(weight)
    }
}

#Preview("Pretendard Sample") {
    VStack(alignment: .leading, spacing: 8) {
        Text("Regular 14").font(.pretendard(size: 14))
        Text("Medium 14").font(.pretendard(size: 14, weight: .medium))
        Text("Bold 24").font(.pretendard(size: 24, weight: .bold))
    }
    .padding()
}
