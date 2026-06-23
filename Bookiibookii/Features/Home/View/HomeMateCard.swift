import SwiftUI
import Kingfisher

// 안드로이드 item_home_mate_card.xml 대응
// 흰 라운드 카드 + 40x40 프로필 + 닉네임/태그칩 Row + 최근 완독 책 + 우측 화살표.
struct HomeMateCard: View {
    let item: RecommendedBookmateDto
    var onTap: () -> Void = {}

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            profileImage

            VStack(alignment: .leading, spacing: 6) {
                titleRow
                Text(item.displayRecentBook)
                    .font(.pretendard(size: 12))
                    .foregroundColor(Color("grey600"))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color("grey400"))
                .frame(width: 20, height: 20)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("white"))
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private var profileImage: some View {
        KFImage(item.profileImageUrl.flatMap(URL.init(string:)))
            .placeholder { Image("ic_profile_placeholder").resizable() }
            .retry(maxCount: 2)
            .cancelOnDisappear(true)
            .resizable()
            .scaledToFill()
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 15))
    }

    private var titleRow: some View {
        HStack(spacing: 6) {
            Text(item.nickname)
                .font(.pretendard(size: 15, weight: .bold))
                .foregroundColor(Color("grey900"))
                .lineLimit(1)

            ForEach(displayTags, id: \.self) { tag in
                tagChip(tag)
            }
        }
    }

    private var displayTags: [String] {
        let tags = (item.matchedTags ?? []).prefix(2)
        return tags.map { GroupTagMapper.koreanTag($0) }
    }

    private func tagChip(_ text: String) -> some View {
        Text(text)
            .font(.pretendard(size: 11, weight: .medium))
            .foregroundColor(Color("main200"))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color("main100")))
    }
}

#Preview {
    VStack(spacing: 12) {
        HomeMateCard(item: RecommendedBookmateDto(
            userId: 1,
            nickname: "마로형",
            profileImageUrl: nil,
            matchedTags: ["MEMO", "INSIGHT"],
            recentBookTitle: "가장 최근에 완독한 책 제목"
        ))
        HomeMateCard(item: RecommendedBookmateDto(
            userId: 2,
            nickname: "길동",
            profileImageUrl: nil,
            matchedTags: ["CLEAN"],
            recentBookTitle: nil
        ))
    }
    .padding(20)
    .background(Color("grey100"))
}
