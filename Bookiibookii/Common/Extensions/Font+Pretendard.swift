import SwiftUI

extension Font {
    /// Pretendard Variable 폰트. 가변 폰트이므로 weight 파라미터로 굵기 지정.
    static func pretendard(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("Pretendard Variable", size: size).weight(weight)
    }

    /// MaruBuri 세리프 폰트 (독서카드/라이브러리 본문·인용 등).
    /// 정적 폰트라 weight별 PostScript 이름을 직접 매핑
    static func maruburi(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .ultraLight, .thin:
            name = "MaruBuri-ExtraLight"
        case .light:
            name = "MaruBuri-Light"
        case .medium, .semibold:
            name = "MaruBuri-SemiBold"
        case .bold, .heavy, .black:
            name = "MaruBuri-Bold"
        default:
            name = "MaruBuri-Regular"
        }
        return Font.custom(name, size: size)
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
