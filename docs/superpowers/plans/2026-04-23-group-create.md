# 그룹 생성 기능 구현 플랜

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 그룹 탭 FAB에서 이어읽기(RELAY) / 함께읽기(TOGETHER) 타입별 그룹 생성 폼을 fullScreenCover로 표시하고, 도서 검색 + 폼 입력 후 `POST /api/groups`로 생성 완료.

**Architecture:** 공통 `GroupCreateViewModel(groupType:)` 하나에 모든 상태/검증/API 로직을 집중시키고, `GroupRelayCreateView`와 `GroupTogetherCreateView`가 각자의 폼 UI만 담당. `GroupView`의 FAB 콜백에서 `fullScreenCover`로 진입.

**Tech Stack:** SwiftUI, async/await, URLSession (기존 AuthInterceptor 사용), `@MainActor` ViewModel, `@Environment(\.dismiss)` / `@Environment(\.openURL)`

---

## 파일 구조

| 파일 | 작업 |
|---|---|
| `Bookiibookii/Data/Models/GroupModels.swift` | 수정 — BookItem, BookSearchAPIResponse, GroupCreateRequest, GroupTagRequest 추가 |
| `Bookiibookii/Data/API/GroupService.swift` | 수정 — searchBooks(), createGroup() 추가 |
| `Bookiibookii/Features/Group/GroupCreateViewModel.swift` | 신규 — 공통 ViewModel + GroupType, TradeType, ReadingTag enum |
| `Bookiibookii/Features/Group/GroupRelayCreateView.swift` | 신규 — 이어읽기 생성 폼 |
| `Bookiibookii/Features/Group/GroupTogetherCreateView.swift` | 신규 — 함께읽기 생성 폼 |
| `Bookiibookii/Features/Group/GroupView.swift` | 수정 — FAB → fullScreenCover 연결 |

---

## Task 1: 데이터 모델 추가

**Files:**
- Modify: `Bookiibookii/Data/Models/GroupModels.swift`

- [ ] **Step 1: GroupModels.swift 끝에 도서 검색 + 그룹 생성 모델 추가**

파일 맨 아래에 추가:

```swift
// MARK: - 도서 검색

struct BookSearchAPIResponse: Codable {
    let isSuccess: Bool
    let code: String
    let message: String
    let result: BookSearchResultData?
}

struct BookSearchResultData: Codable {
    let books: [BookItem]
    let totalPage: Int
    let totalResults: Int
}

struct BookItem: Codable, Identifiable {
    let title: String
    let author: String
    let image: String
    let publisher: String
    let isbn13: String
    let category: String
    let categoryLabel: String
    let link: String
    var id: String { isbn13 }
}

// MARK: - 그룹 생성 요청

struct GroupCreateRequest: Encodable {
    let isbn13: String
    let maxCapacity: Int
    let startDate: String          // "yyyy-MM-dd"
    let readingPeriod: Int
    let groupComment: String
    let customTag: String          // 없으면 ""
    let groupType: String          // "RELAY" | "TOGETHER"
    let tradeType: String          // "DELIVERY" | "DIRECT" | "NONE"
    let preferRegion: String       // 없으면 ""
    let meetPlace: String          // 없으면 ""
    let tags: [GroupTagRequest]
}

struct GroupTagRequest: Encodable {
    let type: String               // "METHOD" | "VIBE"
    let value: [String]
}
```

- [ ] **Step 2: 빌드 확인**

