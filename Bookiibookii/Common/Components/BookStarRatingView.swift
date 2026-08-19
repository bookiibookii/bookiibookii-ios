import SwiftUI

/// 0.5점 단위 별점 표시.
/// - 1점: `sub200` (진한 파란)
/// - 0.5점: `sub100` 채움 + `sub200` 외곽선
/// - 0점: `grey300` 외곽선
struct BookStarRatingView: View {
    let rating: Double
    var starSize: CGFloat = 16
    var spacing: CGFloat = 0

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<5, id: \.self) { index in
                starIcon(starValue: min(max(rating - Double(index), 0), 1))
            }
        }
    }

    @ViewBuilder
    private func starIcon(starValue: Double) -> some View {
        ZStack {
            if starValue >= 0.75 {
                starImage("ic_star_fill", Color("sub200"))
            } else if starValue >= 0.25 {
                starImage("ic_star_fill", Color("sub100"))
                starImage("ic_star", Color("sub200"))
            } else {
                starImage("ic_star", Color("grey300"))
            }
        }
        .frame(width: starSize, height: starSize)
    }

    private func starImage(_ name: String, _ color: Color) -> some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: starSize, height: starSize)
            .foregroundColor(color)
    }
}
