import SwiftUI

struct QuestoinView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: QuestoinViewModel

    init(inquiryService: InquiryService) {
        _viewModel = StateObject(wrappedValue: QuestoinViewModel(inquiryService: inquiryService))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color("grey100").ignoresSafeArea()
            VStack(spacing: 0) {
                CustomNavigationBar(title: "문의 내역", onBack: { container.navigationRouter.pop() }, rightButton: .none)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if viewModel.isLoading {
                            ProgressView().padding(.top, 40)
                        } else if let message = viewModel.errorMessage {
                            Text("문의 내역을 불러오지 못했어요.\n\(message)")
                                .font(.pretendard(size: 14, weight: .regular))
                                .foregroundColor(Color("grey700"))
                                .multilineTextAlignment(.center)
                                .padding(.top, 40)
                        } else if viewModel.isEmpty {
                            emptyCard
                        } else {
                            ForEach(viewModel.items) { item in questionCard(item) }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }

            Button { container.navigationRouter.push(to: .qustionDetail) } label: {
                Text("문의하기")
                    .font(.pretendard(size: 18, weight: .medium))
                    .foregroundColor(Color("white"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(Color("grey900"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .task { await viewModel.load() }
        .onAppear { Task { await viewModel.load() } }
    }

    private var emptyCard: some View {
        VStack(spacing: 8) {
            Text("아직 문의 내역이 없어요 😊").font(.pretendard(size: 16, weight: .medium)).foregroundColor(Color("grey900"))
            Text("이용 중 궁금한 점이 생기면\n언제든 부키부키 팀을 찾아주세요.")
                .font(.pretendard(size: 14, weight: .regular))
                .foregroundColor(Color("grey600"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func questionCard(_ item: QuestionItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(item.author).font(.pretendard(size: 11, weight: .medium)).foregroundColor(Color("grey900"))
                Spacer()
                Text(Self.dateFormatter.string(from: item.createdAt)).font(.pretendard(size: 11, weight: .regular)).foregroundColor(Color("grey400"))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title).font(.pretendard(size: 14, weight: .medium)).foregroundColor(Color("grey900"))
                Text(item.content).font(.pretendard(size: 14, weight: .regular)).foregroundColor(Color("grey700"))
            }
            if item.status == .waiting {
                Text("답변 대기 중입니다")
                    .font(.pretendard(size: 14, weight: .regular))
                    .foregroundColor(Color("grey500"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color("grey100"))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color("grey200"), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else if let answer = item.answerContent {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(item.answerAuthor ?? "부키부키 팀").font(.pretendard(size: 12, weight: .regular)).foregroundColor(Color("main200"))
                        Spacer()
                        if let d = item.answerDate { Text(Self.dateFormatter.string(from: d)).font(.pretendard(size: 11, weight: .regular)).foregroundColor(Color("grey400")) }
                    }
                    Text(answer).font(.pretendard(size: 14, weight: .regular)).foregroundColor(Color("grey900"))
                }
                .padding(12)
                .background(Color("grey100"))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color("grey200"), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy. MM. dd."
        return f
    }()
}
