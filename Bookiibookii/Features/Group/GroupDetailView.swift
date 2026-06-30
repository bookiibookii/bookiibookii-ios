import SwiftUI
import Kingfisher

struct GroupDetailView: View {
    @StateObject private var viewModel: GroupDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var applyMsg = ""
    @State private var showMoreSheet = false
    @State private var showEditView = false

    private let groupService: GroupService

    init(groupId: Int, groupService: GroupService) {
        self.groupService = groupService
        _viewModel = StateObject(
            wrappedValue: GroupDetailViewModel(groupId: groupId, service: groupService)
        )
    }

    var body: some View {
        ZStack {
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
                    .padding(.top, 84)
                    .padding(.bottom, 32)
                }
            } else if viewModel.phase == .failed {
                VStack(spacing: 16) {
                    Text("불러오기 실패")
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey500"))
                    Button("다시 시도") { Task { await viewModel.fetchDetail() } }
                        .pretendardText(size: 14, weight: .medium)
                        .foregroundColor(Color("main200"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if viewModel.showApplyDialog {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture {}
                applyDialog
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }

            if viewModel.showDeleteConfirm {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture {}
                deleteDialog
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.showApplyDialog)
        .animation(.easeInOut(duration: 0.2), value: viewModel.showDeleteConfirm)
        .overlay(alignment: .top) { headerBar }
        .fullScreenCover(isPresented: $viewModel.showApplicants) {
            GroupApplicantView(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showEditView) {
            if let config = viewModel.editConfig {
                if viewModel.detail?.groupType == "TOGETHER" {
                    GroupTogetherCreateView(groupService: groupService, editConfig: config)
                } else {
                    GroupRelayCreateView(groupService: groupService, editConfig: config)
                }
            }
        }
        .onChange(of: showEditView) { isShowing in
            if !isShowing { Task { await viewModel.fetchDetail() } }
        }
        .sheet(isPresented: $showMoreSheet) {
            GroupMoreSheet(
                isHost: viewModel.isHost,
                canEdit: viewModel.canEdit,
                onEdit: { showEditView = true },
                onDelete: { viewModel.showDeleteConfirm = true },
                onReport: { viewModel.toast = "신고가 접수되었습니다." }
            )
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
                    Image("ic_back")
                        .resizable()
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                Spacer()
                Button { showMoreSheet = true } label: {
                    Image("ic_meetball")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)

            Text(viewModel.detail?.title ?? "")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))
                .lineLimit(1)
                .padding(.horizontal, 64)
        }
        .frame(height: 68)
    }

    // MARK: - 카드 섹션

    private func cardSection(_ d: GroupDetailDto) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
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
                                .pretendardText(size: 14)
                                .foregroundColor(Color("black"))
                                .lineLimit(1)
                            HStack(spacing: 4) {
                                Text(d.author)
                                    .pretendardText(size: 11)
                                    .foregroundColor(Color("grey500"))
                                    .lineLimit(1)
                                if !d.category.isEmpty {
                                    Text("(\(d.category))")
                                        .pretendardText(size: 11)
                                        .foregroundColor(Color("grey500"))
                                        .lineLimit(1)
                                }
                            }
                        }
                        Spacer(minLength: 8)
                        statusBadge(d.groupStatus)
                    }

                    HStack(spacing: 4) {
                        Image("ic_calender")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundColor(Color("grey500"))
                        Text("\(d.readingPeriod)일")
                            .pretendardText(size: 11)
                            .foregroundColor(Color("grey500"))
                        Rectangle().fill(Color("grey400")).frame(width: 1, height: 10).padding(.horizontal, 2)
                        Image("ic_group")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundColor(Color("grey500"))
                        Text("\(d.matchedCount)명 대기")
                            .pretendardText(size: 11)
                            .foregroundColor(Color("grey500"))
                        if d.isHot {
                            Text("HOT")
                                .pretendardText(size: 11, weight: .medium)
                                .foregroundColor(Color("main200"))
                                .padding(.horizontal, 6)
                                .frame(height: 16)
                                .background(Capsule().fill(Color("main100")))
                        }
                    }
                    .padding(.top, 12)

