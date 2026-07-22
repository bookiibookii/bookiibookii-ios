import SwiftUI

struct LibraryReadingCardItem: View {
    let card: LibraryCard
    var onToggleBookmark: (() -> Void)? = nil
    var onToggleReaction: ((LibraryCardReaction) -> Void)? = nil
    var onTap: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            cardSummary
                .padding(12)
                .frame(height: 147, alignment: .top)

            cardContent
                .frame(height: 128)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 275)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }

    private var cardSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                profileImage

                Text(card.creatorName)
                    .pretendardText(size: 14, weight: .medium)
                    .foregroundColor(Color("grey800"))
                    .lineLimit(1)

                Spacer(minLength: 0)

                if card.isBookmarked {
                    Button {
                        onToggleBookmark?()
                    } label: {
                        Image("ic_bookmark_fill")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color("main200"))
                            .frame(width: 16, height: 16)
                            .frame(width: 20, height: 20)
                            .background(Color("main100"))
                            .clipShape(Circle())
                            .overlay {
                                Circle()
                                    .stroke(Color("main200"), lineWidth: 0.5)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(card.memo)
                .pretendardText(size: 14)
                .foregroundColor(Color("grey800"))
                .lineLimit(3)
                .frame(maxWidth: .infinity, minHeight: 59, alignment: .topLeading)

            HStack {
                if let reaction = card.displayedReaction {
                    Button {
                        onToggleReaction?(reaction)
                    } label: {
                        Image(reaction.iconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
                Text("p.\(card.page)")
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey400"))
            }
        }
    }

    private var profileImage: some View {
        ProfilePlaceholder(imageUrl: card.creatorProfileImageURL, size: 24)
    }

    @ViewBuilder
    private var cardContent: some View {
        switch card.cardType {
        case .image:
            Color("grey200")
                .overlay {
                    if let urlString = card.imageURL,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                Color.clear
                            }
                        }
                    }
                }
                .clipped()

        case .text:
            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: [
                        Color(red: 1, green: 78 / 255, blue: 24 / 255),
                        Color("main200"),
                        Color(red: 1, green: 201 / 255, blue: 164 / 255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(alignment: .leading, spacing: 4) {
                    Image("ic_text")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color("white"))
                        .frame(width: 16, height: 16)

                    Text(card.quotation ?? "")
                        .font(.custom("MaruBuri-Bold", size: 12, relativeTo: .caption))
                        .foregroundColor(Color("white"))
                        .lineSpacing(3)
                        .lineLimit(4)
                }
                .padding(8)
            }
        }
    }
}