Xcode에서 `⌘B` 빌드. 에러 없이 통과해야 함.

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Data/Models/GroupModels.swift
git commit -m "feat: 도서 검색·그룹 생성 데이터 모델 추가"
```

---

## Task 2: GroupService 확장

**Files:**
- Modify: `Bookiibookii/Data/API/GroupService.swift`

- [ ] **Step 1: searchBooks 메서드 추가**

`GroupService` 클래스의 `searchGroups` 메서드 아래에 추가:

```swift
/// GET /api/books/search?keyword=&page=&size=
func searchBooks(keyword: String, page: Int = 1, size: Int = 10) async throws -> [BookItem] {
    var components = URLComponents(
        url: baseURL.appendingPathComponent("api/books/search"),
        resolvingAgainstBaseURL: false
    )!
    components.queryItems = [
        URLQueryItem(name: "keyword", value: keyword),
        URLQueryItem(name: "page",    value: String(page)),
        URLQueryItem(name: "size",    value: String(size))
    ]
    var request = URLRequest(url: components.url!)
    request.httpMethod = "GET"
    let (data, http) = try await interceptor.request(request)
    guard (200...299).contains(http.statusCode) else {
        throw GroupServiceError.http(http.statusCode)
    }
    let response = try JSONDecoder().decode(BookSearchAPIResponse.self, from: data)
    guard response.isSuccess, let result = response.result else {
        throw GroupServiceError.server(response.message)
    }
    return result.books
}
```

- [ ] **Step 2: createGroup 메서드 추가**

`searchBooks` 바로 아래에 추가:

```swift
/// POST /api/groups
func createGroup(_ body: GroupCreateRequest) async throws {
    let url = baseURL.appendingPathComponent("api/groups")
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(body)
    let (data, http) = try await interceptor.request(request)
    guard (200...299).contains(http.statusCode) else {
        if let msg = (try? JSONDecoder().decode(APIErrorMessage.self, from: data))?.message {
            throw GroupServiceError.server(msg)
        }
        throw GroupServiceError.http(http.statusCode)
    }
}

// 에러 바디 파싱용 — 이 파일 안에만 사용
private struct APIErrorMessage: Decodable { let message: String }
```

- [ ] **Step 3: 빌드 확인 후 커밋**

```bash
git add Bookiibookii/Data/API/GroupService.swift
git commit -m "feat: GroupService에 도서 검색·그룹 생성 API 추가"
```

---

## Task 3: GroupCreateViewModel 생성

**Files:**
- Create: `Bookiibookii/Features/Group/GroupCreateViewModel.swift`

- [ ] **Step 1: 파일 생성**

```swift
import Foundation
import SwiftUI

// MARK: - 보조 enum

enum GroupType { case relay, together }
enum TradeType { case delivery, direct }

enum ReadingTag: String, CaseIterable {
    case memo     = "MEMO"
    case postit   = "POSTIT"
    case clean    = "CLEAN"
    case serious  = "SERIOUS"
    case lightFun = "LIGHT_FUN"
    case insight  = "INSIGHT"

    var displayName: String {
        switch self {
        case .memo:     return "#메모환영"
        case .postit:   return "#포스트잇"
        case .clean:    return "#깔끔"
        case .serious:  return "#진지함"
        case .lightFun: return "#재미있게"
        case .insight:  return "#인사이트"
        }
    }

    var tagType: String {
        switch self {
        case .memo, .postit, .clean:       return "METHOD"
        case .serious, .lightFun, .insight: return "VIBE"
        }
    }
}

// MARK: - ViewModel

@MainActor
final class GroupCreateViewModel: ObservableObject {

    enum Phase { case idle, submitting, done, failed }

    let groupType: GroupType

    // 도서 검색
    @Published var searchQuery: String = ""
    @Published private(set) var searchResults: [BookItem] = []
    @Published var showSearchResults: Bool = false
    @Published private(set) var selectedBook: BookItem? = nil

    // RELAY 전용
    @Published var bookHave: Bool? = nil
    @Published var tradeType: TradeType? = nil
    @Published var preferRegion: String = ""
    @Published var meetPlace: String = ""
    @Published var showBuyDialog: Bool = false

    // TOGETHER 전용
    @Published var maxCapacity: String = ""

    // 공통
    @Published var startDate: Date? = nil
    @Published var readingPeriod: String = ""
    @Published var selectedTags: Set<ReadingTag> = []
    @Published var customTag: String = ""
    @Published var groupComment: String = ""

    // 상태
    @Published private(set) var phase: Phase = .idle
    @Published var toast: String? = nil

    private let service: GroupService
    private var searchTask: Task<Void, Never>?

    init(groupType: GroupType, service: GroupService) {
        self.groupType = groupType
        self.service = service
    }

    // MARK: - 유효성 검사

    var isFormValid: Bool {
        guard selectedBook != nil else { return false }
        guard startDate != nil else { return false }
        guard let period = Int(readingPeriod), period >= 3, period <= 30 else { return false }
        guard !selectedTags.isEmpty else { return false }
        guard !groupComment.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        switch groupType {
        case .relay:
            guard bookHave != nil else { return false }
            guard let trade = tradeType else { return false }
            if trade == .direct {
                guard !preferRegion.trimmingCharacters(in: .whitespaces).isEmpty,
                      !meetPlace.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
            }
        case .together:
            guard let cap = Int(maxCapacity), cap >= 2, cap <= 8 else { return false }
        }
        return true
    }

