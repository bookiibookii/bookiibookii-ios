import SwiftUI

// 별 인덱스(0~4)의 시각 상태.
private enum StarState { case empty, subPale, sub }

// 별 인덱스의 현재 상태를 0~10 점수로부터 계산.
private func starStateFor(score: Int, index: Int) -> StarState {
    let halfPos = (index + 1) * 2 - 1
    let fullPos = (index + 1) * 2
    if fullPos <= score { return .sub }
    if halfPos == score { return .subPale }
    return .empty
}

// 클릭 시 새 점수. Empty→SubPale, SubPale→Sub, Sub→SubPale.
private func nextScoreAfterClick(score: Int, index: Int) -> Int {
    let halfPos = (index + 1) * 2 - 1
    let fullPos = (index + 1) * 2
    if score < halfPos { return halfPos }
    if score == halfPos { return fullPos }
    return halfPos
}

struct TrackerBookReviewView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: TrackerBookReviewViewModel

    // rating: 0~10 (별 5개 × 2단계 — half=1, full=2)
    @State private var rating: Int = 0
    @State private var commentInput: String = ""

    init(groupId: Int, isEdit: Bool = false, trackerService: TrackerService) {
        _viewModel = StateObject(
            wrappedValue: TrackerBookReviewViewModel(
                groupId: groupId, isEdit: isEdit, trackerService: trackerService
            )
        )
    }

#if DEBUG
    // 프리뷰 전용 — 시드된 ViewModel 주입 (네트워크 없이 화면 확인용)
    init(previewViewModel: TrackerBookReviewViewModel) {
        _viewModel = StateObject(wrappedValue: previewViewModel)
    }
#endif

    var body: some View {
        VStack(spacing: 0) {
            CustomNavigationBar(title: "책 리뷰", onBack: { container.navigationRouter.pop() })

            ScrollView {
                card.padding(16)
            }

            FooterButton(
                text: "등록하기",
                enabled: rating > 0 && !viewModel.state.submitting,
                action: {
                    let star = Double(rating) / 2.0
                    let trimmed = commentInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    viewModel.submitReview(star: star, comment: trimmed.isEmpty ? nil : commentInput) {
                        container.navigationRouter.pop()
                    }
                }
            )
            .padding(16)
        }
        .background(Color("uiBg"))
        .navigationBarBackButtonHidden(true)
        .dismissKeyboardOnTap()
        .task { await viewModel.load() }
        // 수정 모드 프리필이 비동기로 도착하면 반영
        .onChange(of: viewModel.state.initialStar) { value in
            rating = Int((value * 2).rounded())
        }
        .onChange(of: viewModel.state.initialComment) { value in
            commentInput = value
        }
    }

    private var card: some View {
        VStack(spacing: 16) {
            BookCover(imageUrl: viewModel.state.bookImageUrl)
                .frame(width: 122, height: 180)

            (
                Text(viewModel.state.bookTitle).foregroundColor(Color("main200"))
                + Text("에 대한 평가를 남겨주세요!").foregroundColor(Color("grey900"))
            )
            .pretendardText(size: 16, weight: .medium)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)

            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { i in
                    StarItem(state: starStateFor(score: rating, index: i)) {
                        rating = nextScoreAfterClick(score: rating, index: i)
                    }
                }
            }
            .padding(.bottom, 8)

            ZStack(alignment: .topLeading) {
                if commentInput.isEmpty {
                    Text("감상평을 자유롭게 남겨주세요.")
                        .pretendardText(size: 16, weight: .medium)
                        .foregroundColor(Color("grey500"))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                TextEditor(text: $commentInput)
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey900"))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .tint(Color("main200"))
                    .onChange(of: commentInput) { value in
                        if value.count > 500 { commentInput = String(value.prefix(500)) }
                    }
            }
            .frame(height: 200)
            .padding(20)
            .background(Color("grey100"))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct StarItem: View {
    let state: StarState
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                switch state {
                case .empty:
                    star("ic_star", Color("grey300"))
                case .subPale:
                    star("ic_star_fill", Color("sub100"))
                    star("ic_star", Color("sub200"))
                case .sub:
                    star("ic_star_fill", Color("sub200"))
                }
            }
            .frame(width: 40, height: 40)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func star(_ name: String, _ color: Color) -> some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40)
            .foregroundColor(color)
    }
}

#if DEBUG
#Preview {
    let vm = TrackerBookReviewViewModel(
        groupId: 0,
        trackerService: TrackerService(interceptor: AuthInterceptor(authService: AuthService()))
    )
    vm.state = TrackerBookReviewUiState(
        bookTitle: "살인자의 기억법",
        bookImageUrl: nil
    )
    return TrackerBookReviewView(previewViewModel: vm)
        .environmentObject(DIContainer())
}
#endif
