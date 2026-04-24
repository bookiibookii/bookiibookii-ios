import SwiftUI
import Kingfisher

// 심플 버전 — 이번 PR 범위.
// 릴레이 진행바 / 함께읽기 독서율 바는 후속 PR에서 exchangeType 분기로 추가.
struct TrackerCard: View {
    let item: TrackerItem
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            cover
            info
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private var cover: some View {
        KFImage(item.coverImageUrl.flatMap(URL.init(string:)))
            .placeholder { Color("grey300") }
            .retry(maxCount: 2)
            .cancelOnDisappear(true)
            .resizable()
            .scaledToFill()
            .frame(width: 60, height: 85)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color("grey200"), lineWidth: 1)
            )
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.bookTitle)
                .font(.pretendard(size: 16, weight: .medium))
                .foregroundColor(Color("grey800"))
                .lineLimit(1)
                .truncationMode(.tail)

            Text(authorLine)
                .font(.pretendard(size: 12))
                .foregroundColor(Color("grey600"))
                .lineLimit(1)

            Spacer().frame(height: 8)

            if let name = item.withUserName, !name.isEmpty {
                HStack(spacing: 4) {
                    Text("with")
                        .font(.pretendard(size: 12, weight: .medium))
                        .foregroundColor(Color("grey500"))
                    Text(name)
                        .font(.pretendard(size: 12, weight: .medium))
                        .foregroundColor(Color("grey800"))
                        .lineLimit(1)
                }
            }
        }
    }

    private var authorLine: String {
        let category = TrackerCategoryMapper.displayKo(item.bookCategory)
        if category.isEmpty { return item.bookAuthor }
        return "\(item.bookAuthor) (\(category))"
    }
}

#Preview("릴레이 Host") {
    TrackerCard(
        item: TrackerItem(
            id: 1, groupId: 1,
            role: .host, exchangeType: .delivery,
            bookTitle: "참을 수 없는 존재의 가벼움",
            bookAuthor: "밀란 쿤데라", bookCategory: "NOVEL_GENRE",
            coverImageUrl: nil, withUserName: "noshel"
        ),
        onTap: {}
    )
    .padding()
    .background(Color("grey100"))
}

#Preview("함께읽기 participant+N") {
    TrackerCard(
        item: TrackerItem(
            id: 2, groupId: 2,
            role: .host, exchangeType: .none,
            bookTitle: "살인자의 기억법",
            bookAuthor: "김영하", bookCategory: "NOVEL_GENRE",
            coverImageUrl: nil, withUserName: "noshel +29"
        ),
        onTap: {}
    )
    .padding()
    .background(Color("grey100"))
}