    // MARK: - 도서 검색

    func onSearchQueryChanged(_ query: String) {
        if query == selectedBook?.title { return }
        selectedBook = nil
        searchTask?.cancel()
        searchResults = []
        showSearchResults = false
        guard query.count >= 2 else { return }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            await performSearch(query: query)
        }
    }

    func selectBook(_ book: BookItem) {
        selectedBook = book
        searchQuery = book.title
        searchResults = []
        showSearchResults = false
        searchTask?.cancel()
    }

    private func performSearch(query: String) async {
        do {
            let results = try await service.searchBooks(keyword: query)
            searchResults = results
            showSearchResults = !results.isEmpty
        } catch {
            searchResults = []
            showSearchResults = false
        }
    }

    // MARK: - 태그

    func toggleTag(_ tag: ReadingTag) {
        if selectedTags.contains(tag) { selectedTags.remove(tag) }
        else { selectedTags.insert(tag) }
    }

    // MARK: - 책 소유 여부 (RELAY)

    func didTapBookHaveNo() {
        bookHave = false
        showBuyDialog = true
    }

    func resetBookHave() {
        bookHave = nil
        showBuyDialog = false
    }

    var buyURL: URL? {
        selectedBook.flatMap { URL(string: $0.link) }
    }

    // MARK: - 제출

    func submit() async {
        guard isFormValid, phase == .idle else { return }
        phase = .submitting

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let tagsByType = Dictionary(grouping: Array(selectedTags), by: \.tagType)
        let tags = tagsByType.map { type, items in
            GroupTagRequest(type: type, value: items.map(\.rawValue))
        }

        let rawCustomTag = customTag.hasPrefix("#") ? String(customTag.dropFirst()) : customTag

        let request = GroupCreateRequest(
            isbn13: selectedBook!.isbn13,
            maxCapacity: groupType == .together ? (Int(maxCapacity) ?? 2) : 2,
            startDate: formatter.string(from: startDate!),
            readingPeriod: Int(readingPeriod)!,
            groupComment: groupComment,
            customTag: rawCustomTag,
            groupType: groupType == .relay ? "RELAY" : "TOGETHER",
            tradeType: {
                switch tradeType {
                case .delivery: return "DELIVERY"
                case .direct:   return "DIRECT"
                case nil:       return "NONE"
                }
            }(),
            preferRegion: preferRegion,
            meetPlace: meetPlace,
            tags: tags
        )

        do {
            try await service.createGroup(request)
            toast = "그룹 생성 완료되었습니다"
            phase = .done
        } catch let e as GroupServiceError {
            toast = e.errorDescription ?? "그룹 생성에 실패했습니다"
            phase = .idle
        } catch {
            toast = "네트워크 오류가 발생했습니다"
            phase = .idle
        }
    }
}
```

- [ ] **Step 2: 빌드 확인 후 커밋**

```bash
git add Bookiibookii/Features/Group/GroupCreateViewModel.swift
git commit -m "feat: GroupCreateViewModel 추가 (공통 로직 + enum 정의)"
```

---

## Task 4: GroupRelayCreateView 생성

**Files:**
- Create: `Bookiibookii/Features/Group/GroupRelayCreateView.swift`

- [ ] **Step 1: 파일 생성**

```swift
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
            if phase == .done {
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    dismiss()
                }
            }
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
                            HStack {
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
```

- [ ] **Step 2: FlowLayout 컴포넌트 추가**

태그 칩을 줄바꿈 처리하기 위해 `GroupRelayCreateView.swift` 파일 맨 아래에 추가:

```swift
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
```

- [ ] **Step 3: 빌드 확인 후 커밋**

```bash
git add Bookiibookii/Features/Group/GroupRelayCreateView.swift
git commit -m "feat: GroupRelayCreateView 이어읽기 생성 폼 추가"
```

---

## Task 5: GroupTogetherCreateView 생성

**Files:**
- Create: `Bookiibookii/Features/Group/GroupTogetherCreateView.swift`

- [ ] **Step 1: 파일 생성**

GroupRelayCreateView와 구조 동일, RELAY 전용 섹션 없이 `maxCapacity` 섹션 추가.

```swift
import SwiftUI

struct GroupTogetherCreateView: View {
    @StateObject private var viewModel: GroupCreateViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDatePicker = false

    init(groupService: GroupService) {
        _viewModel = StateObject(
            wrappedValue: GroupCreateViewModel(groupType: .together, service: groupService)
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
                        maxCapacitySection
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
        .toast($viewModel.toast)
        .onChange(of: viewModel.phase) { phase in
            if phase == .done {
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    dismiss()
                }
            }
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
            .background(RoundedRectangle(cornerRadius: 12).stroke(Color("grey200"), lineWidth: 1))
            if viewModel.showSearchResults && !viewModel.searchResults.isEmpty {
                VStack(spacing: 0) {
                    ForEach(viewModel.searchResults) { book in
                        Button { viewModel.selectBook(book) } label: {
                            HStack {
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

    // MARK: - 최대 인원

    private var maxCapacitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("최대 인원", required: true)
            ZStack(alignment: .trailing) {
                TextField("2~8", text: $viewModel.maxCapacity)
                    .font(.pretendard(size: 14))
                    .foregroundColor(Color("grey900"))
                    .keyboardType(.numberPad)
                    .padding(.leading, 16)
                    .padding(.trailing, 40)
                    .frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 12).stroke(Color("grey200"), lineWidth: 1))
                Text("명")
                    .font(.pretendard(size: 14))
                    .foregroundColor(Color("grey400"))
                    .padding(.trailing, 16)
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
```

- [ ] **Step 2: 빌드 확인 후 커밋**

```bash
git add Bookiibookii/Features/Group/GroupTogetherCreateView.swift
git commit -m "feat: GroupTogetherCreateView 함께읽기 생성 폼 추가"
```

---

## Task 6: GroupView FAB 연결

**Files:**
- Modify: `Bookiibookii/Features/Group/GroupView.swift`

- [ ] **Step 1: 상태 추가 및 FAB 콜백 교체**

`GroupView` 상단의 `@State` 변수에 추가:

```swift
// 기존
@State private var activeSheet: ActiveSheet? = nil
@State private var isFabOpen: Bool = false
@State private var isSearchPresented: Bool = false

// 추가
@State private var activeCreate: CreateType? = nil

enum CreateType: String, Identifiable {
    case relay, together
    var id: String { rawValue }
}
```

FAB 콜백 교체 (기존 `showComingSoon` 대신):

```swift
// 기존
GroupFabMenu(
    isOpen: $isFabOpen,
    onTapTogether: { viewModel.showComingSoon("그룹 만들기는 준비 중입니다") },
    onTapRelay:    { viewModel.showComingSoon("그룹 만들기는 준비 중입니다") }
)

// 변경
GroupFabMenu(
    isOpen: $isFabOpen,
    onTapTogether: {
        withAnimation(.easeOut(duration: 0.25)) { isFabOpen = false }
        activeCreate = .together
    },
    onTapRelay: {
        withAnimation(.easeOut(duration: 0.25)) { isFabOpen = false }
        activeCreate = .relay
    }
)
```

- [ ] **Step 2: fullScreenCover 추가**

기존 `.fullScreenCover(isPresented: $isSearchPresented)` 아래에 추가:

```swift
.fullScreenCover(item: $activeCreate) { type in
    switch type {
    case .relay:
        GroupRelayCreateView(groupService: container.api.group)
    case .together:
        GroupTogetherCreateView(groupService: container.api.group)
    }
}
```

- [ ] **Step 3: 빌드 확인**

Xcode에서 `⌘B`. 에러 없이 통과해야 함.

- [ ] **Step 4: 시뮬레이터에서 동작 확인**

1. 그룹 탭 진입
2. 우하단 FAB(`+`) 탭 → 메뉴 열림
3. "이어읽기" 탭 → `GroupRelayCreateView` fullScreenCover 진입
4. "함께읽기" 탭 → `GroupTogetherCreateView` fullScreenCover 진입
5. 뒤로가기(`chevron.left`) 탭 → 이전 화면 복귀

- [ ] **Step 5: 커밋**

```bash
git add Bookiibookii/Features/Group/GroupView.swift
git commit -m "feat: 그룹 생성 FAB → fullScreenCover 연결"
```
