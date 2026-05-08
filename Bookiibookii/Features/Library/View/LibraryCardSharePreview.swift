import SwiftUI

/// 공유 미리보기에서 선택할 수 있는 두 가지 스타일.
/// - `divide`: 책 제목 / 카드 이미지 / 메모·작성자 영역이 위·아래로 분리된 형태 (`ic_divide_image`).
/// - `card` : 카드 이미지 위에 메모·작성자가 오버레이되는 형태 (`ic_card_image`).
enum LibraryCardShareStyle: Equatable {
    case divide
    case card
}

/// 공유용 카드 미리보기.
///
/// 동일한 데이터(`책 제목`, `카드 이미지`, `메모`, `작성자`)를 받아
/// 선택된 `LibraryCardShareStyle`에 따라 두 가지 디자인 중 하나로 렌더링합니다.
struct LibraryCardSharePreview: View {
    let detail: LibraryCardDetail
    let style: LibraryCardShareStyle

    var body: some View {
        switch style {
        case .divide: divideStyle
        case .card:   cardStyle
        }
    }

    // MARK: - Divide 스타일 (제목/이미지/메모가 분리된 형태)

    private var divideStyle: some View {
        VStack(spacing: 0) {
            cardImageView
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(alignment: .topLeading) {
                    HStack(spacing: 6) {
                        Image("divide_image_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 16)
                        Text(detail.bookTitle ?? "")
                            .font(.pretendard(size: 13, weight: .medium))
                            .foregroundColor(Color("main200"))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color("main105"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(12)
                }

            VStack(alignment: .leading, spacing: 12) {
                Text(detail.memo)
                    .font(.pretendard(size: 14, weight: .regular))
                    .foregroundColor(Color("grey900"))
                    .lineSpacing(14 * 0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    Spacer()
                    Text(detail.creatorName)
                        .font(.pretendard(size: 12, weight: .regular))
                        .foregroundColor(Color("grey500"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("grey200"), lineWidth: 1)
        )
    }

    // MARK: - Card 스타일 (이미지 위에 메모/작성자 오버레이)

    private var cardStyle: some View {
        ZStack {
            cardImageView
                .aspectRatio(3.0/4.0, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()

            VStack(alignment: .leading, spacing: 12) {
                Text(detail.bookTitle ?? "")
                    .font(.pretendard(size: 14, weight: .medium))
                    .foregroundColor(Color("main200"))
                    .lineLimit(1)

                Text(detail.memo)
                    .font(.pretendard(size: 16, weight: .medium))
                    .foregroundColor(Color.white)
                    .lineSpacing(16 * 0.5)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                HStack {
                    Text(detail.creatorName)
                        .font(.pretendard(size: 12, weight: .regular))
                        .foregroundColor(Color.white)
                    Spacer()
                    Image("card_image_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(3.0/4.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 이미지

    @ViewBuilder
    private var cardImageView: some View {
        Color("grey200")
            .overlay(
                AsyncImage(url: URL(string: detail.imageURL ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty, .failure:
                        EmptyView()
                    @unknown default:
                        EmptyView()
                    }
                }
            )
    }
}
