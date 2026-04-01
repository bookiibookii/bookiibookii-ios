import SwiftUI

extension Color {
    // MARK: - 앱 공통 색상 (안드로이드 colors.xml 대응)
    static let uiBg      = Color(hex: "#F6F6F6") // @color/ui_bg
    static let grey200   = Color(hex: "#E2E1DF") // @color/grey_200
    static let grey500   = Color(hex: "#858481") // @color/grey_500
    static let grey700   = Color(hex: "#525D5B") // @color/grey_700
    static let grey900   = Color(hex: "#242322") // @color/grey_900
    static let preMain   = Color(hex: "#FF7618") // @color/pre_main (주황)

    // MARK: - 토글 버튼 색상
    static let toggleBgSelected      = Color(hex: "#242322")
    static let toggleBgUnselected    = Color.white
    static let toggleStrokeSelected  = Color(hex: "#242322")
    static let toggleStrokeUnselected = Color(hex: "#E2E1DF")
    static let toggleTextSelected    = Color.white
    static let toggleTextUnselected  = Color(hex: "#242322")

    // MARK: - Hex 초기화
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
