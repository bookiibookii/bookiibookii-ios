import SwiftUI
import Kingfisher

// 안드로이드 item_home_group_card.xml 대응
// 3컬럼 그리드의 작은 카드. 표지(3:4) + 제목 1줄.
struct HomeRecommendedGroupCard: View {
    let item: RecommendedGroupDto
    var onTap: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            KFImage(item.bookImageUrl.flatMap(URL.init(string:)))
                .placeholder { Color("grey200") }
                .retry(maxCount: 2)
                .cancelOnDisappear(true)
                .resizable()
                .scaledToFill()
                .aspectRatio(3.0/4.0, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("grey200"), lineWidth: 1)
                )

            Text(item.displayTitle)
                .pretendardText(size: 12)
                .foregroundColor(Color("grey900"))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.top, 8)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

#Preview {
    HStack(spacing: 12) {
        HomeRecommendedGroupCard(item: RecommendedGroupDto(
            groupId: 1,
            bookTitle: "괴테는 모든 것을 말했다",
            bookImageUrl: nil
        ))
        HomeRecommendedGroupCard(item: RecommendedGroupDto(
            groupId: 2,
            bookTitle: "소년이 온다",
            bookImageUrl: nil
        ))
        HomeRecommendedGroupCard(item: RecommendedGroupDto(
            groupId: 3,
            bookTitle: "작별하지 않는다",
            bookImageUrl: nil
        ))
    }
    .padding(20)
    .background(Color("grey100"))
}
