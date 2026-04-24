import SwiftUI
import Kingfisher

struct GroupApplicantView: View {
    @ObservedObject var viewModel: GroupDetailViewModel
    @Environment(\.dismiss) private var dismiss

    private struct PendingAction {
        let applicationId: Int
        let status: String
        let nickname: String
    }

    @State private var pendingAction: PendingAction?

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

    private func applicantCard(_ item: GroupApplicantDto) -> some View {
        VStack(alignment: .leading, spacing: 0) {
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
                    Text(String(item.createdAt.prefix(10)).replacingOccurrences(of: "-", with: "."))
                        .font(.pretendard(size: 12))
                        .foregroundColor(Color("grey400"))
                }
            }

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

            Text(item.applyMsg)
                .font(.pretendard(size: 14))
                .foregroundColor(Color("grey600"))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("grey100"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.top, 12)

            HStack(spacing: 12) {
                Button {
                    pendingAction = PendingAction(
                        applicationId: item.applicationId,
                        status: "REJECTED",
                        nickname: item.name
                    )
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
                    pendingAction = PendingAction(
                        applicationId: item.applicationId,
                        status: "ACCEPTED",
                        nickname: item.name
                    )
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

    // MARK: - 수락/거절 확인 다이얼로그

    private func confirmDialog(_ action: PendingAction) -> some View {
        let isAccept = action.status == "ACCEPTED"
        let bookTitle = viewModel.detail?.bookTitle ?? ""
        let isRelay = viewModel.detail?.groupType == "RELAY"
        let contentMsg: String = isAccept
            ? "\(action.nickname) 님의 그룹 참여 요청을 수락하시겠습니까? \(isRelay ? "수락 즉시 그룹이 시작됩니다." : "인원이 다 차면 그룹이 시작됩니다.")"
            : "\(action.nickname) 님의 그룹 참여 요청을 거절하시겠습니까? 상대방에게 거절 알림이 발송됩니다."
        let confirmBg: Color = isAccept ? Color("grey900") : Color(red: 1, green: 0.302, blue: 0.302)

        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(isAccept ? "참여 요청 수락" : "참여 요청 거절")
                    .font(.pretendard(size: 20, weight: .bold))
                    .foregroundColor(Color("grey900"))
                Spacer()
                Button { pendingAction = nil } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("grey900"))
                        .frame(width: 24, height: 24)
                        .background(Color("grey200"))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            if !bookTitle.isEmpty {
                Text(bookTitle)
                    .font(.pretendard(size: 16))
                    .foregroundColor(Color("grey800"))
                    .lineLimit(1)
                    .padding(.top, 4)
            }

            Text(contentMsg)
                .font(.pretendard(size: 16))
                .foregroundColor(Color("grey700"))
                .padding(.top, 20)

            HStack(spacing: 12) {
                Button { pendingAction = nil } label: {
                    Text("취소")
                        .font(.pretendard(size: 14))
                        .foregroundColor(Color("grey900"))
                        .frame(width: 140)
                        .frame(height: 48)
                        .background(Color("grey200"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)

                Button {
                    let captured = action
                    pendingAction = nil
                    Task {
                        await viewModel.processApplicant(
                            applicationId: captured.applicationId,
                            status: captured.status,
                            nickname: captured.nickname
                        )
                    }
                } label: {
                    Text(isAccept ? "수락" : "거절")
                        .font(.pretendard(size: 14))
                        .foregroundColor(.white)
                        .frame(width: 140)
                        .frame(height: 48)
                        .background(confirmBg)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 20)
        }
        .padding(24)
        .frame(width: 340)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
