import Foundation
import Combine
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

// MARK: - 수정 모드 설정

struct GroupEditConfig {
    let groupId: Int
    let bookTitle: String
    let startDate: Date
    let readingPeriod: Int
    let groupComment: String
    let customTag: String          // "" or raw tag (without #)
    let tagCodes: [String]         // e.g. ["MEMO", "SERIOUS"]
}

// MARK: - ViewModel

@MainActor
final class GroupCreateViewModel: ObservableObject {

    enum Phase { case idle, submitting, done, failed }

    let groupType: GroupType
    let editConfig: GroupEditConfig?
    var isEditMode: Bool { editConfig != nil }

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

    init(groupType: GroupType, editConfig: GroupEditConfig? = nil, service: GroupService) {
        self.groupType = groupType
        self.editConfig = editConfig
        self.service = service
        if let config = editConfig {
            self.startDate = config.startDate
            self.readingPeriod = String(config.readingPeriod)
            self.groupComment = config.groupComment
            self.customTag = config.customTag.isEmpty ? "" : "#\(config.customTag)"
            self.selectedTags = Set(config.tagCodes.compactMap { ReadingTag(rawValue: $0) })
        }
    }

    // MARK: - 유효성 검사

    var isFormValid: Bool {
        guard startDate != nil else { return false }
        guard let period = Int(readingPeriod), period >= 3, period <= 30 else { return false }
        guard !selectedTags.isEmpty else { return false }
        guard !groupComment.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        if isEditMode { return true }
        guard selectedBook != nil else { return false }
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
        if let config = editConfig {
            await modify(groupId: config.groupId)
        } else {
            await create()
        }
    }

    private func buildTags() -> [GroupTagRequest] {
        let tagsByType = Dictionary(grouping: Array(selectedTags), by: \.tagType)
        return tagsByType.map { type, items in GroupTagRequest(type: type, value: items.map(\.rawValue)) }
    }

    private func rawCustomTag() -> String {
        customTag.hasPrefix("#") ? String(customTag.dropFirst()) : customTag
    }

    private func create() async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let request = GroupCreateRequest(
            isbn13: selectedBook!.isbn13,
            maxCapacity: groupType == .together ? (Int(maxCapacity) ?? 2) : 2,
            startDate: formatter.string(from: startDate!),
            readingPeriod: Int(readingPeriod)!,
            groupComment: groupComment,
            customTag: rawCustomTag(),
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
            tags: buildTags()
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

    private func modify(groupId: Int) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let request = GroupModifyRequest(
            startDate: formatter.string(from: startDate!),
            readingPeriod: Int(readingPeriod)!,
            groupComment: groupComment,
            customTag: rawCustomTag(),
            tags: buildTags()
        )

        do {
            try await service.modifyGroup(groupId: groupId, body: request)
            toast = "그룹 정보가 정상적으로 수정 되었습니다"
            phase = .done
        } catch let e as GroupServiceError {
            toast = e.errorDescription ?? "그룹 수정에 실패했습니다"
            phase = .idle
        } catch {
            toast = "네트워크 오류가 발생했습니다"
            phase = .idle
        }
    }
}
