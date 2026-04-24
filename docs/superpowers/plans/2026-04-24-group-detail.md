# Group Detail Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** GroupView/GroupSearchView 카드 탭 → 그룹 세부 화면(GroupDetailView) 진입, 신청/취소/호스트 신청자 관리/삭제 구현

**Architecture:** 접근법 B — GroupDetailViewModel 하나로 GroupDetailView + GroupApplicantView 공유. fullScreenCover로 진입. 댓글은 feat/#19로 분리.

**Tech Stack:** SwiftUI, Combine, async/await, Kingfisher(KFImage), URLSession + AuthInterceptor

---

## File Map

| 파일 | 작업 |
|------|------|
| `Bookiibookii/Data/Models/GroupModels.swift` | GroupDetailDto 등 7개 모델 추가 |
| `Bookiibookii/Data/API/GroupService.swift` | 6개 메서드 추가 |
| `Bookiibookii/Features/Group/GroupDetailViewModel.swift` | 신규 생성 |
| `Bookiibookii/Features/Group/GroupDetailView.swift` | 신규 생성 |
| `Bookiibookii/Features/Group/GroupApplicantView.swift` | 신규 생성 |
| `Bookiibookii/Features/Group/GroupView.swift` | 카드 탭 연결 |
| `Bookiibookii/Features/Group/GroupSearchView.swift` | 카드 탭 연결 |

---

## Task 1: GroupModels.swift — 상세 화면용 모델 추가

**Files:**
- Modify: `Bookiibookii/Data/Models/GroupModels.swift`

- [ ] **Step 1: 파일 끝에 모델 블록 추가**

`GroupModels.swift` 파일 맨 끝에 아래 코드를 추가한다.

```swift
// MARK: - 그룹 상세

struct GroupDetailResponse: Codable {
    let isSuccess: Bool
    let code: String
    let message: String
    let result: GroupDetailDto?
}

struct GroupDetailDto: Codable {
    let groupId: Int
    let title: String
    let bookTitle: String
    let bookImage: String?
    let author: String
    let category: String
    let groupStatus: String       // RECRUITING | MATCHED | COMPLETED
    let buttonStatus: String      // APPLY | CANCEL | MANAGE | FULL | TRACKER
    let isHost: Bool
    let readingPeriod: Int
    let matchedCount: Int
    let maxCapacity: Int
    let waitingCount: Int
    let isHot: Bool
    let createdAt: String
    let startDate: String
    let hostNickname: String
    let hostProfileImageUrl: String?
    let preferRegion: String?
    let meetPlace: String?
    let groupTags: [String]?
    let customTag: String?
    let groupComment: String?
    let participantSlots: [ParticipantSlot]?
    let groupType: String
}

struct ParticipantSlot: Codable {
    let nickname: String?
    let profileImageUrl: String?
    let role: String              // HOST | GUEST | EMPTY
    let isMe: Bool
}

// MARK: - 신청 / 취소

struct GroupApplyRequest: Encodable {
    let applyMsg: String
}

struct GroupApplyResultWrapper: Codable {
    let isSuccess: Bool
    let code: String
    let message: String
}

struct GroupCancelResultWrapper: Codable {
    let isSuccess: Bool
    let code: String
    let message: String
}

// MARK: - 신청자 목록 (호스트용)

struct GroupApplicantListResponse: Codable {
    let isSuccess: Bool
    let code: String
    let message: String
    let result: GroupApplicantListResult?
}

struct GroupApplicantListResult: Codable {
    let applicationList: [GroupApplicantDto]
    let totalCount: Int
}

struct GroupApplicantDto: Codable, Identifiable {
    let applicationId: Int
    let user: Int
    let name: String
    let tags: [String]?
    let createdAt: String
    let applyMsg: String
    let profileImageUrl: String?
    var id: Int { applicationId }
}

struct GroupAppStatusRequest: Encodable {
    let status: String            // ACCEPTED | REJECTED
}

struct GroupAppStatusResponse: Codable {
    let isSuccess: Bool
    let code: String
    let message: String
}

struct GroupDeleteResultWrapper: Codable {
    let isSuccess: Bool
    let code: String
    let message: String
}
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build \
  2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Data/Models/GroupModels.swift
git commit -m "feat: 그룹 상세 화면용 데이터 모델 추가"
```

