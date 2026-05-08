import SwiftUI

/// 함께읽기 그룹 종료 후 책 리뷰를 작성하는 화면.
/// `POST /api/reviews/together/{userBookId}` 로 `rating(Double)` 과 `comment`를 전송합니다.
struct TogetherReviewView: View {
    @EnvironmentObject private var container: DIContainer

    let userBookId: Int
    let bookTitle: String
    let groupService: GroupService

    /// 0, 0.5, 1.0, 1.5, ... , 5.0 (0.5 단위)
    @State private var rating: Double = 0
    @State private var reviewText: String = ""
    @State private var isSubmitting = false
    @State private var toastMessage: String?

    private var trimmedReviewText: String {
        reviewText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        rating > 0 && !isSubmitting
    }

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        ratingSection
                        reviewSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }
            }

            submitButton
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .alert("안내", isPresented: Binding(
            get: { toastMessage != nil },
            set: { if !$0 { toastMessage = nil } }
        )) {
            Button("확인", role: .cancel) { toastMessage = nil }
        } message: {
            Text(toastMessage ?? "")
        }
    }

    private var header: some View {
        HStack {
            Button {
                container.navigationRouter.pop()
            } label: {
                Image("ic_back")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            Spacer()
            Text("후기 남기기")
                .font(.pretendard(size: 20, weight: .medium))
                .foregroundColor(Color("grey900"))
            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Divider().overlay(Color("grey200"))
        }
    }

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("'\(bookTitle)'에 대한 평가를 남겨주세요!")
                .font(.pretendard(size: 18, weight: .medium))
                .foregroundColor(Color("grey900"))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { idx in
                    Button {
                        toggleStar(at: idx)
                    } label: {
                        starImage(for: idx)
                            .font(.system(size: 32))
                            .foregroundColor(starColor(for: idx))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Text(ratingLabel)
                .font(.pretendard(size: 13, weight: .regular))
                .foregroundColor(Color("grey500"))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    /// 0.5 단위 토글 로직.
    /// - 처음 누르면 해당 인덱스까지 가득 (rating == idx)
    /// - 같은 별을 한 번 더 누르면 해당 별만 반쪽 (rating == idx - 0.5)
    /// - 그 다음 또 누르면 다시 가득으로 돌아감
    private func toggleStar(at idx: Int) {
        let target = Double(idx)
        if rating == target {
            rating = target - 0.5
        } else {
            rating = target
        }
    }

    private func starImage(for idx: Int) -> Image {
        Image(systemName: rating >= Double(idx) - 0.5 ? "star.fill" : "star")
    }

    /// 가득찬 별: `main200`, 반쪽 별: `main105`, 비어있는 별: `grey200`.
    private func starColor(for idx: Int) -> Color {
        if rating >= Double(idx) {
            return Color("main200")
        }
        if rating >= Double(idx) - 0.5 {
            return Color("main105")
        }
        return Color("grey200")
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("후기")
                .font(.pretendard(size: 14, weight: .medium))
                .foregroundColor(Color("grey800"))

            ZStack(alignment: .topLeading) {
                if reviewText.isEmpty {
                    Text("이번 독서 경험을 자유롭게 남겨주세요.")
                        .font(.pretendard(size: 14, weight: .regular))
                        .foregroundColor(Color("grey400"))
                        .padding(.top, 12)
                        .padding(.leading, 10)
                }

                TextEditor(text: $reviewText)
                    .font(.pretendard(size: 14, weight: .regular))
                    .foregroundColor(Color("grey900"))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 180)
            }
            .padding(2)
            .background(Color("grey100"))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color("grey200"), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text("\(reviewText.count)/500")
                .font(.pretendard(size: 12, weight: .regular))
                .foregroundColor(Color("grey500"))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var submitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            Text(isSubmitting ? "등록 중..." : "후기 남기기")
                .font(.pretendard(size: 18, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(canSubmit ? Color("grey900") : Color("grey400"))
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
    }

    private var ratingLabel: String {
        switch rating {
        case 0:                  return "별점을 선택해 주세요"
        case 0.5...1.0:          return "아쉬웠어요"
        case 1.5...2.0:          return "그저 그랬어요"
        case 2.5...3.0:          return "괜찮았어요"
        case 3.5...4.0:          return "좋았어요"
        case 4.5...5.0:          return "최고였어요"
        default:                 return "별점을 선택해 주세요"
        }
    }

    private func submit() async {
        guard canSubmit else { return }
        guard reviewText.count <= 500 else {
            toastMessage = "후기는 500자 이내로 작성해 주세요."
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await groupService.createTogetherReview(
                userBookId: userBookId,
                rating: rating,
                comment: trimmedReviewText.isEmpty ? nil : trimmedReviewText
            )
            container.navigationRouter.pop()
        } catch {
            toastMessage = error.localizedDescription
        }
    }
}
