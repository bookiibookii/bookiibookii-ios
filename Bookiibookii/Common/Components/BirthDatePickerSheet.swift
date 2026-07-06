import SwiftUI

/// 생년월일 휠 피커 바텀시트 (안드로이드 BirthdatePickerBottomSheet 대응).
struct BirthDatePickerSheet: View {
    let initialDate: Date
    let onConfirm: (Date) -> Void

    private let years: [Int]
    private let months = Array(1...12)
    private let days = Array(1...31)
    private let today: (y: Int, m: Int, d: Int)

    @State private var yearIdx: Int
    @State private var monthIdx: Int
    @State private var dayIdx: Int

    init(initialDate: Date, onConfirm: @escaping (Date) -> Void) {
        self.initialDate = initialDate
        self.onConfirm = onConfirm

        let cal = Calendar(identifier: .gregorian)
        let now = Date()
        let cy = cal.component(.year, from: now)
        today = (cy, cal.component(.month, from: now), cal.component(.day, from: now))

        let ys = Array(1924...cy)
        years = ys

        let c = cal.dateComponents([.year, .month, .day], from: initialDate)
        let iy = c.year ?? 2000, im = c.month ?? 1, id = c.day ?? 1
        _yearIdx = State(initialValue: ys.firstIndex(of: iy) ?? (ys.count - 1))
        _monthIdx = State(initialValue: min(max(im - 1, 0), 11))
        _dayIdx = State(initialValue: min(max(id - 1, 0), 30))
    }

    private var selYear: Int { years[yearIdx] }
    private var selMonth: Int { months[monthIdx] }
    private var selDay: Int { days[dayIdx] }

    private var isFuture: Bool {
        if selYear != today.y { return selYear > today.y }
        if selMonth != today.m { return selMonth > today.m }
        return selDay > today.d
    }

    private var composedDate: Date {
        let cal = Calendar(identifier: .gregorian)
        var monthComp = DateComponents(); monthComp.year = selYear; monthComp.month = selMonth
        let maxDay = cal.date(from: monthComp).flatMap { cal.range(of: .day, in: .month, for: $0)?.count } ?? 31
        var comp = DateComponents()
        comp.year = selYear; comp.month = selMonth; comp.day = min(selDay, maxDay)
        return cal.date(from: comp) ?? initialDate
    }

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("grey200")).frame(width: 44, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 24)

            Spacer().frame(height: 20)

            HStack {
                Text("생년월일")
                    .pretendardText(size: 20, weight: .semibold)
                    .foregroundColor(Color("grey900"))
                Spacer()
                Button(action: { if !isFuture { onConfirm(composedDate) } }) {
                    Text("완료")
                        .pretendardText(size: 20)
                        .foregroundColor(isFuture ? Color("grey300") : Color("grey500"))
                }
                .disabled(isFuture)
            }
            .padding(.horizontal, 16)

            Spacer().frame(height: 16)

            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color("main100"))
                    .frame(height: 41)

                HStack(spacing: 8) {
                    WheelPickerColumn(items: years.map { "\($0)년" }, index: $yearIdx)
                    WheelPickerColumn(items: months.map { "\($0)월" }, index: $monthIdx)
                    WheelPickerColumn(items: days.map { "\($0)일" }, index: $dayIdx)
                }
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color("white"))
    }
}

private struct WheelPickerColumn: View {
    let items: [String]
    @Binding var index: Int

    private let itemHeight: CGFloat = 41
    private let spacing: CGFloat = 10
    private let visible = 5
    private var pitch: CGFloat { itemHeight + spacing }
    private var viewport: CGFloat { itemHeight * CGFloat(visible) + spacing * CGFloat(visible - 1) }
    private var inset: CGFloat { (viewport - itemHeight) / 2 }

    @State private var didInit = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: spacing) {
                    ForEach(items.indices, id: \.self) { i in
                        Text(items[i])
                            .pretendardText(size: 18, weight: i == index ? .semibold : .regular)
                            .foregroundColor(i == index ? Color("main200") : Color("grey900"))
                            .frame(maxWidth: .infinity)
                            .frame(height: itemHeight)
                            .id(i)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.vertical, inset, for: .scrollContent)
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { _, y in
                guard didInit else { return }
                let i = min(max(Int(((y + inset) / pitch).rounded()), 0), items.count - 1)
                if i != index { index = i }
            }
            .frame(height: viewport)
            .onAppear {
                guard !didInit else { return }
                proxy.scrollTo(index, anchor: .center)
                DispatchQueue.main.async { didInit = true }
            }
        }
    }
}
