import Foundation
import Combine

// 그룹 생성/수정 통합 VM. 안드 group/vm/GroupEditorViewModel.kt(+GroupEditorUiState) 대응.
@MainActor
final class GroupEditorViewModel: ObservableObject {
    let groupId: Int?              // nil=생성, 있으면 수정
    var isEdit: Bool { groupId != nil }

    private let service: GroupService
    private let locationService: LocationService

    // MARK: - 도서 검색 (생성 모드 전용, 수정 모드에서도 필드는 두되 UI에서 안 씀)

    @Published var isbn13: String?
    @Published var bookSearchQuery: String = ""
    @Published private(set) var bookSearchResults: [BookItem] = []
    @Published private(set) var bookSearchLoading = false
    @Published private(set) var bookSearchError: String?

    @Published var groupName: String = ""
    @Published var tradeType: ExchangeType?
    @Published private(set) var places: [SelectablePlace] = []
    @Published private(set) var placesLoading = false
    @Published var selectedPlaceId: Int?

    @Published var readingPeriodIndex: Int = 0
    @Published var groupComment: String = ""
    @Published var ruleStyle: ReadingStyle?
    @Published var customRules: [String] = []

    @Published private(set) var submitting = false

    // 컨트롤러 확정: 생성 성공 시 상세 자동이동 없이 dismiss만. 수정 성공 시 groupId 전달.
    @Published var createdEvent = false
    @Published var updatedGroupId: Int?
    @Published var submitError: String?
    @Published var prefillFailed: String?

    // 사용자 안내용 토스트 (제출 에러·알림 등)
    @Published var toast: String?

    // 수정 모드 프리필 원본 스냅샷 (isDirty 판정용)
    private var editOriginal: EditOriginal?

    private var cancellables = Set<AnyCancellable>()

    static let periods = [3, 7, 14, 21, 28]
    static let maxCustomRules = 4

    struct EditOriginal {
        let groupName: String
        let readingPeriodIndex: Int
        let groupComment: String
        let ruleStyle: ReadingStyle?
        let customRules: [String]
    }

    init(groupId: Int?, service: GroupService, locationService: LocationService) {
        self.groupId = groupId
        self.service = service
        self.locationService = locationService

        // 실시간 도서 검색 디바운스(0.35s, 2자 이상) — 안드 DEFAULT_SEARCH_DEBOUNCE_MS(350L) 대응
        $bookSearchQuery
            .dropFirst()
            .debounce(for: .seconds(0.35), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                guard let self else { return }
                let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.count >= 2 else {
                    self.bookSearchResults = []
                    self.bookSearchError = nil
                    return
                }
                Task { await self.performSearch(trimmed) }
            }
            .store(in: &cancellables)

        if let id = groupId {
            Task { await loadGroupForEdit(id) }
        }
    }

    // MARK: - computed (안드 GroupEditorUiState 25-53행 대응)

    var readingPeriod: Int { Self.periods[readingPeriodIndex] }

    var isDirty: Bool {
        guard let o = editOriginal else { return true }   // 생성 모드는 항상 true
        return groupName != o.groupName
            || readingPeriodIndex != o.readingPeriodIndex
            || groupComment != o.groupComment
            || ruleStyle != o.ruleStyle
            || customRules.filter { !$0.isEmpty } != o.customRules.filter { !$0.isEmpty }
    }

    var canSubmit: Bool {
        let ruleCount = 1 + customRules.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
        guard !groupName.trimmingCharacters(in: .whitespaces).isEmpty,
              groupComment.count <= 500,
              ruleStyle != nil,
              (1...5).contains(ruleCount) else { return false }
        if isEdit { return true }
        return isbn13 != nil && tradeType != nil && selectedPlaceId != nil
    }

    // MARK: - 초기화 + 프리필 (안드 54-101행 대응)

    func loadGroupForEdit(_ id: Int) async {
        do {
            let detail = try await service.fetchGroupDetail(groupId: id)
            let periodIndex = max(0, Self.periods.firstIndex(of: detail.readingPeriod) ?? 0)
            let (style, customs) = splitRules(detail.rules)
            groupName = detail.groupName
            readingPeriodIndex = periodIndex
            groupComment = detail.groupComment ?? ""
            ruleStyle = style
            customRules = customs
            editOriginal = EditOriginal(
                groupName: detail.groupName,
                readingPeriodIndex: periodIndex,
                groupComment: detail.groupComment ?? "",
                ruleStyle: style,
                customRules: customs
            )
        } catch {
            // 안드 Event.PrefillFailed 대응 — 토스트 + 자동 뒤로가기 (View가 관찰해 처리)
            prefillFailed = "그룹 정보를 불러오지 못했어요"
        }
    }

    // apiTag "All_ROUNDER" 등 서버/로컬 케이스 차이를 대비해 대소문자 무시 매칭
    private func splitRules(_ rules: [GroupRule]) -> (ReadingStyle?, [String]) {
        let style = rules.compactMap { r in
            ReadingStyle.allCases.first { $0.apiTag.caseInsensitiveCompare(r.tag) == .orderedSame }
        }.first
        let customs = rules.filter { $0.tag.caseInsensitiveCompare("CUSTOM") == .orderedSame }.map { $0.content }
        return (style, customs)
    }

    // MARK: - 책검색 (안드 112-172행 대응)

    func onBookSearchQueryChange(_ value: String) {
        bookSearchQuery = value
        isbn13 = nil
    }

