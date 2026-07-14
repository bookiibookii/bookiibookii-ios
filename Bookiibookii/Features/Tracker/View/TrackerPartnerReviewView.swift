import SwiftUI
import Kingfisher

private let partnerCommentMaxLength = 20

// reaction: 좋았어요→BOOM_UP, 별로였어요→BOOM_DOWN, 미선택→nil
private enum PartnerRating {
    case none, good, bad
    var reaction: String? {
        switch self {
        case .good: return "BOOM_UP"
        case .bad: return "BOOM_DOWN"
        case .none: return nil
        }
    }
}

struct TrackerPartnerReviewView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: TrackerPartnerReviewViewModel

    @State private var rating: PartnerRating = .none
    @State private var commentInput: String = ""

    init(groupId: Int, trackerService: TrackerService) {
        _viewModel = StateObject(
            wrappedValue: TrackerPartnerReviewViewModel(groupId: groupId, trackerService: trackerService)
        )
    }

#if DEBUG
    // 프리뷰 전용 — 시드된 ViewModel 주입 (네트워크 없이 화면 확인용)
    init(previewViewModel: TrackerPartnerReviewViewModel) {
        _viewModel = StateObject(wrappedValue: previewViewModel)
    }
#endif

    private var s: TrackerPartnerReviewUiState { viewModel.state }

    var body: some View {
        VStack(spacing: 0) {
            CustomNavigationBar(title: "교환독서 후기", onBack: { container.navigationRouter.pop() })

            ScrollView {
                VStack(spacing: 16) {
                    trackerCard
                    reviewCard
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)

            FooterButton(
                text: "등록하기",
                enabled: !commentInput.trimmingCharacters(in: .whitespaces).isEmpty && !s.submitting,
                action: {
                    viewModel.submitReview(reaction: rating.reaction, comment: commentInput) {
                        container.navigationRouter.pop()
                    }
                }
            )
            .padding(16)
        }
        .background(Color("uiBg"))
        .navigationBarBackButtonHidden(true)
        .task { await viewModel.load() }
    }

    // MARK: 상단 카드 (그룹명 + 내책/파트너책)

    private var trackerCard: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text(s.groupName)
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey800"))
                Rectangle()
                    .fill(Color("grey100"))
                    .frame(height: 0.8)
                    .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .center, spacing: 16) {
                bookColumn(
                    nickname: s.myNickname, bookTitle: s.myBookTitle,
                    coverUrl: s.myBookCoverUrl, profileUrl: s.myProfileImageUrl, isMyBook: true
                )
                bookColumn(
                    nickname: s.partnerNickname, bookTitle: s.partnerBookTitle,
                    coverUrl: s.partnerBookCoverUrl, profileUrl: s.partnerProfileImageUrl, isMyBook: false
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func bookColumn(
        nickname: String, bookTitle: String, coverUrl: String?, profileUrl: String?, isMyBook: Bool
    ) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                // 표지 (하단 정렬)
                VStack {
                    Spacer(minLength: 0)
                    ZStack(alignment: .bottomTrailing) {
                        BookCoverImage(imageUrl: coverUrl)
                            .frame(width: 100, height: 132)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        if isMyBook {
                            Text("내 책")
                                .pretendardText(size: 10, weight: .regular)
                                .foregroundColor(Color("grey900"))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color("grey200").opacity(0.75))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .padding(4)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 144)
                // 파트너 프로필 오버레이 (좌상단)
                ReviewProfileAvatar(imageUrl: profileUrl, size: 44, innerStroke: true)
                    .padding(.leading, 17)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 144)

            Text(nickname)
                .pretendardText(size: 14, weight: .regular)
                .foregroundColor(Color("grey700"))
            // 항상 2줄 높이 확보 → 한쪽만 길어도 양쪽 칼럼 높이가 같아 표지 정렬 유지
            Text(bookTitle.stripBookSubtitle())
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey800"))
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: 리뷰 입력 카드

    private var reviewCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 4) {
                ReviewProfileAvatar(imageUrl: s.partnerProfileImageUrl, size: 20)
                (
                    Text(s.partnerNickname).foregroundColor(Color("main200"))
                    + Text("님과의 교환독서는 어떠셨나요?").foregroundColor(Color("grey900"))
                )
                .pretendardText(size: 16, weight: .medium)
            }

            HStack(spacing: 12) {
                ratingButton(text: "좋았어요", icon: "ic_hand_thumbs_up", target: .good, isPositive: true)
                ratingButton(text: "별로였어요", icon: "ic_hand_thumbs_down", target: .bad, isPositive: false)
            }

            ZStack(alignment: .topLeading) {
                if commentInput.isEmpty {
                    Text("파트너에게 소중한 후기를 남겨주세요.")
                        .pretendardText(size: 16, weight: .regular)
                        .foregroundColor(Color("grey500"))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                TextEditor(text: $commentInput)
                    .pretendardText(size: 16, weight: .regular)
                    .foregroundColor(Color("grey900"))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .tint(Color("main200"))
                    .onChange(of: commentInput) { value in
                        if value.count > partnerCommentMaxLength {
                            commentInput = String(value.prefix(partnerCommentMaxLength))
                        }
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

    private func ratingButton(text: String, icon: String, target: PartnerRating, isPositive: Bool) -> some View {
        let isSelected = rating == target
        let bg = isSelected ? Color("main100") : Color("white")
        let border = isSelected ? Color("main105") : Color("grey200")
        let content = isSelected ? Color("main200") : (isPositive ? Color("grey900") : Color("grey500"))
        return Button {
            // 이미 선택된 버튼을 다시 누르면 선택 취소
            rating = isSelected ? .none : target
        } label: {
            HStack(spacing: 8) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(content)
                Text(text)
                    .pretendardText(size: 16, weight: .regular)
                    .foregroundColor(content)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(bg)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

// 임시 빈 프로필 아바타 — 안드 ProfilePlaceholder 대응 공통 컴포넌트는 후속 작업에서 통일.
private struct ReviewProfileAvatar: View {
    let imageUrl: String?
    let size: CGFloat
    var innerStroke: Bool = false

    var body: some View {
        KFImage(imageUrl.flatMap { $0.isEmpty ? nil : URL(string: $0) })
            .placeholder { Color("grey200") }
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size / 2, style: .continuous))
            .overlay {
                if innerStroke {
                    RoundedRectangle(cornerRadius: size / 2, style: .continuous)
                        .stroke(Color("grey100"), lineWidth: 1)
                }
            }
    }
}

#if DEBUG
#Preview {
    let vm = TrackerPartnerReviewViewModel(
        groupId: 0,
        trackerService: TrackerService(interceptor: AuthInterceptor(authService: AuthService()))
    )
    vm.state = TrackerPartnerReviewUiState(
        groupName: "김영하 도장깨기 하실 분",
        myNickname: "나",
        myBookTitle: "살인자의 기억법",
        partnerNickname: "noshel",
        partnerBookTitle: "작별인사"
    )
    return TrackerPartnerReviewView(previewViewModel: vm)
        .environmentObject(DIContainer())
}
#endif