---

## Task 2: GroupService.swift — 상세 화면용 API 메서드 추가

**Files:**
- Modify: `Bookiibookii/Data/API/GroupService.swift`

- [ ] **Step 1: `createGroup` 메서드 바로 위(마지막 메서드 뒤, `private struct` 앞)에 6개 메서드 삽입**

`GroupService` 클래스 내 `createGroup` 메서드 다음, `private struct APIErrorMessage` 선언 바로 위에 아래를 삽입한다.

```swift
    /// GET /api/groups/{groupId}
    func fetchGroupDetail(groupId: Int) async throws -> GroupDetailDto {
        let url = baseURL.appendingPathComponent("api/groups/\(groupId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw GroupServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(GroupDetailResponse.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw GroupServiceError.server(response.message)
        }
        return result
    }

    /// POST /api/groups/{groupId}/apply
    func applyGroup(groupId: Int, applyMsg: String) async throws {
        let url = baseURL.appendingPathComponent("api/groups/\(groupId)/apply")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(GroupApplyRequest(applyMsg: applyMsg))
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            if let msg = (try? JSONDecoder().decode(APIErrorMessage.self, from: data))?.message {
                throw GroupServiceError.server(msg)
            }
            throw GroupServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(GroupApplyResultWrapper.self, from: data)
        guard response.isSuccess else { throw GroupServiceError.server(response.message) }
    }

    /// DELETE /api/groups/{groupId}/apply
    func cancelApply(groupId: Int) async throws {
        let url = baseURL.appendingPathComponent("api/groups/\(groupId)/apply")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            if let msg = (try? JSONDecoder().decode(APIErrorMessage.self, from: data))?.message {
                throw GroupServiceError.server(msg)
            }
            throw GroupServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(GroupCancelResultWrapper.self, from: data)
        guard response.isSuccess else { throw GroupServiceError.server(response.message) }
    }

    /// GET /api/groups/{groupId}/applications
    func fetchApplicants(groupId: Int) async throws -> [GroupApplicantDto] {
        let url = baseURL.appendingPathComponent("api/groups/\(groupId)/applications")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw GroupServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(GroupApplicantListResponse.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw GroupServiceError.server(response.message)
        }
        return result.applicationList
    }

    /// PUT /api/applications/{applicationId}
    func updateApplicant(applicationId: Int, status: String) async throws {
        let url = baseURL.appendingPathComponent("api/applications/\(applicationId)")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(GroupAppStatusRequest(status: status))
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            if let msg = (try? JSONDecoder().decode(APIErrorMessage.self, from: data))?.message {
                throw GroupServiceError.server(msg)
            }
            throw GroupServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(GroupAppStatusResponse.self, from: data)
        guard response.isSuccess else { throw GroupServiceError.server(response.message) }
    }

    /// DELETE /api/groups/{groupId}
    func deleteGroup(groupId: Int) async throws {
        let url = baseURL.appendingPathComponent("api/groups/\(groupId)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            if let msg = (try? JSONDecoder().decode(APIErrorMessage.self, from: data))?.message {
                throw GroupServiceError.server(msg)
            }
            throw GroupServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(GroupDeleteResultWrapper.self, from: data)
        guard response.isSuccess else { throw GroupServiceError.server(response.message) }
    }
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build \
  2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Data/API/GroupService.swift
git commit -m "feat: GroupService 상세/신청/취소/신청자관리/삭제 API 추가"
```

---

## Task 3: GroupDetailViewModel.swift 생성

**Files:**
- Create: `Bookiibookii/Features/Group/GroupDetailViewModel.swift`

- [ ] **Step 1: 파일 생성**

