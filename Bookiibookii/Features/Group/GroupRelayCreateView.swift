import SwiftUI

struct GroupRelayCreateView: View {
    @StateObject private var viewModel: GroupCreateViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var showDatePicker = false

    init(groupService: GroupService) {
        _viewModel = StateObject(
            wrappedValue: GroupCreateViewModel(groupType: .relay, service: groupService)
        )
    }

    var body: some View {
        ZStack {
            Color("white").ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        bookSearchSection
                        bookHaveSection
                        tradeTypeSection
                        startDateSection
                        readingPeriodSection
                        tagSection
                        commentSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 100)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            submitButton
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .background(Color("white"))
        }
        .sheet(isPresented: $showDatePicker) { datePickerSheet }
        .confirmationDialog(
            "책을 먼저 구매하시겠습니까?",
            isPresented: $viewModel.showBuyDialog,
            titleVisibility: .visible
        ) {
            Button("구매하러 가기") {
                if let url = viewModel.buyURL { openURL(url) }
                viewModel.resetBookHave()
            }
            Button("취소", role: .cancel) { viewModel.resetBookHave() }
        } message: {
            Text(viewModel.selectedBook?.title ?? "선택하신 도서")
        }
        .toast($viewModel.toast)
        .onChange(of: viewModel.phase) { phase in
            if phase == .done { dismiss() }
        }
    }

    // MARK: - 네비게이션 바

    private var navBar: some View {
        ZStack {
            Text("그룹 만들기")
                .font(.pretendard(size: 20, weight: .bold))
                .foregroundColor(Color("grey900"))
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color("grey900"))
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 56)
    }

    // MARK: - 도서 검색

    private var bookSearchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("도서 검색", required: true)
            HStack(spacing: 8) {
                Image("ic_search")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color("grey400"))
                TextField("검색하기", text: $viewModel.searchQuery)
                    .font(.pretendard(size: 14))
                    .foregroundColor(Color("grey900"))
                    .onChange(of: viewModel.searchQuery) { value in
                        viewModel.onSearchQueryChanged(value)
                    }
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("grey200"), lineWidth: 1)
            )
            if viewModel.showSearchResults && !viewModel.searchResults.isEmpty {
                VStack(spacing: 0) {
                    ForEach(viewModel.searchResults) { book in
                        Button { viewModel.selectBook(book) } label: {
                            HStack(spacing: 10) {
                                AsyncImage(url: URL(string: book.image)) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Color("grey200")
                                }
                                .frame(width: 40, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(book.title)
                                        .font(.pretendard(size: 14))
                                        .foregroundColor(Color("grey900"))
                                        .lineLimit(1)
                                    Text(book.author)
                                        .font(.pretendard(size: 12))
                                        .foregroundColor(Color("grey500"))
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        if book.id != viewModel.searchResults.last?.id {
                            Divider().padding(.horizontal, 12)
                        }
                    }
                }
                .background(Color("white"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color("grey200"), lineWidth: 1))
                .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
            }
        }
    }

    // MARK: - 책 소유 여부

    private var bookHaveSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("이 책의 실물을 가지고 계신가요?", required: true)
            HStack(spacing: 12) {
                toggleButton(title: "네",    isSelected: viewModel.bookHave == true)  { viewModel.bookHave = true }
                toggleButton(title: "아니오", isSelected: viewModel.bookHave == false) { viewModel.didTapBookHaveNo() }
            }
            Text("그룹을 생성하려면 실물 책이 필요합니다")
                .font(.pretendard(size: 12))
                .foregroundColor(Color("grey500"))
        }
    }

    // MARK: - 교환 방법

    private var tradeTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("교환 방법", required: true)
            HStack(spacing: 12) {
                toggleButton(title: "택배 교환", isSelected: viewModel.tradeType == .delivery) { viewModel.tradeType = .delivery }
                toggleButton(title: "직접 교환", isSelected: viewModel.tradeType == .direct)   { viewModel.tradeType = .direct }
            }
            if viewModel.tradeType == .direct {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("내 지역", required: true)
                        TextField("시/구", text: $viewModel.preferRegion)
                            .font(.pretendard(size: 14))
                            .foregroundColor(Color("grey900"))
                            .padding(.horizontal, 16)
                            .frame(height: 48)
                            .background(RoundedRectangle(cornerRadius: 12).stroke(Color("grey200"), lineWidth: 1))
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("희망 교환 장소", required: true)
                        TextField("000 경찰서 앞", text: $viewModel.meetPlace)
                            .font(.pretendard(size: 14))
                            .foregroundColor(Color("grey900"))
                            .padding(.horizontal, 16)
                            .frame(height: 48)
                            .background(RoundedRectangle(cornerRadius: 12).stroke(Color("grey200"), lineWidth: 1))
                    }
                }
            }
        }
    }

    // MARK: - 시작 날짜

    private var startDateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("시작 날짜", required: true)
            Button { showDatePicker = true } label: {
                HStack {
                    Text(viewModel.startDate.map { Self.displayFormatter.string(from: $0) } ?? "날짜 선택")
                        .font(.pretendard(size: 14))
                        .foregroundColor(viewModel.startDate == nil ? Color("grey400") : Color("grey900"))
                    Spacer()
                    Image("ic_cal")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color("grey500"))
                }
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(RoundedRectangle(cornerRadius: 12).stroke(Color("grey200"), lineWidth: 1))
            }
            .buttonStyle(.plain)
            Text("독서를 시작할 날짜를 선택해주세요 (익일부터 선택 가능)")
                .font(.pretendard(size: 12))
                .foregroundColor(Color("grey500"))
        }
    }

    // MARK: - 독서 기간

    private var readingPeriodSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("독서 기간", required: true)
            ZStack(alignment: .trailing) {
                TextField("3~30", text: $viewModel.readingPeriod)
                    .font(.pretendard(size: 14))
                    .foregroundColor(Color("grey900"))
                    .keyboardType(.numberPad)
                    .padding(.leading, 16)
                    .padding(.trailing, 40)
                    .frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 12).stroke(Color("grey200"), lineWidth: 1))
                Text("일")
                    .font(.pretendard(size: 14))
                    .foregroundColor(Color("grey400"))
                    .padding(.trailing, 16)
            }
            Text("3일에서 30일 사이로 입력해주세요")
                .font(.pretendard(size: 12))
                .foregroundColor(Color("grey500"))
        }
    }

    // MARK: - 독서 태그

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("독서 태그", required: true)
            FlowLayout(spacing: 8) {
                ForEach(ReadingTag.allCases, id: \.self) { tag in
                    tagChip(tag)
                }
                customTagField
            }
        }
    }

    private func tagChip(_ tag: ReadingTag) -> some View {
        let isSelected = viewModel.selectedTags.contains(tag)
        return Button { viewModel.toggleTag(tag) } label: {
            Text(tag.displayName)
                .font(.pretendard(size: 14))
                .foregroundColor(isSelected ? Color("main200") : Color("grey500"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color("main100") : Color("white"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? Color("main200") : Color("grey200"), lineWidth: 1.5)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private var customTagField: some View {
        TextField("#직접 입력하기", text: $viewModel.customTag)
            .font(.pretendard(size: 14))
            .foregroundColor(viewModel.customTag.isEmpty ? Color("grey500") : Color("main200"))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(viewModel.customTag.isEmpty ? Color("white") : Color("main100"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(viewModel.customTag.isEmpty ? Color("grey200") : Color("main200"), lineWidth: 1.5)
                    )
            )
            .onChange(of: viewModel.customTag) { value in
                let filtered = value.filter { !$0.isWhitespace }
                let limited  = String(filtered.prefix(9))
                if limited != value { viewModel.customTag = limited }
            }
    }

    // MARK: - 그룹 소개

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("그룹 소개", required: true)
            ZStack(alignment: .topLeading) {
                if viewModel.groupComment.isEmpty {
                    Text("게스트가 꼭 지켜야 할 규칙을 적어주세요.")
                        .font(.pretendard(size: 14))
                        .foregroundColor(Color("grey400"))
                        .padding(12)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $viewModel.groupComment)
                    .font(.pretendard(size: 14))
                    .foregroundColor(Color("grey900"))
                    .scrollContentBackground(.hidden)
                    .padding(8)
            }
            .frame(height: 128)
            .background(RoundedRectangle(cornerRadius: 12).stroke(Color("grey200"), lineWidth: 1))
        }
    }

    // MARK: - 제출 버튼

    private var submitButton: some View {
        Button {
            Task { await viewModel.submit() }
        } label: {
            ZStack {
                if viewModel.phase == .submitting {
                    ProgressView().tint(Color("white"))
                } else {
                    Text("그룹 만들기")
                        .font(.pretendard(size: 18, weight: .bold))
                        .foregroundColor(viewModel.isFormValid ? Color("white") : Color("grey500"))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(viewModel.isFormValid ? Color("grey900") : Color("grey200"))
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.phase == .submitting)
    }

    // MARK: - DatePicker 시트

    private var datePickerSheet: some View {
        VStack(spacing: 0) {
            DatePicker(
                "",
                selection: Binding(
                    get: { viewModel.startDate ?? Self.tomorrow },
                    set: { viewModel.startDate = $0 }
                ),
                in: Self.tomorrow...,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            .environment(\.locale, Locale(identifier: "ko_KR"))
            Button("확인") { showDatePicker = false }
                .font(.pretendard(size: 16, weight: .semibold))
                .foregroundColor(Color("white"))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color("grey900"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .presentationDetents([.medium])
    }

    // MARK: - 공통 헬퍼

    private func sectionLabel(_ text: String, required: Bool) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.pretendard(size: 16, weight: .semibold))
                .foregroundColor(Color("grey900"))
            if required {
                Text("*")
                    .font(.pretendard(size: 16))
                    .foregroundColor(Color("main200"))
            }
        }
    }

    private func toggleButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.pretendard(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? Color("main200") : Color("grey500"))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color("main100") : Color("white"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color("main200") : Color("grey200"), lineWidth: 1.5)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        return f
    }()

    private static var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    }
}

// 태그 칩 줄바꿈용 레이아웃
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                height += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}
