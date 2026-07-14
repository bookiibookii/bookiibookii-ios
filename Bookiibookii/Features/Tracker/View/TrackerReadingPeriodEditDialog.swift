import SwiftUI

// 예상 독서 기간(예정 종료일) 수정 다이얼로그. 오늘 이후 날짜만 선택 가능.
struct TrackerReadingPeriodEditDialog: View {
    let originalEndDate: Date?
    let onConfirm: (Date) -> Void
    let onDismiss: () -> Void

    private static let weekdayLabels = ["일", "월", "화", "수", "목", "금", "토"]
    private let calendar = Calendar(identifier: .gregorian)

    @State private var displayMonth: Date   // 표시 중인 달의 1일(자정)
    @State private var selectedDate: Date?

    init(originalEndDate: Date?, onConfirm: @escaping (Date) -> Void, onDismiss: @escaping () -> Void) {
        self.originalEndDate = originalEndDate
        self.onConfirm = onConfirm
        self.onDismiss = onDismiss
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let base = originalEndDate ?? Date()
        let comps = cal.dateComponents([.year, .month], from: base)
        _displayMonth = State(initialValue: cal.date(from: comps) ?? cal.startOfDay(for: base))
    }

    private var today: Date { calendar.startOfDay(for: Date()) }
    private var originalDay: Date? { originalEndDate.map { calendar.startOfDay(for: $0) } }

    private let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        f.locale = Locale(identifier: "ko_KR")
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("예상 독서 기간 수정")
                    .pretendardText(size: 24, weight: .bold)
                    .foregroundColor(Color("grey900"))
                Spacer()
                Button(action: onDismiss) {
                    Image("ic_x").resizable().scaledToFit().frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }

            Text("파트너와 협의 후 예상 독서 기간을 수정해주세요.")
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey500"))
                .frame(maxWidth: .infinity, alignment: .leading)

            monthNav
            calendarGrid
            infoBox

            HStack(spacing: 8) {
                CardButton(text: "취소", style: .white, action: onDismiss)
                CardButton(
                    text: "수정",
                    style: selectedDate != nil ? .main : .grey,
                    action: { if let d = selectedDate { onConfirm(d) } }
                )
                .disabled(selectedDate == nil)
            }
        }
        .padding(20)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var monthNav: some View {
        HStack(spacing: 8) {
            Button { shiftMonth(-1) } label: {
                Image("ic_chevron").renderingMode(.template).resizable().scaledToFit()
                    .frame(width: 28, height: 28).foregroundColor(Color("black"))
            }.buttonStyle(.plain)
            let comps = calendar.dateComponents([.year, .month], from: displayMonth)
            Text("\(String(comps.year ?? 0))년 \(comps.month ?? 0)월")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))
            Button { shiftMonth(1) } label: {
                Image("ic_chevron").renderingMode(.template).resizable().scaledToFit()
                    .frame(width: 28, height: 28).foregroundColor(Color("black"))
                    .rotationEffect(.degrees(180))
            }.buttonStyle(.plain)
        }
    }

    private var calendarGrid: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(Self.weekdayLabels, id: \.self) { label in
                    Text(label)
                        .pretendardText(size: 16, weight: .medium)
                        .foregroundColor(Color("grey700"))
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(Array(weeks().enumerated()), id: \.offset) { _, week in
                HStack {
                    ForEach(week, id: \.timeIntervalSince1970) { date in
                        dayCell(date)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ date: Date) -> some View {
        let isCurrentMonth = calendar.isDate(date, equalTo: displayMonth, toGranularity: .month)
        let isSelectable = isCurrentMonth && date > today
        let isToday = isCurrentMonth && date == today
        let isOriginal = isCurrentMonth && date == originalDay
        let isSelected = isCurrentMonth && selectedDate.map { $0 == date } == true

        let textColor: Color = {
            if !isCurrentMonth { return Color("grey400") }
            if isSelected { return Color("main200") }
            if isToday { return Color("sub200") }
            if isOriginal { return Color("main200") }
            return Color("grey900")
        }()

        ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color("main100"))
            }
            Text("\(calendar.component(.day, from: date))")
                .pretendardText(size: 15, weight: .medium)
                .foregroundColor(textColor)
            if isToday {
                Circle().fill(Color("sub200")).frame(width: 4, height: 4)
                    .offset(y: 11)
            }
        }
        .frame(width: 32, height: 32)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            guard isSelectable else { return }
            selectedDate = (selectedDate == date) ? nil : date
        }
    }

    private var infoBox: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text("기존 예정 독서 종료일").pretendardText(size: 14).foregroundColor(Color("grey700"))
                Text("|").pretendardText(size: 14).foregroundColor(Color("grey700"))
                Text(originalDay.map { "\(displayFormatter.string(from: $0))." } ?? "-")
                    .pretendardText(size: 14).foregroundColor(Color("grey700"))
            }
            HStack(spacing: 4) {
                Text("수정 예정 독서 종료일").pretendardText(size: 14).foregroundColor(Color("grey700"))
                Text("|").pretendardText(size: 14).foregroundColor(Color("grey700"))
                if let sel = selectedDate {
                    Text("\(displayFormatter.string(from: sel)).")
                        .pretendardText(size: 14, weight: .medium).foregroundColor(Color("main200"))
                } else {
                    Text("-").pretendardText(size: 14).foregroundColor(Color("grey700"))
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color("grey200"), lineWidth: 1))
    }

    private func shiftMonth(_ delta: Int) {
        if let d = calendar.date(byAdding: .month, value: delta, to: displayMonth) { displayMonth = d }
    }

    // 일요일 시작 6주 그리드
    private func weeks() -> [[Date]] {
        let weekday = calendar.component(.weekday, from: displayMonth) // 1=일..7=토
        let daysFromPrev = weekday - 1
        guard let gridStart = calendar.date(byAdding: .day, value: -daysFromPrev, to: displayMonth) else { return [] }
        return (0..<6).map { week in
            (0..<7).compactMap { day in
                calendar.date(byAdding: .day, value: week * 7 + day, to: gridStart)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.45).ignoresSafeArea()
        TrackerReadingPeriodEditDialog(
            originalEndDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
            onConfirm: { _ in }, onDismiss: {}
        )
        .padding(.horizontal, 24)
    }
}
