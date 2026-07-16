import SwiftUI

/// 공유 미리보기에서 선택할 수 있는 두 가지 스타일.
/// - 이미지 카드: `divide`(SPLIT) / `card`(OVERLAY)
/// - 텍스트 카드: 레이아웃은 동일하고 색상만 다름 (`divide`=t1 라이트, `card`=t2 다크)
enum LibraryCardShareStyle: Equatable {
    case divide
    case card
}

/// 공유·다운로드용 카드 미리보기.
struct LibraryCardSharePreview: View {
    let detail: LibraryCardDetail
    let style: LibraryCardShareStyle

    var body: some View {
        Group {
            if detail.cardType == .text {
                textShareCard
            } else {
                switch style {
                case .divide: imageDivideStyle
                case .card:   imageCardStyle
                }
            }
        }
    }

    // MARK: - Text share (Figma: logo+title chip, quotation, memo, by.)

    private var isLightTextTheme: Bool { style == .divide }

    private var textShareCard: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                textGradient

                VStack(alignment: .leading, spacing: 8) {
                    bookTitleChip

                    Image("ic_quote")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(isLightTextTheme ? Color("main100") : Color.white.opacity(0.85))
                        .frame(width: 28, height: 28)
                        .padding(.top, 12)

                    Text(displayQuotation)
                        .font(.custom("MaruBuri-Bold", size: 20))
                        .foregroundColor(isLightTextTheme ? Color("main200") : .white)
                        .lineSpacing(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 372)

            VStack(alignment: .trailing, spacing: 4) {
                Text(detail.memo)
                    .pretendardText(size: 15, weight: .regular)
                    .foregroundColor(Color("grey900"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(5)

                Spacer(minLength: 0)

                Text("by. \(detail.creatorName)")
                    .pretendardText(size: 14, weight: .regular)
                    .foregroundColor(Color("grey400"))
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .frame(height: 148)
            .background(Color("white"))
        }
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }

    /// 글귀 그대로 보여주되, 따옴표가 없으면 Figma/안드처럼 감싼다.
    private var displayQuotation: String {
        let raw = (detail.quotation?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap {
            $0.isEmpty ? nil : $0
        } ?? detail.memo
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("“") || trimmed.hasPrefix("\"") || trimmed.hasPrefix("「") {
            return trimmed
        }
        return "“\(trimmed)”"
    }

    private var bookTitleChip: some View {
        HStack(spacing: 8) {
            Image("ic_logo_symbol")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
                .frame(width: 16, height: 16)

            Text(detail.bookTitle ?? "")
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isLightTextTheme ? Color("main200") : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            if !isLightTextTheme {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color("main100"), lineWidth: 1)
            }
        }
    }

    private var textGradient: LinearGradient {
        if isLightTextTheme {
            return LinearGradient(
                colors: [Color("white"), Color("main105")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [
                Color(red: 1, green: 0.31, blue: 0.09),
                Color("main200"),
                Color("main100")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Image divide (SPLIT)

    private var imageDivideStyle: some View {
        VStack(spacing: 0) {
            cardImageView
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(alignment: .topLeading) {
                    HStack(spacing: 6) {
                        Image("ic_logo_symbol")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color("main200"))
                            .frame(width: 18, height: 16)
                        Text(detail.bookTitle ?? "")
                            .pretendardText(size: 13, weight: .medium)
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
                    .pretendardText(size: 14, weight: .regular)
                    .foregroundColor(Color("grey900"))
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    Spacer()
                    Text("by. \(detail.creatorName)")
                        .pretendardText(size: 12, weight: .regular)
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

    // MARK: - Image card (OVERLAY)

    private var imageCardStyle: some View {
        ZStack {
            cardImageView
                .aspectRatio(3.0 / 4.0, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()

            VStack(alignment: .leading, spacing: 12) {
                Text(detail.bookTitle ?? "")
                    .pretendardText(size: 14, weight: .medium)
                    .foregroundColor(Color("main200"))
                    .lineLimit(1)

                Text(detail.memo)
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color.white)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                HStack {
                    Text("by. \(detail.creatorName)")
                        .pretendardText(size: 12, weight: .regular)
                        .foregroundColor(Color.white)
                    Spacer()
                    Image("ic_logo_symbol")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 22, height: 22)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Image

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