```swift
import Foundation
import SwiftUI

@MainActor
final class GroupDetailViewModel: ObservableObject {
    let groupId: Int
    private let service: GroupService

    enum Phase { case idle, loading, loaded, failed }

    @Published private(set) var detail: GroupDetailDto?
    @Published private(set) var phase: Phase = .idle
    @Published var toast: String?

    // 화면 전환 트리거
    @Published var showApplyDialog = false
    @Published var showDeleteConfirm = false
    @Published var showApplicants = false
    @Published var showMoreSheet = false
    @Published var shouldDismiss = false

    // 신청자 목록 (GroupApplicantView에서 사용)
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

    // MARK: - 파생값

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
        case "MANAGE":  return "참여 요청 관리\(d.waitingCount > 0 ? " (\(d.waitingCount))" : "")"
        case "FULL":    return "모집 완료"
        case "TRACKER": return d.groupType == "TOGETHER" ? "서재 보기" : "트래커 보기"
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
                    : "모임이 시작되면 트래커가 생성됩니다!"
                toast = msg
            } else {
                shouldDismiss = true
            }
        default: break
        }
    }
}
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build \
  2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Features/Group/GroupDetailViewModel.swift
git commit -m "feat: GroupDetailViewModel 추가"
```

---

## Task 4: GroupApplicantView.swift 생성

**Files:**
- Create: `Bookiibookii/Features/Group/GroupApplicantView.swift`

- [ ] **Step 1: 파일 생성**

```swift
import SwiftUI
import Kingfisher

struct GroupApplicantView: View {
    @ObservedObject var viewModel: GroupDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        if viewModel.applicants.isEmpty {
                            Text("신청자가 없습니다")
                                .font(.pretendard(size: 14))
                                .foregroundColor(Color("grey500"))
                                .padding(.top, 80)
                        } else {
                            ForEach(viewModel.applicants) { applicant in
                                applicantCard(applicant)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .task { await viewModel.fetchApplicants() }
        .toast($viewModel.toast)
    }

    // MARK: - 헤더

    private var header: some View {
        ZStack {
            Color("white")
            HStack {
                Button { dismiss() } label: {
                    Image("ic_back_button")
                        .resizable()
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 24)

            HStack(spacing: 4) {
                Text("참여 요청 관리")
                    .font(.pretendard(size: 20, weight: .semibold))
                    .foregroundColor(Color("grey900"))
                if !viewModel.applicants.isEmpty {
                    Text("(\(viewModel.applicants.count))")
                        .font(.pretendard(size: 20, weight: .semibold))
                        .foregroundColor(Color("grey900"))
                }
            }
        }
        .frame(height: 68)
    }

    // MARK: - 신청자 카드

    private func applicantCard(_ item: GroupApplicantDto) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 프로필 + 닉네임 + 날짜
            HStack(alignment: .center, spacing: 12) {
                KFImage(item.profileImageUrl.flatMap(URL.init(string:)))
                    .placeholder { Color("grey300") }
                    .retry(maxCount: 2)
                    .cancelOnDisappear(true)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.pretendard(size: 16))
                        .foregroundColor(Color("black"))
                    Text(item.createdAt.prefix(10).replacingOccurrences(of: "-", with: "."))
                        .font(.pretendard(size: 12))
                        .foregroundColor(Color("grey400"))
                }
            }

            // 태그 chips
            let tags = (item.tags ?? []).map { GroupTagMapper.koreanTag($0) }
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.pretendard(size: 11, weight: .medium))
                                .foregroundColor(Color("sub200"))
                                .padding(.horizontal, 10)
                                .frame(height: 23)
                                .background(Capsule().fill(Color("sub100")))
                        }
                    }
                }
                .padding(.top, 12)
            }

            // 신청 메시지
            Text(item.applyMsg)
                .font(.pretendard(size: 14))
                .foregroundColor(Color("grey600"))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("grey100"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.top, 12)

            // 거절 / 수락 버튼
            HStack(spacing: 12) {
                Button {
                    Task { await viewModel.processApplicant(
                        applicationId: item.applicationId,
                        status: "REJECTED",
                        nickname: item.name
                    ) }
                } label: {
                    Text("거절")
                        .font(.pretendard(size: 15, weight: .medium))
                        .foregroundColor(Color("grey900"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color("grey200"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)

                Button {
                    Task { await viewModel.processApplicant(
                        applicationId: item.applicationId,
                        status: "ACCEPTED",
                        nickname: item.name
                    ) }
                } label: {
                    Text("수락")
                        .font(.pretendard(size: 15, weight: .medium))
                        .foregroundColor(Color("grey100"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color("grey900"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 20)
        }
        .padding(24)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build \
  2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Features/Group/GroupApplicantView.swift
git commit -m "feat: GroupApplicantView (호스트 신청자 관리) 추가"
```

