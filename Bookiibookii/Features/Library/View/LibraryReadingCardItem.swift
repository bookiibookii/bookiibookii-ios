import SwiftUI

struct LibraryReadingCardItem: View {
    let card: LibraryCard
    let onToggleBookmark: () -> Void
    var onTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Circle().fill(Color("grey300")).frame(width: 16, height: 16)
                    Text(card.creatorName)
                        .font(.pretendard(size: 11, weight: .regular))
                        .foregroundColor(Color("grey700"))
                }
                Spacer()
                Button(action: onToggleBookmark) {
                    Image("ic_bookmark")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(card.isBookmarked ? Color("main200") : Color("grey300"))
                        .frame(width: 11, height: 11)
                        .frame(width: 20, height: 20)
                        .background(card.isBookmarked ? Color("main100") : Color("grey100"))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(!card.isBookmarkable)
                .opacity(card.isBookmarkable ? 1 : 0.35)
            }

            if let title = card.bookTitle, !title.isEmpty {
                Text(title)
                    .font(.pretendard(size: 10, weight: .medium))
                    .foregroundColor(Color("grey500"))
                    .lineLimit(1)
            }

            Text(card.memo)
                .font(.pretendard(size: 11, weight: .medium))
                .foregroundColor(Color("grey800"))
                .lineLimit(3)

            HStack {
                HStack(spacing: 2) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(Color("main200"))
                    Text("\(card.messageCount)")
                        .font(.pretendard(size: 10, weight: .regular))
                        .foregroundColor(Color("grey600"))
                }
                Spacer()
                Text("\(card.page)pg")
                    .font(.pretendard(size: 10, weight: .regular))
                    .foregroundColor(Color("grey400"))
            }

            Color("grey200")
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .overlay(
                    AsyncImage(url: URL(string: card.imageURL ?? "")) { phase in
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
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}
