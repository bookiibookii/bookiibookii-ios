import SwiftUI
import Kingfisher

// 그룹 탐색 카드. (안드 ExploreGroupCard)
struct ExploreGroupCard: View {
    let item: GroupItemDto
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            cover
            VStack(alignment: .leading, spacing: 0) {
                topBlock
                Spacer(minLength: 0)
                bottomBlock
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private var cover: some View {
        KFImage(item.bookImage.flatMap(URL.init(string:)))
            .placeholder { Color("grey300") }
            .retry(maxCount: 2)
            .cancelOnDisappear(true)
            .resizable()
            .scaledToFill()
            .frame(width: 72, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var topBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if let badge = exchangeBadgeText {
                    Text(badge)
                        .pretendardText(size: 11, weight: .medium)
                        .foregroundColor(Color("main200"))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color("main100")))
                }
                Text(strippedTitle)
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey900"))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Text("\(item.displayAuthor)(\(item.genre ?? ""))")
                .pretendardText(size: 14)
                .foregroundColor(Color("grey500"))
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    private var bottomBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text("예상 독서 기간")
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey700"))
                Text("\(item.readingPeriod)")
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey800"))
                Text("일")
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey700"))
            }
            HStack(spacing: 4) {
                ProfilePlaceholder(imageUrl: item.hostProfileImageUrl, size: 20)
                Text(item.displayNickname)
                    .pretendardText(size: 15)
                    .foregroundColor(Color("grey700"))
                Text("·")
                    .pretendardText(size: 15)
                    .foregroundColor(Color("grey700"))
                Text(item.groupName ?? "")
                    .pretendardText(size: 15)
                    .foregroundColor(Color("grey500"))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }

    // tradeType DIRECT→"직접", DELIVERY→"택배", 그 외 미표시 (안드 tradeTypeLabel)
    private var exchangeBadgeText: String? {
        switch item.tradeType {
        case "DIRECT": return "직접"
        case "DELIVERY": return "택배"
        default: return nil
        }
    }

    private var strippedTitle: String { (item.title ?? "").stripBookSubtitle() }
}