---

## Task 5: GroupDetailView.swift 생성

**Files:**
- Create: `Bookiibookii/Features/Group/GroupDetailView.swift`

- [ ] **Step 1: 파일 생성**

```swift
import SwiftUI
import Kingfisher

struct GroupDetailView: View {
    @StateObject private var viewModel: GroupDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var applyMsg = ""
    @State private var showMoreSheet = false

    init(groupId: Int, groupService: GroupService) {
        _viewModel = StateObject(
            wrappedValue: GroupDetailViewModel(groupId: groupId, service: groupService)
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color("grey100").ignoresSafeArea()

            if viewModel.phase == .loading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let detail = viewModel.detail {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        cardSection(detail)
                        introSection(detail)
                        memberSection(detail)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            } else if viewModel.phase == .failed {
                VStack(spacing: 16) {
                    Text("불러오기 실패")
                        .font(.pretendard(size: 14))
                        .foregroundColor(Color("grey500"))
                    Button("다시 시도") { Task { await viewModel.fetchDetail() } }
                        .font(.pretendard(size: 14, weight: .medium))
                        .foregroundColor(Color("main200"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // 하단 버튼
            if viewModel.detail != nil {
                bottomBar
            }
        }
        .overlay(alignment: .top) { headerBar }
        .fullScreenCover(isPresented: $viewModel.showApplicants) {
            GroupApplicantView(viewModel: viewModel)
        }
        .confirmationDialog("", isPresented: $showMoreSheet) {
            moreSheetButtons
        }
        .sheet(isPresented: $viewModel.showApplyDialog) {
            applyDialogSheet
        }
        .alert("그룹 삭제", isPresented: $viewModel.showDeleteConfirm) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                Task { await viewModel.deleteGroup() }
            }
        } message: {
            Text("\(viewModel.detail?.bookTitle ?? "")\n\n그룹을 정말 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.")
        }
        .task { await viewModel.onAppear() }
        .toast($viewModel.toast)
        .onChange(of: viewModel.shouldDismiss) { if $0 { dismiss() } }
    }

    // MARK: - 헤더

    private var headerBar: some View {
        ZStack {
            Color("white")
            HStack {
                Button { dismiss() } label: {
                    Image("ic_back_button")
                        .resizable()
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                Spacer()
                Button { showMoreSheet = true } label: {
                    Image("ic_more_btn")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)

            Text(viewModel.detail?.title ?? "")
                .font(.pretendard(size: 20, weight: .semibold))
                .foregroundColor(Color("grey900"))
                .lineLimit(1)
                .padding(.horizontal, 64)
        }
        .frame(height: 68)
    }

    // MARK: - 더보기 버튼들

    @ViewBuilder
    private var moreSheetButtons: some View {
        if viewModel.isHost {
            Button(viewModel.canEdit ? "수정" : "수정 (모집 완료 후 불가)") {
                viewModel.toast = "그룹 수정은 준비 중입니다"
            }
            .disabled(!viewModel.canEdit)
            Button("삭제", role: .destructive) {
                viewModel.showDeleteConfirm = true
            }
        } else {
            Button("신고") {
                viewModel.toast = "신고 기능은 준비 중입니다"
            }
        }
        Button("취소", role: .cancel) {}
    }

    // MARK: - 카드 섹션 (책 표지 + 정보)

    private func cardSection(_ d: GroupDetailDto) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // 책 표지
                KFImage(d.bookImage.flatMap(URL.init(string:)))
                    .placeholder { Color("grey300") }
                    .retry(maxCount: 2)
                    .cancelOnDisappear(true)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 74, height: 94)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(d.bookTitle)
                                .font(.pretendard(size: 14))
                                .foregroundColor(Color("black"))
                                .lineLimit(1)
                            HStack(spacing: 4) {
                                Text(d.author)
                                    .font(.pretendard(size: 11))
                                    .foregroundColor(Color("grey500"))
                                    .lineLimit(1)
                                if !d.category.isEmpty {
                                    Text("(\(d.category))")
                                        .font(.pretendard(size: 11))
                                        .foregroundColor(Color("grey500"))
                                        .lineLimit(1)
                                }
                            }
                        }
                        Spacer(minLength: 8)
                        statusBadge(d)
                    }

                    // 메타 Row
                    HStack(spacing: 4) {
                        Image("ic_cal")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundColor(Color("grey500"))
                        Text("\(d.readingPeriod)일")
                            .font(.pretendard(size: 11))
                            .foregroundColor(Color("grey500"))

                        Rectangle().fill(Color("grey400")).frame(width: 1, height: 10).padding(.horizontal, 2)

                        Image("ic_group")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundColor(Color("grey500"))
                        Text("\(d.matchedCount)명 대기")
                            .font(.pretendard(size: 11))
                            .foregroundColor(Color("grey500"))

                        if d.isHot {
                            Text("HOT")
                                .font(.pretendard(size: 11, weight: .medium))
                                .foregroundColor(Color("main200"))
                                .padding(.horizontal, 6)
                                .frame(height: 16)
                                .background(Capsule().fill(Color("main100")))
                        }
                    }
                    .padding(.top, 12)

                    // 프로필 Row
                    HStack(spacing: 4) {
                        KFImage(d.hostProfileImageUrl.flatMap(URL.init(string:)))
                            .placeholder { Image("img_profile_default").resizable() }
                            .retry(maxCount: 2)
                            .cancelOnDisappear(true)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 20, height: 20)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Text(d.hostNickname)
                            .font(.pretendard(size: 12))
                            .foregroundColor(Color("grey700"))
                            .padding(.leading, 4)
                        Text(d.startDate.replacingOccurrences(of: "-", with: "."))
                            .font(.pretendard(size: 11))
                            .foregroundColor(Color("grey400"))
                            .padding(.leading, 4)
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }

            // 태그 전체 표시 (줄바꿈 허용)
            if !viewModel.displayTags.isEmpty {
                tagWrap(viewModel.displayTags)
                    .padding(.top, 12)
            }
        }
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func statusBadge(_ d: GroupDetailDto) -> some View {
        let (bg, text): (Color, String) = d.groupType == "TOGETHER"
            ? (Color("grey900"), "함께읽기(\(d.maxCapacity))")
            : (Color("main200"), d.title)
        return Text(text)
            .font(.pretendard(size: 11, weight: .medium))
            .foregroundColor(Color("white"))
            .padding(.horizontal, 8)
            .frame(height: 23)
            .background(Capsule().fill(bg))
    }

    private func tagWrap(_ tags: [String]) -> some View {
        var rows: [[String]] = [[]]
        // 단순 flow: LazyVGrid로 wrap
        return LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 60), spacing: 8)],
            alignment: .leading,
            spacing: 8
        ) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.pretendard(size: 11, weight: .medium))
                    .foregroundColor(Color("sub200"))
                    .padding(.horizontal, 10)
                    .frame(height: 23)
                    .background(Capsule().fill(Color("sub100")))
                    .fixedSize()
            }
        }
    }

    // MARK: - 그룹 소개 섹션

    private func introSection(_ d: GroupDetailDto) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("그룹 소개")
                .font(.pretendard(size: 16, weight: .semibold))
                .foregroundColor(Color("grey900"))
                .padding(.bottom, 12)
            Divider().background(Color("grey200"))
            Text(d.groupComment ?? "소개글이 없습니다.")
                .font(.pretendard(size: 16))
                .foregroundColor(Color("grey700"))
                .padding(.top, 12)
            if let place = d.meetPlace, !place.isEmpty {
                HStack(spacing: 4) {
                    Text("교환 희망 장소")
                        .font(.pretendard(size: 14))
                        .foregroundColor(Color("grey500"))
                        .padding(.horizontal, 6)
                        .background(Color("grey100"))
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                    Text(place)
                        .font(.pretendard(size: 14))
                        .foregroundColor(Color("grey500"))
                }
                .padding(.top, 12)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - 참여 멤버 섹션

    private func memberSection(_ d: GroupDetailDto) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Text("참여 멤버")
                    .font(.pretendard(size: 16, weight: .semibold))
                    .foregroundColor(Color("grey900"))
                Text("\(d.matchedCount)/\(d.maxCapacity)명")
                    .font(.pretendard(size: 14))
                    .foregroundColor(Color("main200"))
            }
            .padding(.bottom, 12)

            Divider().background(Color("grey200"))

            VStack(spacing: 12) {
                ForEach(Array((d.participantSlots ?? []).enumerated()), id: \.offset) { _, slot in
                    memberRow(slot)
                }
            }
            .padding(.top, 12)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func memberRow(_ slot: ParticipantSlot) -> some View {
        HStack(spacing: 12) {
            if slot.role == "EMPTY" {
                Circle()
                    .fill(Color("grey300"))
                    .frame(width: 36, height: 36)
            } else {
                KFImage(slot.profileImageUrl.flatMap(URL.init(string:)))
                    .placeholder { Image("img_profile_default").resizable() }
                    .retry(maxCount: 2)
                    .cancelOnDisappear(true)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack(spacing: 4) {
                if slot.role == "EMPTY" {
                    Text("대기 중")
                        .font(.pretendard(size: 14))
                        .foregroundColor(Color("grey400"))
                } else {
                    Text(slot.nickname ?? "알 수 없음")
                        .font(.pretendard(size: 14))
                        .foregroundColor(Color("grey700"))
                    if slot.role == "HOST" {
                        Text("(호스트)")
                            .font(.pretendard(size: 12))
                            .foregroundColor(Color("main200"))
                    }
                    if slot.isMe {
                        Text("(나)")
                            .font(.pretendard(size: 12))
                            .foregroundColor(Color("grey500"))
                    }
                }
            }
            Spacer()
        }
    }

    // MARK: - 하단 버튼

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color("grey200"))
            Button {
                viewModel.handleButtonTap()
            } label: {
                Text(viewModel.buttonLabel)
                    .font(.pretendard(size: 15, weight: .medium))
                    .foregroundColor(viewModel.detail?.buttonStatus == "FULL"
                        ? Color("grey500") : Color("white"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        viewModel.detail?.buttonStatus == "FULL"
                            ? Color("grey300") : Color("main200")
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(viewModel.detail?.buttonStatus == "FULL")
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(Color("white"))
    }

    // MARK: - 신청 다이얼로그 시트

    private var applyDialogSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("그룹 참여 신청")
                    .font(.pretendard(size: 20, weight: .bold))
                    .foregroundColor(Color("grey900"))
                Spacer()
                Button { viewModel.showApplyDialog = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color("grey400"))
                }
                .buttonStyle(.plain)
            }

            if let d = viewModel.detail {
                HStack(spacing: 4) {
                    Text("[\(d.hostNickname)]")
                        .font(.pretendard(size: 14))
                        .foregroundColor(Color("grey700"))
                        .lineLimit(1)
                    Text(d.bookTitle)
                        .font(.pretendard(size: 14))
                        .foregroundColor(Color("grey700"))
                        .lineLimit(1)
                }
                .padding(.top, 4)
            }

            HStack {
                Text("신청 한마디")
                    .font(.pretendard(size: 14))
                    .foregroundColor(Color("black"))
                Spacer()
                Text("\(applyMsg.count)/200")
                    .font(.pretendard(size: 12))
                    .foregroundColor(Color("grey500"))
            }
            .padding(.top, 20)

            TextEditor(text: $applyMsg)
                .font(.pretendard(size: 14))
                .foregroundColor(Color("black"))
                .scrollContentBackground(.hidden)
                .background(Color("grey100"))
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.top, 8)
                .onChange(of: applyMsg) { v in
                    if v.count > 200 { applyMsg = String(v.prefix(200)) }
                }

            HStack(spacing: 12) {
                Button {
                    applyMsg = ""
                    viewModel.showApplyDialog = false
                } label: {
                    Text("취소")
                        .font(.pretendard(size: 15, weight: .medium))
                        .foregroundColor(Color("grey900"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("grey200"), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button {
                    guard !applyMsg.trimmingCharacters(in: .whitespaces).isEmpty else {
                        viewModel.toast = "호스트에게 보낼 한 마디를 입력해주세요."
                        return
                    }
                    Task { await viewModel.applyGroup(msg: applyMsg) }
                    applyMsg = ""
                } label: {
                    Text("확인")
                        .font(.pretendard(size: 15, weight: .medium))
                        .foregroundColor(Color("grey100"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color("grey900"))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 20)
        }
        .padding(24)
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color("white"))
    }
}
```

