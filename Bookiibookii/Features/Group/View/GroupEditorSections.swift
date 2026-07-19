import SwiftUI

// 그룹 에디터(생성/수정) 섹션 컴포넌트 모음. 안드 GroupEditorScreen.kt 304-1129행 대응.

// MARK: - FieldLabel (안드 304-327행)

struct FieldLabel: View {
    let text: String
    var required: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey900"))
            if required {
                Text("*")
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("main200"))
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - BookSearchSection (안드 329-462행) — 생성 모드만 표시

struct BookSearchSection: View {
    @Binding var query: String
    let results: [BookItem]
    let bookSelected: Bool
    let error: String?
    let onQueryChange: (String) -> Void
    let onSearchClick: () -> Void
    let onClearClick: () -> Void
    let onBookSelect: (BookItem) -> Void

    // 책 선택 시 필드를 0.6초간 하이라이트(안드 Animatable+tween(600ms) 대응, nice-to-have)
    @State private var highlight = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FieldLabel(text: "도서 검색", required: true)
            ZStack(alignment: .top) {
                HStack(spacing: 8) {
                    Button(action: onSearchClick) {
                        Image("ic_search")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(Color("grey500"))
                    }
                    .buttonStyle(.plain)

                    TextField("", text: Binding(
                        get: { query },
                        set: { onQueryChange($0) }
                    ), prompt: Text("어떤 책을 읽어볼까요?").foregroundColor(Color("grey500")))
                        .pretendardText(size: 16)
                        .foregroundColor(Color("grey900"))
                        .tint(Color("main200"))
                        .disabled(bookSelected)
                        // 책 선택 후에는 텍스트 필드 탭-편집을 완전히 차단(X로만 초기화)
                        .allowsHitTesting(!bookSelected)
                        .submitLabel(.search)
                        .onSubmit(onSearchClick)

                    Button(action: onClearClick) {
                        Image("ic_x")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color("black"))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(highlight ? Color("main100") : Color("white"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(highlight ? Color("main200") : Color("grey300"), lineWidth: 1)
                )

                if !results.isEmpty {
                    GroupEditorBookSearchDropdown(books: results, onSelect: { book in
                        highlightOnSelect()
                        onBookSelect(book)
                    })
                    .padding(.top, 64)
                    .zIndex(1)
                }
            }

            if let error, results.isEmpty {
                Text(error)
                    .pretendardText(size: 14)
                    .foregroundColor(Color("pointRed"))
                    .padding(.top, 8)
            }
        }
    }

    private func highlightOnSelect() {
        withAnimation(.easeOut(duration: 0.05)) { highlight = true }
        withAnimation(.easeOut(duration: 0.6).delay(0.05)) { highlight = false }
    }
}

// 도서 검색 결과 드롭다운 (안드 BookSearchDropdown 대응, GroupApplyDialog 패턴 재사용)
struct GroupEditorBookSearchDropdown: View {
    let books: [BookItem]
    let onSelect: (BookItem) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(books) { book in
                    GroupEditorBookSearchRow(book: book, onTap: { onSelect(book) })
                }
            }
            .padding(8)
        }
        .frame(maxHeight: 320)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("grey200"), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

private struct GroupEditorBookSearchRow: View {
    let book: BookItem
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            BookCover(imageUrl: book.image)
                .frame(width: 48, height: 60)

            VStack(alignment: .leading, spacing: 2) {
                Text(book.title.stripBookSubtitle())
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey800"))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("\(book.author) (\(book.categoryLabel))")
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey600"))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

// MARK: - GroupNameSection (안드 464-517행)

struct GroupNameSection: View {
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FieldLabel(text: "그룹명", required: true)
            HStack(spacing: 8) {
                TextField("", text: $value, prompt: Text("그룹명을 입력해주세요").foregroundColor(Color("grey500")))
                    .pretendardText(size: 16)
                    .foregroundColor(Color("grey900"))
                    .tint(Color("main200"))

                Button(action: { value = "" }) {
                    Image("ic_x")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color("black"))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color("white")))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("grey300"), lineWidth: 1))
        }
    }
}

// MARK: - ExchangeTypeSection + ExchangeTypeCard (안드 520-600행) — 생성 모드만 표시

