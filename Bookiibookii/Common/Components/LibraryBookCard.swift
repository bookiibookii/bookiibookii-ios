import SwiftUI

struct LibraryBookCard: View {
    let book: LibraryBook
    var onTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                AsyncImage(url: URL(string: book.coverImageURL ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Color("grey300")
                    }
                }
                .frame(height: 166)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(book.status.badgeText)
                    .font(.pretendard(size: 12, weight: book.status == .matched ? .medium : .regular))
                    .foregroundColor(book.status == .matched ? .white : Color("grey100"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(book.status == .matched ? Color("main200") : Color("grey400"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(10)
            }

            Text(book.title)
                .font(.pretendard(size: 11, weight: .medium))
                .foregroundColor(Color("grey900"))
                .lineLimit(1)

            if book.status == .completed {
                StarRow(rating: book.rating ?? 0)
            }

            HStack(spacing: 8) {
                Circle()
                    .fill(Color("grey300"))
                    .frame(width: 16, height: 16)
                Text(book.hostNickname)
                    .font(.pretendard(size: 11, weight: .medium))
                    .foregroundColor(Color("grey700"))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

private struct StarRow: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { index in
                let filled = Double(index + 1) <= rating
                Image(systemName: filled ? "star.fill" : "star")
                    .font(.system(size: 10))
                    .foregroundColor(Color("main100"))
            }
        }
    }
}
