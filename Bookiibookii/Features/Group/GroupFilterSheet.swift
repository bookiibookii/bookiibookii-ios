import SwiftUI

/// 그룹유형·분야별 공용 바텀시트.
/// 안드로이드 `FilterBottomSheetFragment` 포팅.
struct GroupFilterSheet<Item: CaseIterable & Hashable & Identifiable>: View
where Item.AllCases == [Item] {
    enum Kind {
        case groupType   // 함께읽기 / 직접교환 / 택배교환 (전체 후 구분선)
        case category    // 9개 장르 flow layout
    }

    let kind: Kind
    let title: String
    let items: [Item]
    let itemDisplay: (Item) -> String
    let preSelected: Set<Item>
    let onConfirm: (Set<Item>) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selection: Set<Item>

    init(
        kind: Kind,
        title: String,
        items: [Item],
        itemDisplay: @escaping (Item) -> String,
        preSelected: Set<Item>,
        onConfirm: @escaping (Set<Item>) -> Void
    ) {
        self.kind = kind
        self.title = title
        self.items = items
        self.itemDisplay = itemDisplay
        self.preSelected = preSelected
        self.onConfirm = onConfirm
        _selection = State(initialValue: preSelected)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            handleBar
                .padding(.top, 12)

            header
                .padding(.horizontal, 24)
                .padding(.top, 20)

            chipArea
                .padding(.horizontal, 24)
                .padding(.top, 20)

            actionRow
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
        }
        .background(Color("white"))
    }

    // 안드로이드 grp_bottom_sheet_handle 대응 (40×4 grey200)
    private var handleBar: some View {
        HStack {
            Spacer()
            Rectangle()
                .fill(Color("grey200"))
                .frame(width: 40, height: 4)
            Spacer()
        }
    }

    // MARK: - 헤더

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.pretendard(size: 18, weight: .bold))
                .foregroundColor(Color("grey900"))
            summaryText
            Spacer()
        }
    }

    private var summaryText: some View {
        let list = items.filter { selection.contains($0) }.map(itemDisplay)
        return Group {
            if list.isEmpty {
                Text("전체")
                    .font(.pretendard(size: 14, weight: .medium))
                    .foregroundColor(Color("main200"))
            } else if list.count <= 3 {
                Text(list.joined(separator: " · "))
                    .font(.pretendard(size: 14, weight: .medium))
                    .foregroundColor(Color("main200"))
            } else {
                let first3 = list.prefix(3).joined(separator: " · ")
                (Text(first3).foregroundColor(Color("main200"))
                 + Text(" 외 \(list.count - 3)개").foregroundColor(Color("grey500")))
                    .font(.pretendard(size: 14, weight: .medium))
            }
        }
    }

    // MARK: - 칩 영역

    @ViewBuilder
    private var chipArea: some View {
        switch kind {
        case .groupType: groupTypeChips
        case .category:  categoryChips
        }
    }

    /// 안드로이드 `FilterBottomSheetFragment.setupUI`의 addDynamicDivider 순서대로:
    /// [전체] [함께 읽기] | divider | [직접 교환] [택배 교환]
    /// (`dataText == "함께 읽기"`일 때 해당 칩 뒤에 divider 삽입)
    private var groupTypeChips: some View {
        HStack(spacing: 8) {
            chip(text: "전체", isSelected: selection.isEmpty) {
                selection.removeAll()
            }
            ForEach(Array(items.enumerated()), id: \.element.id) { _, item in
                chip(text: itemDisplay(item), isSelected: selection.contains(item)) {
                    toggle(item)
                }
                if itemDisplay(item) == "함께 읽기" {
                    Rectangle()
                        .fill(Color("grey300"))
                        .frame(width: 1, height: 38)
                }
            }
            Spacer()
        }
    }

    /// 분야별: [전체] + 9개 장르를 FlowLayout으로 자동 줄바꿈
    private var categoryChips: some View {
        GroupFilterFlowLayout(spacing: 8, lineSpacing: 8) {
            chip(text: "전체", isSelected: selection.isEmpty) {
                selection.removeAll()
            }
            ForEach(items) { item in
                chip(text: itemDisplay(item), isSelected: selection.contains(item)) {
                    toggle(item)
                }
            }
        }
    }

    private func toggle(_ item: Item) {
        if selection.contains(item) {
            selection.remove(item)
        } else {
            selection.insert(item)
        }
    }

    // MARK: - 칩 공통

    private func chip(text: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.pretendard(size: 14, weight: .medium))
                .foregroundColor(isSelected ? Color("main200") : Color("grey700"))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule().fill(isSelected ? Color("main100") : Color("white"))
                )
                .overlay(
                    Capsule().stroke(
                        isSelected ? Color("main200") : Color("grey200"),
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 하단 버튼

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button {
                dismiss()
            } label: {
                Text("취소")
                    .font(.pretendard(size: 16, weight: .medium))
                    .foregroundColor(Color("grey900"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color("grey200"), lineWidth: 1)
                    )
            }

            Button {
                onConfirm(selection)
                dismiss()
            } label: {
                Text("확인")
                    .font(.pretendard(size: 16, weight: .medium))
                    .foregroundColor(Color("white"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color("grey900")))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FlowLayout (iOS 16+)

struct GroupFilterFlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var actualMaxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            x += size.width + spacing
            actualMaxX = max(actualMaxX, x - spacing)
            rowHeight = max(rowHeight, size.height)
            totalHeight = y + rowHeight
        }
        let resolvedWidth = maxWidth.isFinite ? maxWidth : actualMaxX
        return CGSize(width: resolvedWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview("그룹 유형 - 2개 선택") {
    GroupFilterSheet<GroupTypeFilter>(
        kind: .groupType,
        title: "그룹 유형",
        items: GroupTypeFilter.allCases,
        itemDisplay: { $0.displayName },
        preSelected: [.together, .direct],
        onConfirm: { _ in }
    )
    .frame(height: 240)
}

#Preview("분야별 - 2개 선택") {
    GroupFilterSheet<CategoryFilter>(
        kind: .category,
        title: "분야별",
        items: CategoryFilter.allCases,
        itemDisplay: { $0.displayName },
        preSelected: [.sciIt, .selfDev],
        onConfirm: { _ in }
    )
    .frame(height: 344)
}
