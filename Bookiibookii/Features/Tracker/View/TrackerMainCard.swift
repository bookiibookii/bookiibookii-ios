import SwiftUI
import Kingfisher

struct TrackerMainCard: View {
    let card: TrackerCardModel
    let onCardClick: () -> Void
    let onPrimaryAction: () -> Void
    let onSecondaryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            TrackerCardHeader(card: card)
            HStack(spacing: 16) {
                TrackerProfileColumn(profile: card.left, showProgress: card.showReadingProgress)
                TrackerProfileColumn(profile: card.right, showProgress: card.showReadingProgress)
            }
            // secondary가 없으면 primary 단일 풀폭 버튼 (예: 교환독서 후기 작성)
            if card.secondaryAction.label.isEmpty {
                CardButton(
                    text: card.primaryAction.label,
                    style: card.primaryEnabled ? .main : .grey,
                    action: onPrimaryAction
                )
                .disabled(!card.primaryEnabled)
                .frame(maxWidth: .infinity)
            } else {
                HStack(spacing: 12) {
                    CardButton(
                        text: card.secondaryAction.label,
                        style: card.secondaryEnabled ? .white : .grey,
                        action: onSecondaryAction
                    )
                    .disabled(!card.secondaryEnabled)
                    CardButton(
                        text: card.primaryAction.label,
                        style: card.primaryEnabled ? .main : .grey,
                        action: onPrimaryAction
                    )
                    .disabled(!card.primaryEnabled)
                }
            }
        }
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture(perform: onCardClick)
    }
}

private struct TrackerCardHeader: View {
    let card: TrackerCardModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.groupName)
                        .pretendardText(size: 16, weight: .medium)
                        .foregroundColor(Color("grey800"))
                    HStack(spacing: 4) {
                        Text(ellipsizeTitle(card.displayBookTitle.stripBookSubtitle(), maxChars: 18))
                            .pretendardText(size: 14)
                            .foregroundColor(Color("grey500"))
                        Text("·")
                            .pretendardText(size: 14)
                            .foregroundColor(Color("grey500"))
                        Text(card.progressLabel)
                            .pretendardText(size: 14)
                            .foregroundColor(Color("grey500"))
                    }
                }
                Spacer(minLength: 8)
                TrackerDDayChip(text: card.dDay)
            }
            .padding(.bottom, 8)
            Rectangle()
                .fill(Color("grey100"))
                .frame(height: 0.8)
        }
    }
}

private struct TrackerDDayChip: View {
    let text: String

    var body: some View {
        Text(text)
            .pretendardText(size: 11, weight: .medium)
            .foregroundColor(Color("grey700"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color("grey100"))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct TrackerProfileColumn: View {
    let profile: TrackerProfileItem
    let showProgress: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 8) {
                BookCover(imageUrl: profile.bookCoverUrl)
                    .frame(width: 100, height: 132)

                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text(profile.nickname)
                            .pretendardText(size: 14)
                            .foregroundColor(Color("grey700"))
                        Text(profile.bookTitle.stripBookSubtitle())
                            .pretendardText(size: 16, weight: .medium)
                            .foregroundColor(Color("grey800"))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    if showProgress {
                        VStack(spacing: 6) {
                            TrackerProgressBar(percent: profile.progressPercent)
                            Text(profile.progressLabelOverride ?? "\(profile.progressPercent)%")
                                .pretendardText(size: 14)
                                .foregroundColor(Color("grey800"))
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 12)

            ProfilePlaceholder(imageUrl: profile.profileImageUrl, size: 44, innerStroke: true)
                .offset(x: 17, y: 0)
        }
    }
}

private struct TrackerProgressBar: View {
    let percent: Int

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color("grey200"))
                Rectangle()
                    .fill(Color("grey800"))
                    .frame(width: proxy.size.width * CGFloat(min(max(percent, 0), 100)) / 100)
            }
        }
        .frame(height: 6)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

#Preview("TrackerMainCard") {
    ScrollView {
        VStack(spacing: 16) {
            TrackerMainCard(
                card: TrackerCardModel(
                    groupId: 0,
                    groupName: "일이삼사오육칠팔구십일이삼사오육칠팔구십일이삼",
                    displayBookTitle: "살인자의 기억법",
                    bookTitle: "살인자의 기억법",
                    progressLabel: "읽는 중",
                    dDay: "D-5",
                    left: TrackerProfileItem(
                        nickname: "나",
                        bookTitle: "살인자의 기억법 살인자의 기억법",
                        bookCoverUrl: nil,
                        profileImageUrl: nil,
                        progressPercent: 48,
                        isOwnerBook: true
                    ),
                    right: TrackerProfileItem(
                        nickname: "noshel",
                        bookTitle: "작별인사",
                        bookCoverUrl: nil,
                        profileImageUrl: nil,
                        progressPercent: 48,
                        isOwnerBook: false
                    ),
                    primaryAction: .recordProgress,
                    secondaryAction: .writeReadingCard
                ),
                onCardClick: {},
                onPrimaryAction: {},
                onSecondaryAction: {}
            )
            TrackerMainCard(
                card: TrackerCardModel(
                    groupId: 1,
                    groupName: "김영하 도장깨기 하실 분",
                    displayBookTitle: "살인자의 기억법",
                    bookTitle: "살인자의 기억법",
                    progressLabel: "후기 작성",
                    dDay: "D-3",
                    left: TrackerProfileItem(
                        nickname: "나",
                        bookTitle: "살인자의 기억법",
                        bookCoverUrl: nil,
                        profileImageUrl: nil,
                        progressPercent: 100,
                        isOwnerBook: true
                    ),
                    right: TrackerProfileItem(
                        nickname: "noshel",
                        bookTitle: "작별인사",
                        bookCoverUrl: nil,
                        profileImageUrl: nil,
                        progressPercent: 100,
                        isOwnerBook: false
                    ),
                    primaryAction: .writeBookReview,
                    secondaryAction: .none
                ),
                onCardClick: {},
                onPrimaryAction: {},
                onSecondaryAction: {}
            )
            TrackerMainCard(
                card: TrackerCardModel(
                    groupId: 2,
                    groupName: "독서 모임 셋째",
                    displayBookTitle: "데미안",
                    bookTitle: "데미안",
                    progressLabel: "교환 중",
                    dDay: "D-7",
                    left: TrackerProfileItem(
                        nickname: "나",
                        bookTitle: "데미안",
                        bookCoverUrl: nil,
                        profileImageUrl: nil,
                        progressPercent: 20,
                        isOwnerBook: true
                    ),
                    right: TrackerProfileItem(
                        nickname: "partner3",
                        bookTitle: "1984",
                        bookCoverUrl: nil,
                        profileImageUrl: nil,
                        progressPercent: 35,
                        isOwnerBook: false
                    ),
                    primaryAction: .confirmExchange,
                    secondaryAction: .checkMeeting,
                    secondaryEnabled: false
                ),
                onCardClick: {},
                onPrimaryAction: {},
                onSecondaryAction: {}
            )
        }
        .padding(16)
    }
    .background(Color("uiBg"))
}
