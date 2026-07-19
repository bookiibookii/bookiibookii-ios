import Foundation
import SwiftUI
import Combine

// 그룹 상세 VM. 안드 GroupDetailViewModel + JoinRequestViewModel(게스트부) 대응.
@MainActor
final class GroupDetailViewModel: ObservableObject {
    let groupId: Int
    private let service: GroupService
    private var location: LocationService?

    enum Phase { case idle, loading, loaded, failed }

    @Published private(set) var detail: GroupDetailDto?
    @Published private(set) var phase: Phase = .idle
    @Published var toast: String?
    @Published var shouldDismiss = false

    // 다이얼로그 플래그
    @Published var showApplyDialog = false
    @Published var showDeleteDialog = false
    @Published var showAddressRequiredDialog = false
    @Published var showApplicants = false   // MANAGE — 기존 GroupApplicantView 재사용

    // 신청 다이얼로그 상태 (안드 JoinRequestViewModel.GroupApplyUiState 대응)
    @Published var bookSearchQuery: String = ""
    @Published private(set) var bookSearchResults: [BookItem] = []
    @Published var bookSearchLoading = false
    @Published private(set) var selectedISBN: String?
    @Published var applyMsg: String = ""
    @Published private(set) var submitting = false

    // 호스트용 신청자 명단 (GroupApplicantView가 참조)
    @Published private(set) var applicants: [GroupApplicantDto] = []

    private var isCheckingAddress = false
    private var isCanceling = false
    private var isDeleting = false

    init(groupId: Int, service: GroupService) {
        self.groupId = groupId
        self.service = service
    }

    /// 진입 시그니처(groupId:groupService:) 유지를 위해 뷰가 container.api.location을 조회 시점에 주입.
    func attachLocationService(_ service: LocationService) {
        guard location == nil else { return }
        location = service
    }

    var canSubmit: Bool {
        selectedISBN != nil && !applyMsg.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !submitting
    }

    // MARK: - 액션버튼 매퍼 (안드 groupDetailActionButton)

    var actionButton: (text: String, style: CardButtonStyle)? {
        guard let d = detail else { return nil }
        switch d.buttonStatus {
        case "APPLY":  return ("참여 신청하기", .main)
        case "MANAGE": return ("참여 요청 관리 (\(d.waitingCount))", .main)
        case "CANCEL": return ("참여 신청 취소", .mainPale)
        default:       return nil
        }
    }

    // MARK: - 조회

    func onAppear() async { await fetchDetail() }

    func retry() { Task { await fetchDetail() } }

    /// 에러를 토스트로 표시하되, 태스크/URLSession 취소(-999)는 실제 에러가 아니므로 무시한다.
    /// (화면 전환 churn 으로 in-flight 요청이 취소되면 localizedDescription 이 "cancelled" 로 뜨는 것 방지)
    private func toastError(_ error: Error) {
        if error is CancellationError { return }
        if let e = error as? URLError, e.code == .cancelled { return }
        let message = error.localizedDescription
        toast = message
    }

    func fetchDetail() async {
        phase = .loading
        do {
            detail = try await service.fetchGroupDetail(groupId: groupId)
            phase = .loaded
        } catch {
            phase = .failed
            toastError(error)
        }
    }

    // MARK: - 액션 탭 (안드 GroupDetailRoute.onActionClick 대응)

    func handleActionTap() {
        guard let d = detail else { return }
        switch d.buttonStatus {
        case "APPLY":  Task { await checkAddressBeforeApply() }
        case "MANAGE": showApplicants = true
        case "CANCEL": Task { await cancelApply() }
        default: break
        }
    }

    // 참여 신청 전 배송지/희망 교환 장소 등록 여부 확인
    private func checkAddressBeforeApply() async {
        guard !isCheckingAddress, let d = detail, let location else { return }
        isCheckingAddress = true
        defer { isCheckingAddress = false }
        do {
            let hasAddress: Bool
            if d.tradeType == "DIRECT" {
                hasAddress = try await !location.fetchExchanges().isEmpty
            } else {
                hasAddress = try await !location.fetchDeliveries().isEmpty
            }
            if hasAddress {
                showApplyDialog = true
            } else {
                showAddressRequiredDialog = true
            }
        } catch {
            toastError(error)
        }
    }

    // MARK: - 책 검색

    func onBookQueryChange(_ value: String) {
        bookSearchQuery = value
        selectedISBN = nil
    }

    // 검색 버튼/키보드 액션 — 즉시 검색
    func searchBooks() {
        let trimmed = bookSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Task { await performSearch(keyword: trimmed) }
    }

    private func performSearch(keyword: String) async {
        // 이미 책을 고른 뒤 늦게 도착한 검색이 선택을 덮어쓰지 않도록 가드
        guard selectedISBN == nil else { return }
        bookSearchLoading = true
        do {
            let results = try await service.searchBooks(keyword: keyword, page: 1, size: 10)
            if selectedISBN == nil { bookSearchResults = results }
        } catch {
            toastError(error)
        }
        bookSearchLoading = false
    }

    func selectBook(_ book: BookItem) {
        selectedISBN = book.isbn13
        bookSearchQuery = book.title
        bookSearchResults = []
    }

    func clearBookSearch() {
        bookSearchQuery = ""
        selectedISBN = nil
        bookSearchResults = []
    }

    func onApplyMsgChange(_ value: String) {
        applyMsg = value.count > 50 ? String(value.prefix(50)) : value
    }

    // MARK: - 신청 제출

    func submitApply() {
        guard let isbn = selectedISBN, canSubmit else { return }
        submitting = true
        Task {
            do {
                try await service.applyGroup(groupId: groupId, isbn13: isbn, applyMsg: applyMsg)
                showApplyDialog = false
                resetApplyDialog()
                await fetchDetail()
            } catch {
                toastError(error)
            }
            submitting = false
        }
    }

    func resetApplyDialog() {
        bookSearchQuery = ""
        bookSearchResults = []
        selectedISBN = nil
        applyMsg = ""
    }

    // MARK: - 신청 취소

    func cancelApply() async {
        guard !isCanceling else { return }
        isCanceling = true
        defer { isCanceling = false }
        do {
            try await service.cancelApply(groupId: groupId)
            toast = "참여 신청을 취소했어요"
            await fetchDetail()
        } catch {
            toastError(error)
        }
    }

    // MARK: - 삭제

    func confirmDelete() {
        guard !isDeleting else { return }
        isDeleting = true
        Task {
            do {
                try await service.deleteGroup(groupId: groupId)
                shouldDismiss = true
            } catch {
                toastError(error)
            }
            isDeleting = false
        }
    }

    // 주소관리 진입 시 열 탭. 그룹 교환유형 DIRECT=희망교환장소, 그 외/nil=배송지.
    var addressManagementTab: AddressManagementTab {
        detail?.tradeType == "DIRECT" ? .exchange : .delivery
    }

    // MARK: - 신청자 관리 (기존 GroupApplicantView 재사용)

    func fetchApplicants() async {
        do {
            applicants = try await service.fetchApplicants(groupId: groupId)
        } catch {
            toastError(error)
        }
    }

    func processApplicant(applicationId: Int, status: String, nickname: String) async {
        do {
            try await service.updateApplicant(applicationId: applicationId, status: status)
            applicants.removeAll { $0.applicationId == applicationId }
            toast = status == "ACCEPTED"
                ? "\(nickname) 님의 요청을 수락했어요"
                : "\(nickname) 님의 요청을 거절했어요"
            if status == "ACCEPTED" {
                await fetchDetail()
            }
        } catch {
            toastError(error)
        }
    }
}