- [ ] **Step 2: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build \
  2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 커밋**

```bash
git add Bookiibookii/Features/Group/GroupDetailView.swift
git commit -m "feat: GroupDetailView 추가"
```

---

## Task 6: GroupView + GroupSearchView 카드 탭 연결

**Files:**
- Modify: `Bookiibookii/Features/Group/GroupView.swift`
- Modify: `Bookiibookii/Features/Group/GroupSearchView.swift`

- [ ] **Step 1: GroupView.swift 수정**

`@State private var activeCreate: CreateType? = nil` 선언 바로 아래에 추가:
```swift
@State private var selectedGroupId: Int? = nil
```

`GroupCard(item: item) {` 클로저 내용을 교체:
```swift
// 기존: viewModel.showComingSoon("그룹 상세는 준비 중입니다")
// 교체:
selectedGroupId = item.groupId
```

`.fullScreenCover(item: $activeCreate)` 블록 바로 아래에 추가:
```swift
.fullScreenCover(item: $selectedGroupId) { groupId in
    GroupDetailView(groupId: groupId, groupService: container.api.group)
}
```

`Int`는 `Identifiable`을 기본 준수하지 않으므로 파일 최상단(import 아래)에 추가:
```swift
extension Int: @retroactive Identifiable {
    public var id: Int { self }
}
```

