import Foundation
import SwiftUI
import Combine

@MainActor
final class GroupDetailViewModel: ObservableObject {
    let groupId: Int
    private let service: GroupService

    enum Phase { case idle, loading, loaded, failed }

    @Published private(set) var detail: GroupDetailDto?
    @Published private(set) var phase: Phase = .idle
    @Published var toast: String?

    @Published var showApplyDialog = false
    @Published var showDeleteConfirm = false
    @Published var showApplicants = false
    @Published var shouldDismiss = false

    @Published private(set) var applicants: [GroupApplicantDto] = []

    init(groupId: Int, service: GroupService) {
        self.groupId = groupId
        self.service = service
    }

    func onAppear() async { await fetchDetail() }

    func fetchDetail() async {
        phase = .loading
        do {
            detail = try await service.fetchGroupDetail(groupId: groupId)
            phase = .loaded
        } catch {
            phase = .failed
            toast = error.localizedDescription
        }
    }

    func applyGroup(msg: String) async {
        do {
            try await service.applyGroup(groupId: groupId, applyMsg: msg)
            showApplyDialog = false
            toast = "그룹 신청 되었습니다."
            await fetchDetail()
        } catch {
            toast = error.localizedDescription
        }
    }

    func cancelApply() async {
        do {
            try await service.cancelApply(groupId: groupId)
            toast = "신청 취소 요청되었습니다."
            shouldDismiss = true
        } catch {
            toast = error.localizedDescription
        }
    }

    func deleteGroup() async {
        do {
            try await service.deleteGroup(groupId: groupId)
            toast = "그룹이 정상적으로 삭제 되었습니다."
            shouldDismiss = true
        } catch {
            toast = error.localizedDescription
        }
    }

    func fetchApplicants() async {
        do {
            applicants = try await service.fetchApplicants(groupId: groupId)
        } catch {
            toast = error.localizedDescription
        }
    }

    func processApplicant(applicationId: Int, status: String, nickname: String) async {
        do {
            try await service.updateApplicant(applicationId: applicationId, status: status)
            applicants.removeAll { $0.applicationId == applicationId }
            let msg = status == "ACCEPTED"
                ? "\(nickname) 님이 게스트가 되었습니다."
                : "\(nickname) 님의 요청을 거절했습니다."
            toast = msg
        } catch {
            toast = error.localizedDescription
        }
    }

    var isHost: Bool { detail?.isHost ?? false }
    var canEdit: Bool { isHost && detail?.groupStatus == "RECRUITING" }

    var displayTags: [String] {
        guard let d = detail else { return [] }
        var all: [String] = []
        if let c = d.customTag, !c.isEmpty { all.append("#\(c)") }
        (d.groupTags ?? []).forEach { all.append(GroupTagMapper.koreanTag($0)) }
        return all
    }

    var buttonLabel: String {
        guard let d = detail else { return "" }
        switch d.buttonStatus {
        case "APPLY":   return "참여 신청하기"
        case "CANCEL":  return "신청 취소하기"
        case "MANAGE":  return "참여 요청 관리"
        case "FULL":    return "모집 완료"
        case "TRACKER": return d.groupType == "TOGETHER" ? "서재 보기" : "트래커 보기"  // groupType nil → RELAY 취급
        default:        return ""
        }
    }

    func handleButtonTap() {
        guard let d = detail else { return }
        switch d.buttonStatus {
        case "APPLY":   showApplyDialog = true
        case "CANCEL":  Task { await cancelApply() }
        case "MANAGE":  showApplicants = true
        case "FULL":    break
        case "TRACKER":
            if d.groupStatus == "RECRUITING" {
                let msg = d.groupType == "TOGETHER"
                    ? "모임이 시작되면 서재가 생성됩니다!"
                    : "모임이 시작되면 트래커가 생성됩니다!"  // nil → RELAY 취급
                toast = msg
            } else {
                shouldDismiss = true
            }
        default: break
        }
    }
}
