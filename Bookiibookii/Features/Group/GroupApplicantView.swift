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
                    Task { await viewModel.processApplicant(
                        applicationId: item.applicationId,
                        status: "REJECTED",
                        nickname: item.name
                    )}
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
                    )}
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