    // ic_search 클릭 또는 키보드 검색 액션 — 디바운스 기다리지 않고 즉시 검색
    func searchBooks() {
        let trimmed = bookSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Task { await performSearch(trimmed) }
    }

    private func performSearch(_ keyword: String) async {
        // 이미 책을 고른 뒤 늦게 도착한 디바운스 검색이 선택을 덮어쓰지 않도록 가드
        guard isbn13 == nil else { return }
        bookSearchLoading = true
        bookSearchError = nil
        do {
            let results = try await service.searchBooks(keyword: keyword, page: 1, size: 10)
            if isbn13 == nil { bookSearchResults = results }
        } catch {
            bookSearchError = "검색에 실패했어요"
        }
        bookSearchLoading = false
    }

    func onBookSelect(_ book: BookItem) {
        isbn13 = book.isbn13
        bookSearchQuery = book.title
        bookSearchResults = []
        bookSearchError = nil
    }

    // ic_x 클릭. 텍스트 모두 초기화
    func onClearBookSearch() {
        bookSearchQuery = ""
        isbn13 = nil
        bookSearchResults = []
        bookSearchError = nil
    }

    // MARK: - 교환유형/주소 (안드 174-232행 대응)

    func onTradeTypeSelect(_ type: ExchangeType) {
        tradeType = type
        places = []
        selectedPlaceId = nil
        Task { await loadPlaces(type) }
    }

    // 주소관리 화면에서 복귀 시 호출하는 훅(GroupEditorView.onAppear). tradeType 미선택이면 no-op.
    func reloadPlaces() {
        guard let type = tradeType else { return }
        Task { await loadPlaces(type, preserveSelection: true) }
    }

    private func loadPlaces(_ type: ExchangeType, preserveSelection: Bool = false) async {
        placesLoading = true
        do {
            let fetched: [SelectablePlace]
            switch type {
            case .delivery: fetched = try await locationService.fetchDeliveries().map { $0.toSelectablePlace() }
            case .direct:   fetched = try await locationService.fetchExchanges().map { $0.toSelectablePlace() }
            }
            let current = selectedPlaceId
            let keep = preserveSelection && fetched.contains { $0.id == current }
            places = fetched
            selectedPlaceId = keep ? current : (fetched.first { $0.isDefault }?.id ?? fetched.first?.id)
        } catch {
            places = []
            selectedPlaceId = nil
        }
        placesLoading = false
    }

    func onPlaceSelect(_ id: Int) { selectedPlaceId = id }

    // MARK: - 나머지 필드 setter (안드 234-257행 대응)

    func onReadingPeriodSelect(_ index: Int) { readingPeriodIndex = index }
    func onRuleStyleSelect(_ style: ReadingStyle) { ruleStyle = style }
    func onGroupCommentChange(_ value: String) { groupComment = value }
    func onAddCustomRule() {
        guard customRules.count < Self.maxCustomRules else { return }
        customRules.append("")
    }
    func onCustomRuleChange(_ index: Int, _ value: String) {
        guard customRules.indices.contains(index) else { return }
        customRules[index] = value
    }
    func onRemoveCustomRule(_ index: Int) {
        guard customRules.indices.contains(index) else { return }
        customRules.remove(at: index)
    }

    // MARK: - submit (안드 259-339행 대응)

    func submit() async {
        if let id = groupId { await updateGroup(id) } else { await createGroup() }
    }

    private func buildRules() -> [GroupRuleRequest] {
        guard let style = ruleStyle else { return [] }
        var rules = [GroupRuleRequest(tag: style.apiTag, content: nil)]
        rules += customRules.filter { !$0.isEmpty }.map { GroupRuleRequest(tag: "CUSTOM", content: $0) }
        return rules
    }

    private func createGroup() async {
        guard let isbn13, let tradeType, let placeId = selectedPlaceId, ruleStyle != nil, !submitting else { return }
        submitting = true
        defer { submitting = false }
        let isDirect = tradeType == .direct
        let request = GroupCreateRequest(
            isbn13: isbn13,
            groupName: groupName,
            tradeType: isDirect ? "DIRECT" : "DELIVERY",
            userDeliveryId: isDirect ? nil : placeId,
            userExchangeId: isDirect ? placeId : nil,
            readingPeriod: readingPeriod,
            groupComment: groupComment.isEmpty ? nil : groupComment,
            rules: buildRules()
        )
        do {
            try await service.createGroup(request)
            createdEvent = true   // View가 관찰해 dismiss 처리 (2-1: 상세 자동이동은 하지 않음)
        } catch let e as GroupServiceError {
            submitError = e.errorDescription ?? "그룹 생성에 실패했어요"
        } catch {
            submitError = "네트워크 오류가 발생했어요"
        }
    }

    private func updateGroup(_ id: Int) async {
        guard ruleStyle != nil, !submitting else { return }
        submitting = true
        defer { submitting = false }
        let request = GroupModifyRequest(
            readingPeriod: readingPeriod,
            groupComment: groupComment.isEmpty ? nil : groupComment,
            groupName: groupName,
            rules: buildRules()
        )
        do {
            try await service.modifyGroup(groupId: id, body: request)
            updatedGroupId = id
        } catch let e as GroupServiceError {
            submitError = e.errorDescription ?? "그룹 수정에 실패했어요"
        } catch {
            submitError = "네트워크 오류가 발생했어요"
        }
    }
}