struct ExchangeTypeSection: View {
    let selected: ExchangeType?
    let onSelect: (ExchangeType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FieldLabel(text: "교환 유형", required: true)
            HStack(spacing: 8) {
                ExchangeTypeCard(
                    title: "택배 교환",
                    description: "책을 택배로 교환해요",
                    selected: selected == .delivery,
                    onClick: { onSelect(.delivery) }
                )
                .frame(maxWidth: .infinity)

                ExchangeTypeCard(
                    title: "직접 교환",
                    description: "책을 직접 만나서 교환해요",
                    selected: selected == .direct,
                    onClick: { onSelect(.direct) }
                )
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct ExchangeTypeCard: View {
    let title: String
    let description: String
    let selected: Bool
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(selected ? Color("main200") : Color("grey600"))
                Text(description)
                    .pretendardText(size: 12)
                    .foregroundColor(selected ? Color("main200") : Color("grey500"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20).fill(selected ? Color("main100") : Color("white")))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(selected ? Color("main105") : Color("grey200"), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AddressSection (안드 602-704행) — 생성 모드만, tradeType 선택 후 노출

struct AddressSection: View {
    let tradeType: ExchangeType
    let places: [SelectablePlace]
    let selectedPlaceId: Int?
    let onPlaceSelect: (Int) -> Void
    let onManageAddress: (ExchangeType) -> Void

    private var addressLabel: String {
        switch tradeType {
        case .direct: return "희망 교환 장소"
        case .delivery: return "배송지"
        }
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if places.isEmpty {
                addressEmpty
            } else {
                addressList
            }
            Text("주소 관리")
                .pretendardText(size: 14)
                .foregroundColor(Color("grey400"))
                .underline()
                .onTapGesture { onManageAddress(tradeType) }
        }
    }

    private var placeholder: String {
        switch tradeType {
        case .direct: return "희망 교환 장소를 등록해주세요"
        case .delivery: return "배송지를 등록해주세요"
        }
    }

    private var addressEmpty: some View {
        VStack(alignment: .leading, spacing: 0) {
            FieldLabel(text: addressLabel, required: true)
            Text(placeholder)
                .pretendardText(size: 16)
                .foregroundColor(Color("grey400"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color("grey200")))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("grey300"), lineWidth: 1))
                .contentShape(Rectangle())
                .onTapGesture { onManageAddress(tradeType) }
        }
        .frame(maxWidth: .infinity)
    }

    private var addressList: some View {
        VStack(alignment: .leading, spacing: 0) {
            FieldLabel(text: addressLabel, required: true)
            VStack(spacing: 8) {
                ForEach(places) { place in
                    AddressSelectButton(
                        title: place.placeName,
                        address: place.address,
                        selected: place.id == selectedPlaceId,
                        onClick: { onPlaceSelect(place.id) }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// 선택 가능한 주소/장소 카드. 안드 ui/component/AddressButton.kt 대응.
struct AddressSelectButton: View {
    let title: String
    let address: String
    let selected: Bool
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 8) {
                Image("ic_map")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(selected ? Color("main200") : Color("grey500"))

                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .pretendardText(size: 16, weight: .medium)
                        .foregroundColor(selected ? Color("main200") : Color("grey700"))
                    Text(address)
                        .pretendardText(size: 14)
                        .foregroundColor(selected ? Color("grey600") : Color("grey500"))
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(height: 56)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 20).fill(selected ? Color("main100") : Color("white")))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(selected ? Color("main105") : Color("grey200"), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ReadingPeriodSection + ReadingPeriodTrack (안드 706-845행)

struct ReadingPeriodSection: View {
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    private var periods: [Int] { GroupEditorViewModel.periods }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("예상 독서 기간")
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey900"))
                Spacer()
                Text("\(periods[selectedIndex])일")
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("main200"))
            }
            .padding(.bottom, 8)

            VStack(spacing: 8) {
                ReadingPeriodTrack(count: periods.count, selectedIndex: selectedIndex, onSelect: onSelect)

                HStack(spacing: 0) {
                    ForEach(Array(periods.enumerated()), id: \.offset) { index, days in
                        let isSelected = index == selectedIndex
                        let isFilled = index <= selectedIndex
                        Text("\(days)일")
                            .pretendardText(size: 14, weight: isSelected ? .medium : .regular)
                            .foregroundColor(isFilled ? Color("main200") : Color("grey400"))
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture { onSelect(index) }
                    }
                }
            }
        }
    }
}

// 트랙 선택 지점까지 주황 채움 + 균등 배치 점. 점 탭 시 선택. iOS 신규 UI(선례 없음).
struct ReadingPeriodTrack: View {
    let count: Int
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    private let dotSize: CGFloat = 16
    private let trackThickness: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            let trackLength = geo.size.width - dotSize
            let fraction: CGFloat = count <= 1 ? 0 : CGFloat(selectedIndex) / CGFloat(count - 1)

            ZStack(alignment: .leading) {
                // 배경 트랙 (풀폭, 도트 중심 기준 인셋)
                RoundedRectangle(cornerRadius: trackThickness / 2)
                    .fill(Color("grey100"))
                    .frame(height: trackThickness)
                    .padding(.horizontal, dotSize / 2)

                // 채움 트랙
                RoundedRectangle(cornerRadius: trackThickness / 2)
                    .fill(Color("main200"))
                    .frame(width: max(0, trackLength * fraction), height: trackThickness)
                    .padding(.leading, dotSize / 2)

                // 도트 (균등 분산)
                HStack(spacing: 0) {
                    ForEach(0..<count, id: \.self) { index in
                        let isFilled = index <= selectedIndex
                        ZStack {
                            Circle()
                                .fill(isFilled ? Color("main200") : Color("grey100"))
                                .frame(width: dotSize, height: dotSize)
                            if isFilled {
                                Circle()
                                    .fill(Color("white"))
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .contentShape(Circle())
                        .onTapGesture { onSelect(index) }
                        if index < count - 1 {
                            Spacer(minLength: 0)
                        }
                    }
                }
                .frame(width: geo.size.width)
            }
            .frame(height: dotSize)
        }
        .frame(height: dotSize)
    }
}

// MARK: - GroupRuleSection + CustomRuleRow (안드 847-1072행)

struct GroupRuleSection: View {
    let selectedRule: ReadingStyle?
    let onRuleSelect: (ReadingStyle) -> Void
    let customRules: [String]
    let onAddCustomRule: () -> Void
    let onCustomRuleChange: (Int, String) -> Void
    let onRemoveCustomRule: (Int) -> Void

    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(text: "그룹 규칙", required: true)

            ZStack(alignment: .top) {
                Button(action: { expanded.toggle() }) {
                    HStack(spacing: 8) {
                        Text(selectedRule?.label ?? "독서 스타일을 선택해주세요")
                            .pretendardText(size: 16)
                            .foregroundColor(selectedRule != nil ? Color("grey900") : Color("grey400"))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Image("ic_chevron")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(Color("grey500"))
                            .rotationEffect(.degrees(expanded ? 90 : -90))
                    }
                    .padding(.leading, 20)
                    .padding(.trailing, 12)
                    .frame(height: 56)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color("white")))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("grey200"), lineWidth: 1))
                }
                .buttonStyle(.plain)

                if expanded {
                    ruleDropdownList
                        .padding(.top, 64)
                        .zIndex(1)
                }
            }

