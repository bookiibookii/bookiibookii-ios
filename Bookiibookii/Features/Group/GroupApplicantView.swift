import SwiftUI

struct GroupApplicantView: View {
    @ObservedObject var viewModel: GroupDetailViewModel
    @Environment(\.dismiss) private var dismiss
    var onProfileTap: ((String) -> Void)?

    private struct PendingAction {
        let applicationId: Int
        let status: String
        let nickname: String
    }

    @State private var pendingAction: PendingAction?

    var body: some View {
        ZStack {
            Color("uiBg").ignoresSafeArea()
            VStack(spacing: 0) {
                header
                if viewModel.applicants.isEmpty {
                    Spacer()
                    Text("아직 신청자가 없어요")
                        .pretendardText(size: 15)
                        .foregroundColor(Color("grey500"))
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.applicants) { applicant in
                                applicantCard(applicant)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }

            if let action = pendingAction {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture {}
                confirmDialog(action)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: pendingAction != nil)
        .task { await viewModel.fetchApplicants() }
        .toast($viewModel.toast)
    }

    private var header: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    Button { dismiss() } label: {
                        Image("ic_back")
                            .resizable()
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 16)

                Text("참여 요청 관리 (\(viewModel.applicants.count))")
                    .pretendardText(size: 20, weight: .semibold)
                    .foregroundColor(Color("grey900"))
            }
            .frame(height: 68)

            Rectangle()
                .fill(Color("grey200"))
                .frame(height: 1)
        }
        .background(Color("white"))
    }

    private func applicantCard(_ item: GroupApplicantDto) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                if let nickname = item.name, !nickname.isEmpty {
                    onProfileTap?(nickname)
                }
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    ProfilePlaceholder(imageUrl: item.profileImageUrl, size: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name ?? "")
                            .pretendardText(size: 15, weight: .medium)
                            .foregroundColor(Color("grey900"))
                        Text(String((item.createdAt ?? "").prefix(10)).replacingOccurrences(of: "-", with: "."))
                            .pretendardText(size: 14)
                            .foregroundColor(Color("grey400"))
                    }
                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)
            .disabled(onProfileTap == nil || (item.name ?? "").isEmpty)

            Text(item.applyMsg ?? "")
                .pretendardText(size: 15)
                .foregroundColor(Color("grey600"))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("grey100"))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            HStack(alignment: .top, spacing: 12) {
                BookCover(imageUrl: item.bookImage)
                    .frame(width: 48, height: 60)
                VStack(alignment: .leading, spacing: 2) {
                    Text((item.bookTitle ?? "").stripBookSubtitle())
                        .pretendardText(size: 15, weight: .medium)
                        .foregroundColor(Color("grey800"))
                    Text(item.bookAuthor ?? "")
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey600"))
                }
            }

            HStack(spacing: 12) {
                BottomSheetTwoBtnShort(
                    text: "거절",
                    style: .white,
                    action: {
                        pendingAction = PendingAction(
                            applicationId: item.applicationId ?? 0,
                            status: "REJECTED",
                            nickname: item.name ?? ""
                        )
                    }
                )
                BottomSheetTwoBtnShort(
                    text: "수락",
                    style: .orange,
                    action: {
                        pendingAction = PendingAction(
                            applicationId: item.applicationId ?? 0,
                            status: "ACCEPTED",
                            nickname: item.name ?? ""
                        )
                    }
                )
            }
        }
        .padding(20)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 수락/거절 확인 다이얼로그

    private func confirmDialog(_ action: PendingAction) -> some View {
        let isAccept = action.status == "ACCEPTED"
        let contentMsg: String = isAccept
            ? "\(action.nickname) 님의 그룹 참여 요청을 수락하시겠습니까? 수락 즉시 그룹이 시작됩니다."
            : "\(action.nickname) 님의 그룹 참여 요청을 거절하시겠습니까? 상대방에게 거절 알림이 발송됩니다."
        let confirmStyle: BottomSheetBtnStyle = isAccept ? .orange : .red

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text(isAccept ? "참여 요청 수락" : "참여 요청 거절")
                    .pretendardText(size: 24, weight: .bold)
                    .foregroundColor(Color("grey900"))
                Spacer()
                Button { pendingAction = nil } label: {
                    Image("ic_x")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color("grey900"))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color("grey100")))
                }
                .buttonStyle(.plain)
            }

            Text(contentMsg)
                .pretendardText(size: 16)
                .foregroundColor(Color("grey900"))
                .padding(.top, 24)

            HStack(spacing: 8) {
                BottomSheetTwoBtnShort(text: "취소", style: .white, action: { pendingAction = nil })
                BottomSheetTwoBtnShort(
                    text: isAccept ? "수락" : "거절",
                    style: confirmStyle,
                    action: {
                        let captured = action
                        pendingAction = nil
                        Task {
                            await viewModel.processApplicant(
                                applicationId: captured.applicationId,
                                status: captured.status,
                                nickname: captured.nickname
                            )
                        }
                    }
                )
            }
            .padding(.top, 24)
        }
        .padding(20)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 24)
    }
}
