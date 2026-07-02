import SwiftUI

// 교환 방식 필터 바텀시트 (안드 ExchangeMethodBottomSheet)
// tradeTypes: 0=전체([]), 1=직접교환([DIRECT]), 2=택배교환([DELIVERY])
struct GroupExchangeSheet: View {
    let initial: [String]
    let onApply: ([String]) -> Void
    let onCancel: () -> Void

    @State private var selected: Int

    private let options = ["전체", "직접 교환", "택배 교환"]

    init(initial: [String], onApply: @escaping ([String]) -> Void, onCancel: @escaping () -> Void) {
        self.initial = initial
        self.onApply = onApply
        self.onCancel = onCancel
        _selected = State(initialValue: initial.contains("DIRECT") ? 1 : (initial.contains("DELIVERY") ? 2 : 0))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            grabber
            HStack(spacing: 8) {
                Text("교환 방식")
                    .pretendardText(size: 20, weight: .semibold)
                    .foregroundColor(Color("grey900"))
                Text(options[selected])
                    .pretendardText(size: 16)
                    .foregroundColor(Color("main200"))
            }
            .padding(.bottom, 12)

            HStack(spacing: 10) {
                ForEach(options.indices, id: \.self) { i in
                    BottomSheetChip(text: options[i], selected: i == selected) { selected = i }
                        .frame(maxWidth: .infinity)
                }
            }

            HStack(spacing: 12) {
                BottomSheetButton(text: "취소", style: .white, action: onCancel)
                BottomSheetButton(text: "적용", style: .dark) {
                    onApply(selected == 1 ? ["DIRECT"] : (selected == 2 ? ["DELIVERY"] : []))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .presentationDetents([.height(240)])
    }

    private var grabber: some View {
        Capsule().fill(Color("grey200"))
            .frame(width: 44, height: 4)
            .frame(maxWidth: .infinity)
    }
}

// 탭 시 기본 눌림(페이드) 효과 제거 — 칩 클릭 애니메이션 없음
struct NoEffectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { configuration.label }
}

// 안드 BottomSheetChip 대응 — solid: 선택 시 main200 배경/흰 글씨(보더 없음), 미선택 시 흰+테두리
struct BottomSheetChip: View {
    let text: String
    let selected: Bool
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .pretendardText(size: 16, weight: .medium)
                .lineLimit(1)
                .foregroundColor(selected ? Color("white") : Color("grey900"))
                .padding(.horizontal, 12)
                .frame(minWidth: 60)
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(Capsule().fill(selected ? Color("main200") : Color("white")))
                .overlay(Capsule().stroke(selected ? Color.clear : Color("grey200"), lineWidth: 1))
        }
        .buttonStyle(NoEffectButtonStyle())
    }
}

// 안드 GenreSubChip 대응 — pale: 선택 시 main100 배경/main200 글씨/main105 보더, 미선택 시 흰+테두리
struct BottomSheetSubChip: View {
    let text: String
    let selected: Bool
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .pretendardText(size: 16, weight: .medium)
                .lineLimit(1)
                .foregroundColor(selected ? Color("main200") : Color("grey900"))
                .padding(.horizontal, 12)
                .frame(minWidth: 60)
                .frame(height: 46)
                .background(Capsule().fill(selected ? Color("main100") : Color("white")))
                .overlay(Capsule().stroke(selected ? Color("main105") : Color("grey200"), lineWidth: 1))
        }
        .buttonStyle(NoEffectButtonStyle())
    }
}

// 안드 BottomSheetTwoBtnShort 대응
struct BottomSheetButton: View {
    enum Style { case white, dark }
    let text: String
    let style: Style
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(text)
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(style == .dark ? Color("white") : Color("grey900"))
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 16).fill(style == .dark ? Color("grey900") : Color("white")))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(style == .dark ? Color.clear : Color("grey200"), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