            ForEach(Array(customRules.enumerated()), id: \.offset) { index, rule in
                CustomRuleRow(
                    value: Binding(
                        get: { rule },
                        set: { onCustomRuleChange(index, $0) }
                    ),
                    onRemove: { onRemoveCustomRule(index) }
                )
            }

            if customRules.count < GroupEditorViewModel.maxCustomRules {
                Button(action: onAddCustomRule) {
                    HStack(spacing: 4) {
                        Image("ic_plus")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Color("grey600"))
                        Text("규칙 추가")
                            .pretendardText(size: 16)
                            .foregroundColor(Color("grey600"))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color("grey100")))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("grey200"), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Text("최소 1개, 최대 5개까지 입력 가능합니다")
                .pretendardText(size: 14)
                .foregroundColor(Color("grey500"))
        }
    }

    private var ruleDropdownList: some View {
        VStack(spacing: 0) {
            ForEach(Array(ReadingStyle.allCases.enumerated()), id: \.offset) { index, style in
                Button(action: {
                    onRuleSelect(style)
                    expanded = false
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color("main100"))
                                .frame(width: 28, height: 28)
                            Image(style.iconName)
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(Color("main200"))
                        }
                        Text(style.label)
                            .pretendardText(size: 14)
                            .foregroundColor(Color("grey900"))
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                if index < ReadingStyle.allCases.count - 1 {
                    Rectangle()
                        .fill(Color("grey100"))
                        .frame(height: 1)
                }
            }
        }
        .padding(.horizontal, 16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color("grey200"), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// 커스텀 규칙 입력 행
struct CustomRuleRow: View {
    @Binding var value: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField("", text: $value, prompt: Text("독서 규칙을 입력해주세요").foregroundColor(Color("grey400")))
                .pretendardText(size: 16)
                .foregroundColor(Color("grey900"))
                .tint(Color("main200"))

            Button(action: onRemove) {
                Image("ic_x")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color("grey500"))
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 20)
        .padding(.trailing, 12)
        .frame(height: 56)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color("white")))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("grey200"), lineWidth: 1))
    }
}

// MARK: - GroupIntroSection (안드 1074-1117행)

struct GroupIntroSection: View {
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FieldLabel(text: "그룹 소개")
            ZStack(alignment: .topLeading) {
                if value.isEmpty {
                    Text("게스트가 꼭 지켜야 할 규칙을 적어주세요.")
                        .pretendardText(size: 16)
                        .foregroundColor(Color("grey500"))
                        // TextEditor 내부 UITextView 인셋(상단 8, 좌측 lineFragmentPadding 5)만큼 밀어 커서와 정렬
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $value)
                    .pretendardText(size: 16)
                    .foregroundColor(Color("grey900"))
                    .scrollContentBackground(.hidden)
            }
            .padding(20)
            .frame(height: 128)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color("white")))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("grey200"), lineWidth: 1))
        }
    }
}

// MARK: - SectionDivider (안드 1119-1128행)

struct GroupEditorSectionDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color("grey100"))
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}
