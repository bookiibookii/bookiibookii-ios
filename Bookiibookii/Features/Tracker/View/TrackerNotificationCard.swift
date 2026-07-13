import SwiftUI

struct TrackerNotificationCard: View {
    let notifications: [TrackerNotificationItem]
    let onItemClick: (Int) -> Void

    @State private var currentPage: Int = 0
    @State private var pageHeight: CGFloat = 0

    var body: some View {
        if notifications.isEmpty {
            EmptyView()
        } else {
            ZStack(alignment: .topTrailing) {
                TabView(selection: $currentPage) {
                    ForEach(Array(notifications.enumerated()), id: \.offset) { index, item in
                        TrackerNotificationPage(
                            item: item,
                            onTap: { onItemClick(item.groupId) }
                        )
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(key: TrackerPageHeightKey.self, value: proxy.size.height)
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onPreferenceChange(TrackerPageHeightKey.self) { pageHeight = $0 }
                .onChange(of: notifications.count) { _, count in
                    if currentPage >= count { currentPage = max(0, count - 1) }
                }
                .frame(maxWidth: .infinity)
                .frame(height: pageHeight > 0 ? pageHeight : nil)

                if notifications.count > 1 {
                    TrackerCarouselIndicator(total: notifications.count, current: currentPage)
                        .padding(.top, 24)
                        .padding(.trailing, 24)
                }
            }
            .background(Color("white"))
        }
    }
}

private struct TrackerPageHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// 배너 한 페이지: dDay / 토큰 치환 본문(카운트다운 포함) / subText
private struct TrackerNotificationPage: View {
    let item: TrackerNotificationItem
    let onTap: () -> Void

    @State private var seconds: Int

    init(item: TrackerNotificationItem, onTap: @escaping () -> Void) {
        self.item = item
        self.onTap = onTap
        _seconds = State(initialValue: item.remainingSeconds)
    }

    private var hasTimer: Bool { item.template.contains("{remainingTime}") }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.dDay)
                .pretendardText(size: 18, weight: .semibold)
                .foregroundColor(Color("sub200"))
            trackerBannerBody(
                template: item.template,
                nickname: item.nickname,
                bookTitle: item.bookTitle,
                seconds: seconds
            )
            .pretendardText(size: 18)
            Text(item.subText)
                .pretendardText(size: 16)
                .foregroundColor(Color("grey400"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .task(id: item.groupId) {
            guard hasTimer else { return }
            while seconds > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                seconds -= 1
            }
        }
        .onChange(of: item.remainingSeconds) { _, newValue in
            seconds = newValue
        }
    }
}

private struct TrackerCarouselIndicator: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index == current ? Color("grey500") : Color("grey200"))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - 배너 placeholder 토큰 치환 ({nickname}/{bookTitle}/{remainingTime})

private let secondsPerDay = 86_400

// 남은 시간 표기: 24시간 이상이면 "N일"(올림), 24시간 미만이면 HH:MM:SS 카운트다운
func formatRemainingTime(_ totalSeconds: Int) -> String {
    let s = max(totalSeconds, 0)
    if s >= secondsPerDay {
        let days = (s + secondsPerDay - 1) / secondsPerDay
        return "\(days)일"
    }
    return String(format: "%02d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
}

// 조사 첫 글자 → (받침 있을 때 form, 받침 없을 때 form)
private let josaForms: [Character: (batchim: Character, noBatchim: Character)] = [
    "을": ("을", "를"), "를": ("을", "를"),
    "은": ("은", "는"), "는": ("은", "는"),
    "이": ("이", "가"), "가": ("이", "가"),
    "과": ("과", "와"), "와": ("과", "와"),
]

// 앞말(prevValue)의 마지막 글자 받침 유무에 따라 text 첫 글자의 조사를 보정
func correctJosa(_ text: String, prevValue: String?) -> String {
    guard let prevValue, !prevValue.isEmpty, let first = text.first else { return text }
    guard let forms = josaForms[first] else { return text }
    guard let lastScalar = prevValue.unicodeScalars.last else { return text }
    let code = lastScalar.value
    let hasBatchim = (0xAC00...0xD7A3).contains(code) && (code - 0xAC00) % 28 != 0
    let corrected = hasBatchim ? forms.batchim : forms.noBatchim
    return String(corrected) + text.dropFirst()
}

private let bannerTokenRegex = /\{(nickname|bookTitle|remainingTime)\}/

// titleTemplate의 {nickname}/{bookTitle}/{remainingTime}를 실제 값으로 치환 + 조사 보정.
// 강조(토큰 값) = grey900, 리터럴 = grey700.
func trackerBannerBody(template: String, nickname: String, bookTitle: String, seconds: Int) -> Text {
    let emphasis = Color("grey900")
    let normal = Color("grey700")

    var result = Text("")
    var lastIndex = template.startIndex
    var prevValue: String?

    for match in template.matches(of: bannerTokenRegex) {
        if match.range.lowerBound > lastIndex {
            let literal = correctJosa(String(template[lastIndex..<match.range.lowerBound]), prevValue: prevValue)
            result = result + Text(literal).foregroundColor(normal)
            prevValue = nil
        }
        let token = String(match.output.1)
        let value: String
        switch token {
        case "nickname":  value = nickname
        case "bookTitle": value = bookTitle
        default:          value = formatRemainingTime(seconds)
        }
        result = result + Text(value).foregroundColor(emphasis)
        prevValue = value
        lastIndex = match.range.upperBound
    }
    if lastIndex < template.endIndex {
        let literal = correctJosa(String(template[lastIndex...]), prevValue: prevValue)
        result = result + Text(literal).foregroundColor(normal)
    }
    return result
}

#Preview("NotificationCard") {
    TrackerNotificationCard(
        notifications: [
            TrackerNotificationItem(
                groupId: 1,
                dDay: "D-1",
                template: "{nickname}님께 {bookTitle}을 발송해주세요",
                nickname: "noshel",
                bookTitle: "살인자의 기억법",
                remainingSeconds: 0,
                subText: "책이 파손되지 않도록 꼼꼼히 포장해주세요"
            ),
            TrackerNotificationItem(
                groupId: 2,
                dDay: "D-5",
                template: "{nickname} 님과의 책 교환까지 {remainingTime} 남았어요",
                nickname: "noshel",
                bookTitle: "작별인사",
                remainingSeconds: 3661,
                subText: "오늘 읽은 페이지를 기록해주세요"
            ),
            TrackerNotificationItem(
                groupId: 3,
                dDay: "D-3",
                template: "{bookTitle}을 읽고 후기를 남겨주세요",
                nickname: "noshel",
                bookTitle: "데미안",
                remainingSeconds: 0,
                subText: "샘플 서브 텍스트"
            ),
        ],
        onItemClick: { _ in }
    )
}
