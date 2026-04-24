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
                    .padding(.top, 84)
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
                    Image("ic_back")
                        .resizable()
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                Spacer()
                Button { showMoreSheet = true } label: {
                    Image("ic_more")
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

    // MARK: - 더보기

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
                        let (badgeBg, badgeText): (Color, String) = d.groupType == "TOGETHER"
                            ? (Color("grey900"), "함께읽기(\(d.maxCapacity))")
                            : (Color("main200"), d.title)
                        Text(badgeText)
                            .font(.pretendard(size: 11, weight: .medium))
                            .foregroundColor(Color("white"))
                            .padding(.horizontal, 8)
                            .frame(height: 23)
                            .background(Capsule().fill(badgeBg))
                    }

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

            if !viewModel.displayTags.isEmpty {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 60), spacing: 8)],
                    alignment: .leading,
                    spacing: 8
                ) {
                    ForEach(viewModel.displayTags, id: \.self) { tag in
                        Text(tag)
                            .font(.pretendard(size: 11, weight: .medium))
                            .foregroundColor(Color("sub200"))
                            .padding(.horizontal, 10)
                            .frame(height: 23)
                            .background(Capsule().fill(Color("sub100")))
                            .fixedSize()
                    }
                }
                .padding(.top, 12)
            }
        }
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - 그룹 소개

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

    // MARK: - 참여 멤버

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
            Button { viewModel.handleButtonTap() } label: {
                Text(viewModel.buttonLabel)
                    .font(.pretendard(size: 15, weight: .medium))
                    .foregroundColor(viewModel.detail?.buttonStatus == "FULL" ? Color("grey500") : Color("white"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(viewModel.detail?.buttonStatus == "FULL" ? Color("grey300") : Color("main200"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(viewModel.detail?.buttonStatus == "FULL")
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(Color("white"))
    }

    // MARK: - 신청 다이얼로그

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
