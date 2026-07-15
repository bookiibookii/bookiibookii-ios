import SwiftUI

// 직접교환 약속 잡기 1/3 - 일시 선택 다이얼로그.
// 카드 컨텐츠만 담당 — 스크림/오버레이는 호스트 담당.
// initialScheduledAt: 수정 진입 시 기존 일시(ISO) 프리필용 (등록은 nil)
struct TrackerDirectMeetingTimeDialog: View {
    let onDismiss: () -> Void
    let onNextClick: (_ scheduledAt: String) -> Void

    private let today: Date

    @State private var displayMonth: Date
    @State private var selectedDate: Date?
    @State private var isAm: Bool
    @State private var hour: Int
    @State private var minute: Int

    init(
        onDismiss: @escaping () -> Void,
        onNextClick: @escaping (_ scheduledAt: String) -> Void,
        initialScheduledAt: String? = nil
    ) {
        self.onDismiss = onDismiss
        self.onNextClick = onNextClick

        let today = kstCalendar.startOfDay(for: Date())
        self.today = today

        // 기존 일시 파싱(수정 모드). 실패하거나 없으면 nil → 기본값 사용
        let initial = DateUtils.parseKstDateTime(initialScheduledAt)
        let initialDate: Date? = {
            guard let year = initial?.year, let month = initial?.month, let day = initial?.day else { return nil }
            return kstCalendar.date(from: DateComponents(year: year, month: month, day: day))
        }()

        _displayMonth = State(initialValue: startOfMonth(initialDate ?? today))
        _selectedDate = State(initialValue: initialDate)
        _isAm = State(initialValue: (initial?.hour ?? 0) < 12)
        _hour = State(initialValue: initial?.hour.map(to12Hour) ?? 6)
        _minute = State(initialValue: initial?.minute ?? 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            VStack(alignment: .leading, spacing: 20) {
                monthNavigator
                calendarGrid
                TimePickerRow(isAm: $isAm, hour: $hour, minute: $minute)
            }
            // 시/분 드롭다운이 아래 버튼 위로 떠 그려지도록 계산 섹션을 위에 합성
            .zIndex(1)
            buttonRow
        }
        .padding(20)
        // 드롭다운이 카드 밖으로 떠도 잘리지 않도록 clip 대신 배경만 라운드 처리
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color("white")))
    }

    // MARK: - 헤더

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: 8) {
                StepChip(text: "1/3")
                Text("언제 만날까요?")
                    .pretendardText(size: 24, weight: .bold)
                    .foregroundColor(Color("grey900"))
            }
            Spacer()
            Button(action: onDismiss) {
                Image("ic_x")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color("grey900"))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color("grey100")))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 월 이동

    private var monthNavigator: some View {
        HStack(spacing: 8) {
            Button(action: { displayMonth = kstCalendar.date(byAdding: .month, value: -1, to: displayMonth) ?? displayMonth }) {
                Image("ic_chevron")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 28, height: 28)
                    .foregroundColor(Color("black"))
            }
            .buttonStyle(.plain)
            .frame(width: 32, height: 32)

            Text(monthLabel)
                .pretendardText(size: 20, weight: .semibold)
                .foregroundColor(Color("grey900"))

            Button(action: { displayMonth = kstCalendar.date(byAdding: .month, value: 1, to: displayMonth) ?? displayMonth }) {
                Image("ic_chevron")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 28, height: 28)
                    .foregroundColor(Color("black"))
                    .rotationEffect(.degrees(180))
            }
            .buttonStyle(.plain)
            .frame(width: 32, height: 32)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var monthLabel: String {
        let comps = kstCalendar.dateComponents([.year, .month], from: displayMonth)
        return "\(comps.year ?? 0)년 \(comps.month ?? 0)월"
    }

    // MARK: - 캘린더 그리드

    private var calendarGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .pretendardText(size: 16, weight: .medium)
                        .foregroundColor(Color("grey700"))
                        .frame(width: 32)
                        .frame(maxWidth: .infinity)
                }
            }

            ForEach(buildCalendarGrid(month: displayMonth), id: \.self) { week in
                HStack(spacing: 0) {
                    ForEach(week, id: \.self) { cell in
                        DayCellView(
                            cell: cell,
                            today: today,
                            selectedDate: selectedDate,
                            onClick: { date in
                                selectedDate = (selectedDate == date) ? nil : date
                            }
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    // MARK: - 버튼

    private var buttonRow: some View {
        HStack(spacing: 8) {
            CardButton(text: "취소", style: .grey, action: onDismiss)
            CardButton(
                text: "다음",
                style: selectedDate != nil ? .main : .grey,
                action: {
                    guard let selectedDate else { return }
                    onNextClick(buildScheduledAt(date: selectedDate, isAm: isAm, hour12: hour, minute: minute))
                }
            )
        }
    }
}

// MARK: - KST 캘린더 / 날짜 유틸

private let kstCalendar: Calendar = {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
    return cal
}()

private let weekdayLabels = ["일", "월", "화", "수", "목", "금", "토"]

private func startOfMonth(_ date: Date) -> Date {
    let comps = kstCalendar.dateComponents([.year, .month], from: date)
    return kstCalendar.date(from: comps) ?? date
}

private func to12Hour(_ hour24: Int) -> Int {
    let h = hour24 % 12
    return h == 0 ? 12 : h
}

// 선택값(날짜 + 오전/오후 + 12시간제 시 + 분)을 ISO date-time 문자열로 조립
private func buildScheduledAt(date: Date, isAm: Bool, hour12: Int, minute: Int) -> String {
    let hour24: Int
    if isAm && hour12 == 12 {
        hour24 = 0 // 오전 12시 → 00시
    } else if !isAm && hour12 != 12 {
        hour24 = hour12 + 12 // 오후 1~11시 → 13~23시
    } else {
        hour24 = hour12 // 오전 1~11시, 오후 12시
    }
    let comps = kstCalendar.dateComponents([.year, .month, .day], from: date)
    return DateUtils.meetingAtFromKst(
        year: comps.year ?? 0,
        month: comps.month ?? 0,
        day: comps.day ?? 0,
        hour24: hour24,
        minute: minute
    )
}

private struct DayCell: Hashable {
    let date: Date
    let isCurrentMonth: Bool
}

private func buildCalendarGrid(month: Date) -> [[DayCell]] {
    let comps = kstCalendar.dateComponents([.year, .month], from: month)
    guard let firstOfMonth = kstCalendar.date(from: comps) else { return [] }
    let weekday = kstCalendar.component(.weekday, from: firstOfMonth) // 1=일 ... 7=토
    let daysFromPrevMonth = weekday - 1
    guard let gridStart = kstCalendar.date(byAdding: .day, value: -daysFromPrevMonth, to: firstOfMonth) else { return [] }

    var weeks = (0..<6).map { week in
        (0..<7).map { day -> DayCell in
            let offset = week * 7 + day
            let date = kstCalendar.date(byAdding: .day, value: offset, to: gridStart) ?? gridStart
            let isCurrentMonth = kstCalendar.isDate(date, equalTo: firstOfMonth, toGranularity: .month)
            return DayCell(date: date, isCurrentMonth: isCurrentMonth)
        }
    }
    // 맨 밑줄이 전부 다음 달이면 제거 (기본 5줄, 6주 필요한 달만 6줄 유지)
    while let last = weeks.last, last.allSatisfy({ !$0.isCurrentMonth }) {
        weeks.removeLast()
    }
    return weeks
}

// MARK: - StepChip

private struct StepChip: View {
    let text: String

    var body: some View {
        Text(text)
            .pretendardText(size: 14, weight: .medium)
            .foregroundColor(Color("grey900"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color("white"))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color("grey200"), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - 날짜 셀

private struct DayCellView: View {
    let cell: DayCell
    let today: Date
    let selectedDate: Date?
    let onClick: (Date) -> Void

    private var isSelectable: Bool { cell.isCurrentMonth && cell.date > today }
    private var isToday: Bool { cell.isCurrentMonth && kstCalendar.isDate(cell.date, inSameDayAs: today) }
    private var isSelected: Bool {
        guard cell.isCurrentMonth, let selectedDate else { return false }
        return kstCalendar.isDate(cell.date, inSameDayAs: selectedDate)
    }

    private var textColor: Color {
        if !cell.isCurrentMonth { return Color("grey400") }
        if isSelected { return Color("main200") }
        if isToday { return Color("sub200") }
        return Color("grey900")
    }

    var body: some View {
        Button(action: { onClick(cell.date) }) {
            Text("\(kstCalendar.component(.day, from: cell.date))")
                .pretendardText(size: 15, weight: .medium)
                .foregroundColor(textColor)
                .frame(width: 32, height: 32)
                .background(isSelected ? Color("main100") : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(alignment: .bottom) {
                    if isToday {
                        Circle()
                            .fill(Color("sub200"))
                            .frame(width: 4, height: 4)
                    }
                }
        }
        .buttonStyle(.plain)
        // 지난 날짜는 선택만 막고 글자색(검정)은 유지 — .disabled의 흐림 처리 방지
        .allowsHitTesting(isSelectable)
    }
}

// MARK: - 시간 선택

private let hourOptions = Array(1...12)
private let minuteOptions = Array(stride(from: 0, through: 55, by: 5))

private struct TimePickerRow: View {
    @Binding var isAm: Bool
    @Binding var hour: Int
    @Binding var minute: Int

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color("uiBg")).frame(height: 1)
            HStack {
                AmPmToggle(isAm: $isAm)
                Spacer()
                TimeBox(value: hour, suffix: "시", options: hourOptions, onSelect: { hour = $0 })
                Spacer()
                TimeBox(value: minute, suffix: "분", options: minuteOptions, onSelect: { minute = $0 })
            }
            .padding(.vertical, 14)
            Rectangle().fill(Color("uiBg")).frame(height: 1)
        }
    }
}

private struct AmPmToggle: View {
    @Binding var isAm: Bool

    var body: some View {
        HStack(spacing: 4) {
            chip(text: "오전", selected: isAm) { isAm = true }
            chip(text: "오후", selected: !isAm) { isAm = false }
        }
        .padding(2)
        .background(Color("grey200"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func chip(text: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .pretendardText(size: 14)
                .foregroundColor(Color("grey900"))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(selected ? Color("white") : Color("grey200"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

private struct TimeBox: View {
    let value: Int
    let suffix: String
    let options: [Int]
    let onSelect: (Int) -> Void

    @State private var expanded = false

    var body: some View {
        HStack(spacing: 4) {
            Button(action: { expanded.toggle() }) {
                Text(String(format: "%02d", value))
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey900"))
                    .padding(4)
                    .frame(width: 80)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color("grey200"), lineWidth: 1))
            }
            .buttonStyle(.plain)
            // 드롭다운은 레이아웃에 영향 주지 않는 overlay로 띄운다(다이얼로그가 커지지 않도록)
            .overlay(alignment: .top) {
                if expanded {
                    dropdownList
                        .offset(y: 44)
                        .zIndex(1)
                }
            }
            Text(suffix)
                .pretendardText(size: 14)
                .foregroundColor(Color("grey900"))
                .fixedSize()
        }
    }

    private var dropdownList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        onSelect(option)
                        expanded = false
                    }) {
                        Text(String(format: "%02d", option))
                            .pretendardText(size: 14)
                            .foregroundColor(Color("grey900"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(width: 80, height: 160)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color("grey200"), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    TrackerDirectMeetingTimeDialog(
        onDismiss: {},
        onNextClick: { _ in }
    )
    .padding(24)
    .background(Color("uiBg"))
}