                    HStack(spacing: 4) {
                        KFImage(d.hostProfileImageUrl.flatMap(URL.init(string:)))
                            .placeholder { Image("ic_profile_placeholder").resizable() }
                            .retry(maxCount: 2)
                            .cancelOnDisappear(true)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 20, height: 20)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Text(d.hostNickname)
                            .pretendardText(size: 12, weight: .medium)
                            .foregroundColor(Color("grey700"))
                        Text((d.startDate ?? "").replacingOccurrences(of: "-", with: "."))
                            .pretendardText(size: 11)
                            .foregroundColor(Color("grey400"))
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }

            if !viewModel.displayTags.isEmpty {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 60), spacing: 8)],
                    alignment: .leading,
                    spacing: 8
                ) {
                    ForEach(viewModel.displayTags, id: \.self) { tag in
                        Text(tag)
                            .pretendardText(size: 11, weight: .medium)
                            .foregroundColor(Color("sub200"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("sub100"))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .fixedSize()
                    }
                }
                .padding(.top, 12)
            }

            actionButton
                .padding(.top, 12)
        }
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - 상태 배지

    @ViewBuilder
    private func statusBadge(_ status: String) -> some View {
        switch status {
        case "RECRUITING":
            Text("모집 중")
                .pretendardText(size: 11)
                .foregroundColor(Color("white"))
                .padding(.horizontal, 8)
                .frame(height: 23)
                .background(Color("main200"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        case "MATCHED":
            Text("진행 중")
                .pretendardText(size: 11)
                .foregroundColor(Color("main200"))
                .padding(.horizontal, 8)
                .frame(height: 23)
                .background(Color("white"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color("main105"), lineWidth: 1))
        case "COMPLETED":
            Text("종료")
                .pretendardText(size: 11)
                .foregroundColor(Color("grey500"))
                .padding(.horizontal, 8)
                .frame(height: 23)
                .background(Color("grey200"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        default:
            Text("마감")
                .pretendardText(size: 11)
                .foregroundColor(Color("grey500"))
                .padding(.horizontal, 8)
                .frame(height: 23)
                .background(Color("grey200"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - 카드 내부 버튼

    @ViewBuilder
    private var actionButton: some View {
        if let d = viewModel.detail {
            let isFull = d.buttonStatus == "FULL"
            Button { viewModel.handleButtonTap() } label: {
                HStack(spacing: 4) {
                    Text(viewModel.buttonLabel)
                        .pretendardText(size: 15)
                        .foregroundColor(isFull ? Color("grey500") : Color("main200"))
                    if d.buttonStatus == "MANAGE" && d.waitingCount > 0 {
                        Text("(\(d.waitingCount))")
                            .pretendardText(size: 15)
                            .foregroundColor(Color("main200"))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isFull ? Color("grey200") : Color("main100"))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .disabled(isFull)
            .buttonStyle(.plain)
        }
    }

    // MARK: - 그룹 소개

    private func introSection(_ d: GroupDetailDto) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("그룹 소개")
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey900"))
                .padding(.bottom, 12)
            Divider().background(Color("grey200"))
            Text(d.groupComment ?? "소개글이 없습니다.")
                .pretendardText(size: 16)
                .foregroundColor(Color("grey700"))
                .padding(.top, 12)
            if let place = d.meetPlace, !place.isEmpty {
                HStack(spacing: 4) {
                    Text("교환 희망 장소")
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey500"))
                        .padding(.horizontal, 6)
                        .background(Color("grey100"))
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                    Text(place)
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey500"))
                }
                .padding(.top, 12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - 참여 멤버

    private func memberSection(_ d: GroupDetailDto) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Text("참여 멤버")
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey900"))
                Text("\(d.matchedCount)/\(d.maxCapacity)명")
                    .pretendardText(size: 14)
                    .foregroundColor(Color("main200"))
            }
            .padding(.bottom, 12)
            Divider().background(Color("grey200"))
            VStack(spacing: 0) {
                ForEach(Array((d.participantSlots ?? []).enumerated()), id: \.offset) { _, slot in
                    memberRow(slot)
                }
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func memberRow(_ slot: ParticipantSlot) -> some View {
        HStack(spacing: 12) {
            if slot.role == "EMPTY" {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("grey300"))
                    .frame(width: 40, height: 40)
            } else {
                KFImage(slot.profileImageUrl.flatMap(URL.init(string:)))
                    .placeholder { Image("ic_profile_placeholder").resizable() }
                    .retry(maxCount: 2)
                    .cancelOnDisappear(true)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            HStack(spacing: 8) {
                if slot.role == "EMPTY" {
                    Text("대기 중")
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey400"))
                } else {
                    Text(slot.nickname ?? "알 수 없음")
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey900"))
                    if slot.role == "HOST" {
                        Text("HOST")
                            .pretendardText(size: 11)
                            .foregroundColor(Color("main200"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("main100"))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    if slot.isMe {
                        Text("(나)")
                            .pretendardText(size: 12)
                            .foregroundColor(Color("grey500"))
                    }
                }
            }
            Spacer()
        }
        .padding(.bottom, 12)
    }

    // MARK: - 신청 다이얼로그 (중앙 모달)

    private var applyDialog: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 헤더
            HStack {
                Text("그룹 참여 신청")
                    .pretendardText(size: 20, weight: .medium)
                    .foregroundColor(Color("grey900"))
                Spacer()
                Button {
                    applyMsg = ""
                    viewModel.showApplyDialog = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color("grey900"))
                        .frame(width: 32, height: 32)
                        .background(Color("grey100"))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            // 책 정보
            if let d = viewModel.detail {
                HStack(spacing: 4) {
                    Text("[\(d.hostNickname)]")
                        .pretendardText(size: 16)
                        .foregroundColor(Color("grey800"))
                        .lineLimit(1)
                    Text(d.bookTitle)
                        .pretendardText(size: 16)
                        .foregroundColor(Color("grey800"))
                        .lineLimit(1)
                }
            }

            // 신청 한 마디 입력
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("신청 한 마디")
                        .pretendardText(size: 14, weight: .medium)
                        .foregroundColor(Color("grey900"))
                    Spacer()
                    Text("\(applyMsg.count)/50")
                        .pretendardText(size: 12)
                        .foregroundColor(Color("grey500"))
                }
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $applyMsg)
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey900"))
                        .scrollContentBackground(.hidden)
                        .padding(8)
                    if applyMsg.isEmpty {
                        Text("호스트에게 간단한 소개를 남겨주세요.")
                            .pretendardText(size: 14)
                            .foregroundColor(Color("grey500"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                }
                .frame(height: 100)
                .background(Color("grey100"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .onChange(of: applyMsg) { v in
                    if v.count > 50 { applyMsg = String(v.prefix(50)) }
                }
            }

            // 버튼
            HStack(spacing: 12) {
                Button {
                    applyMsg = ""
                    viewModel.showApplyDialog = false
                } label: {
                    Text("취소")
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey900"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color("grey200"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)

                Button {
                    let trimmed = applyMsg.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else {
                        viewModel.toast = "호스트에게 보낼 한 마디를 입력해주세요."
                        return
                    }
                    Task { await viewModel.applyGroup(msg: trimmed) }
                    applyMsg = ""
                } label: {
                    Text("신청하기")
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey100"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color("grey900"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .frame(width: 340)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - 삭제 확인 다이얼로그 (중앙 모달)

    private var deleteDialog: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("그룹 삭제")
                    .pretendardText(size: 20, weight: .medium)
                    .foregroundColor(Color("grey900"))
                Spacer()
                Button {
                    viewModel.showDeleteConfirm = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color("grey900"))
                        .frame(width: 32, height: 32)
                        .background(Color("grey100"))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Text("그룹을 정말 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.")
                .pretendardText(size: 16)
                .foregroundColor(Color("grey700"))

            HStack(spacing: 12) {
                Button {
                    viewModel.showDeleteConfirm = false
                } label: {
                    Text("취소")
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey900"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color("grey200"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.showDeleteConfirm = false
                    Task { await viewModel.deleteGroup() }
                } label: {
                    Text("삭제")
                        .pretendardText(size: 14)
                        .foregroundColor(Color("white"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(red: 1, green: 77 / 255, blue: 77 / 255))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .frame(width: 340)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
