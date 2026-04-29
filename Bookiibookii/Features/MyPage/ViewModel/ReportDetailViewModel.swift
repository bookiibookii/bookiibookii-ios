import Foundation
import Combine

final class ReportDetailViewModel: ObservableObject {
    static let maxContentLength = 1000

    let cautionTitle = "신고 시 유의사항"
    let cautionMessage = "허위 신고는 제재 대상이 될 수 있습니다. 정확하고 객관적인 사실만 작성해 주세요."
    let groupSectionTitle = "신고 그룹 *"
    let memberSectionTitle = "신고 멤버"
    let reasonSectionTitle = "신고 유형 *"
    let contentSectionTitle = "신고 내용 *"
    let groupPlaceholder = "신고할 그룹을 선택해주세요"
    let memberPlaceholder = "신고할 멤버를 선택해주세요"
    let contentPlaceholder = "구체적인 상황을 설명해주세요."

    @Published var groups: [ReportGroup] = ReportGroup.preview
    @Published var selectedGroup: ReportGroup?
    @Published var selectedMember: ReportMember?
    @Published var selectedReason: ReportReason?
    @Published var content = ""
    @Published var isGroupListExpanded = false
    @Published var isMemberListExpanded = false

    var myGroups: [ReportGroup] {
        groups.filter(\.isMyGroup)
    }

    var joinedGroups: [ReportGroup] {
        groups.filter { !$0.isMyGroup }
    }

    var groupFieldText: String {
        selectedGroup?.displayTitle ?? groupPlaceholder
    }

    var memberFieldText: String {
        selectedMember?.name ?? memberPlaceholder
    }

    var isGroupSelected: Bool {
        selectedGroup != nil
    }

    var isMemberSelected: Bool {
        selectedMember != nil
    }

    var membersForSelectedGroup: [ReportMember] {
        selectedGroup?.members ?? []
    }

    var canSubmit: Bool {
        selectedGroup != nil && selectedReason != nil && !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func toggleGroupList() {
        isGroupListExpanded.toggle()
        if isGroupListExpanded {
            isMemberListExpanded = false
        }
    }

    func toggleMemberList() {
        guard selectedGroup != nil else { return }
        isMemberListExpanded.toggle()
        if isMemberListExpanded {
            isGroupListExpanded = false
        }
    }

    func selectGroup(_ group: ReportGroup) {
        selectedGroup = group
        selectedMember = nil
        isGroupListExpanded = false
    }

    func selectMember(_ member: ReportMember) {
        selectedMember = member
        isMemberListExpanded = false
    }

    func selectReason(_ reason: ReportReason) {
        selectedReason = reason
    }

    func updateContent(_ text: String) {
        if text.count > Self.maxContentLength {
            content = String(text.prefix(Self.maxContentLength))
            return
        }
        content = text
    }

    func makeDraftForSubmit() -> ReportSubmitDraft? {
        guard let selectedGroup,
              let selectedReason,
              canSubmit
        else { return nil }

        return ReportSubmitDraft(
            groupTitle: selectedGroup.bookTitle,
            reason: selectedReason,
            content: content.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