**주의:** 이 extension은 앱 전역에 한 번만 정의해야 한다. 이미 다른 파일에 있다면 중복 추가하지 않는다.

- [ ] **Step 2: GroupSearchView.swift 수정**

`@FocusState private var isSearchFocused` 선언 바로 아래에 추가:
```swift
@State private var selectedGroupId: Int? = nil
```

`GroupCard(item: item) {` 클로저 내용을 교체:
```swift
// 기존: viewModel.toast = "그룹 상세는 준비 중입니다"
// 교체:
selectedGroupId = item.groupId
```

`.toast($viewModel.toast)` 바로 아래에 추가:
```swift
.fullScreenCover(item: $selectedGroupId) { groupId in
    GroupDetailView(groupId: groupId, groupService: groupService)
}
```

`GroupSearchView`에 `groupService` 프로퍼티 저장이 필요하다. `init` 위에 추가:
```swift
private let groupService: GroupService
```

`init` 에서 저장:
```swift
init(groupService: GroupService) {
    self.groupService = groupService
    _viewModel = StateObject(wrappedValue: GroupSearchViewModel(service: groupService))
}
```

- [ ] **Step 3: 빌드 확인**

```bash
xcodebuild -project Bookiibookii.xcodeproj -scheme Bookiibookii \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build \
  2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: 커밋**

```bash
git add Bookiibookii/Features/Group/GroupView.swift \
        Bookiibookii/Features/Group/GroupSearchView.swift
git commit -m "feat: GroupView/GroupSearchView 카드 탭 → GroupDetailView 연결"
```

---

## 자체검토 결과

**스펙 커버리지 확인:**
- [x] GroupDetailDto / ParticipantSlot → Task 1
- [x] GroupService 6개 메서드 → Task 2
- [x] GroupDetailViewModel (buttonStatus 분기, handleButtonTap) → Task 3
- [x] GroupApplicantView (신청자 목록, 수락/거절) → Task 4
- [x] GroupDetailView (카드/소개/멤버/버튼/다이얼로그/더보기) → Task 5
- [x] GroupView + GroupSearchView 연결 → Task 6
- [x] 댓글 제외 확인 → 어디에도 댓글 코드 없음

**타입 일관성:**
- `GroupDetailDto` Task 1 정의 → Task 3, 5에서 동일하게 사용
- `GroupApplicantDto.applicationId: Int` → Task 3 `processApplicant(applicationId: Int)` 일치
- `viewModel.displayTags` → Task 3에서 `[String]` 반환, Task 5에서 `ForEach(tags, id: \.self)` 사용 일치

**플레이스홀더:** 없음
