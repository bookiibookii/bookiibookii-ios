import SwiftUI

// 안드로이드 ui/component/Buttons.kt 대응 공통 버튼 컴포넌트.
// 색상은 에셋(main200, main100=mainPale, grey900/200/500, white, pointRed) 사용,
// 폰트는 pretendardText(자간·행간 적용). 라운드: Footer=20, Card/Sheet=16.

// MARK: - FooterButton (하단 풀폭 액션, 높이 72 / round 20)

enum FooterButtonStyle { case dark, grey }

struct FooterButton: View {
    let text: String
    var style: FooterButtonStyle = .dark
    var enabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void

    private var containerColor: Color {
        if !enabled { return Color("grey200") }
        return style == .grey ? Color("grey200") : Color("grey900")
    }
    private var contentColor: Color {
        if !enabled { return Color("grey500") }
        return style == .grey ? Color("grey900") : Color("white")
    }

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(text)
                        .pretendardText(size: 18, weight: .medium)
                        .foregroundColor(contentColor)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .padding(.horizontal, 18)
            .background(containerColor)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .disabled(!enabled || isLoading)
    }
}

// MARK: - CardButton (카드형 액션, 기본 높이 56 / round 16, 4+1 변형)

enum CardButtonStyle { case main, mainPale, grey, white, red }

struct CardButton: View {
    let text: String
    var style: CardButtonStyle = .main
    var height: CGFloat = 56
    var corner: CGFloat = 16
    var fontSize: CGFloat = 16
    var contentColorOverride: Color? = nil   // 안드처럼 스타일 기본 글자색을 덮어쓸 때
    let action: () -> Void

    private var containerColor: Color {
        switch style {
        case .main:     return Color("main200")
        case .mainPale: return Color("main100")
        case .grey:     return Color("grey200")
        case .white:    return Color("white")
        case .red:      return Color("pointRed")
        }
    }
    private var contentColor: Color {
        switch style {
        case .main:     return Color("white")
        case .mainPale: return Color("main200")
        case .grey:     return Color("grey500")
        case .white:    return Color("grey900")
        case .red:      return Color("white")
        }
    }
    private var borderColor: Color? {
        style == .white ? Color("grey200") : nil
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .pretendardText(size: fontSize)
                .foregroundColor(contentColorOverride ?? contentColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .padding(.horizontal, 18)
                .background(containerColor)
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                .overlay(
                    Group {
                        if let borderColor {
                            RoundedRectangle(cornerRadius: corner, style: .continuous)
                                .strokeBorder(borderColor, lineWidth: 1)
                        }
                    }
                )
        }
    }
}

// MARK: - BottomSheetTwoBtnShort (시트/다이얼로그 버튼, 높이 56 / round 16, 5 변형)

enum BottomSheetBtnStyle { case white, dark, orange, grey, red }

struct BottomSheetTwoBtnShort: View {
    let text: String
    var style: BottomSheetBtnStyle = .dark
    var enabled: Bool = true
    let action: () -> Void

    private var containerColor: Color {
        if !enabled { return Color("grey200") }
        switch style {
        case .white:  return Color("white")
        case .dark:   return Color("grey900")
        case .orange: return Color("main200")
        case .grey:   return Color("grey200")
        case .red:    return Color("pointRed")
        }
    }
    private var contentColor: Color {
        if !enabled { return Color("grey500") }
        switch style {
        case .white:  return Color("grey900")
        case .dark:   return Color("white")
        case .orange: return Color("white")
        case .grey:   return Color("grey500")
        case .red:    return Color("white")
        }
    }
    private var borderColor: Color? {
        (enabled && style == .white) ? Color("grey200") : nil
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(contentColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .padding(.horizontal, 18)
                .background(containerColor)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    Group {
                        if let borderColor {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(borderColor, lineWidth: 1)
                        }
                    }
                )
        }
        .disabled(!enabled)
    }
}

#Preview {
    VStack(spacing: 12) {
        FooterButton(text: "다음", style: .dark, action: {})
        FooterButton(text: "비활성", enabled: false, action: {})
        HStack(spacing: 8) {
            CardButton(text: "취소", style: .grey, action: {})
            CardButton(text: "신청하기", style: .main, action: {})
        }
        CardButton(text: "자세히 보기", style: .mainPale, action: {})
        HStack(spacing: 8) {
            BottomSheetTwoBtnShort(text: "취소", style: .white, action: {})
            BottomSheetTwoBtnShort(text: "삭제", style: .red, action: {})
        }
    }
    .padding()
    .background(Color("uiBg"))
}
