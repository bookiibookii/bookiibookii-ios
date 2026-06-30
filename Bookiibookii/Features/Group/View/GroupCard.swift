import SwiftUI
import Kingfisher

struct GroupCard: View {
    let item: GroupItemDto
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topRow
            if !displayTags.isEmpty {
                tagRow
                    .padding(.top, 12)
            }
        }
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    // MARK: - 상단 (표지 + 정보)
    // 안드로이드 item_grp_card.xml 기준: 프로필·닉네임·날짜는 표지 오른쪽 텍스트 컬럼 내부,
    // 메타 row 아래에 위치 (카드 왼쪽이 아님).

    private var topRow: some View {
        HStack(alignment: .top, spacing: 12) {
            cover
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    titleAndAuthor
                    Spacer(minLength: 8)
                    statusBadge
                }
                metaRow
                    .padding(.top, 12)
                profileRow
                    .padding(.top, 4)
            }
        }
    }

    private var cover: some View {
        KFImage(item.bookImage.flatMap(URL.init(string:)))
            .placeholder { Color("grey300") }
            .retry(maxCount: 2)
            .cancelOnDisappear(true)
            .resizable()
            .scaledToFill()
            .frame(width: 74, height: 94)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var titleAndAuthor: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .pretendardText(size: 14, weight: .regular)
                .foregroundColor(Color("black"))
                .lineLimit(1)
                .truncationMode(.tail)

            HStack(spacing: 4) {
                Text(item.displayAuthor)
                    .pretendardText(size: 11)
                    .foregroundColor(Color("grey500"))
                    .lineLimit(1)
                if let genre = item.displayGenre {
                    Text(genre)
                        .pretendardText(size: 11)
                        .foregroundColor(Color("grey500"))
                        .lineLimit(1)
                }
            }
        }
    }

    private var statusBadge: some View {
        let (bg, text): (Color, String) = item.isTogether
            ? (Color("grey900"), "함께읽기(\(item.maxCapacity))")
            : (Color("main200"), item.badgeText)
        return Text(text)
            .pretendardText(size: 11, weight: .medium)
            .foregroundColor(Color("white"))
            .padding(.horizontal, 8)
            .frame(height: 23)
            .background(Capsule().fill(bg))
    }

    private var metaRow: some View {
        HStack(spacing: 4) {
            Image("ic_calender")
                .renderingMode(.template)
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundColor(Color("grey500"))
            Text("\(item.readingPeriod)일")
                .pretendardText(size: 11)
                .foregroundColor(Color("grey500"))

            Rectangle()
                .fill(Color("grey400"))
                .frame(width: 1, height: 10)
                .padding(.horizontal, 2)

            Image("ic_group")
                .renderingMode(.template)
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundColor(Color("grey500"))
            Text("\(item.currentCount)명 대기")
                .pretendardText(size: 11)
                .foregroundColor(Color("grey500"))

            if item.isHot { hotBadge }
        }
    }

    private var hotBadge: some View {
        Text("HOT")
            .pretendardText(size: 11, weight: .medium)
            .foregroundColor(Color("main200"))
            .padding(.horizontal, 6)
            .frame(height: 16)
            .background(Capsule().fill(Color("main100")))
    }

    // MARK: - 프로필 + 날짜

    private var profileRow: some View {
        HStack(spacing: 4) {
            KFImage(item.hostProfileImageUrl.flatMap(URL.init(string:)))
                .placeholder { Image("ic_profile_placeholder").resizable() }
                .retry(maxCount: 2)
                .cancelOnDisappear(true)
                .resizable()
                .scaledToFill()
                .frame(width: 20, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(item.displayNickname)
                .pretendardText(size: 12)
                .foregroundColor(Color("grey700"))
                .padding(.leading, 4)

            Text(item.displayDate)
                .pretendardText(size: 11)
                .foregroundColor(Color("grey400"))
                .padding(.leading, 4)

            Spacer()
        }
    }

    // MARK: - 태그

    private var displayTags: [String] {
        var all: [String] = []
        if let c = item.customTag, !c.isEmpty { all.append("#\(c)") }
        (item.tags ?? []).forEach { all.append(GroupTagMapper.koreanTag($0)) }
        return all
    }

    private var tagRow: some View {
        let all = displayTags
        let visible = Array(all.prefix(3))
        let extra = all.count - visible.count
        return HStack(spacing: 8) {
            ForEach(visible.indices, id: \.self) { idx in
                tagChip(visible[idx])
            }
            if extra > 0 {
                tagChip("+\(extra)")
            }
            Spacer()
        }
    }

    private func tagChip(_ text: String) -> some View {
        Text(text)
            .pretendardText(size: 11, weight: .medium)
            .foregroundColor(Color("sub200"))
            .padding(.horizontal, 10)
            .frame(height: 23)
            .background(Capsule().fill(Color("sub100")))
    }
}

#Preview("모집 중 + RELAY") {
    GroupCard(
        item: GroupItemDto(
            groupId: 1, groupName: "괴테 같이 읽어요", title: "괴테는 모든 것을 말했다",
            author: "한강", genre: "소설", bookImage: nil,
            hostProfileImageUrl: nil, hostNickname: "noshel",
            tags: ["MEMO", "INSIGHT", "CLEAN", "SLOW", "SCI_IT"],
            groupStatus: "RECRUITING", currentCount: 2, maxCapacity: 4,
            waitingCount: 1, readingPeriod: 7, customTag: nil,
            groupType: "RELAY", tradeType: "DELIVERY",
            startDate: "2025-12-16", isHot: true, pictureBadge: "마포구",
            displayStatus: nil
        ),
        onTap: {}
    )
    .padding()
    .background(Color("grey100"))
}

#Preview("함께읽기 TOGETHER") {
    GroupCard(
        item: GroupItemDto(
            groupId: 2, groupName: "소년이 온다 함께", title: "소년이 온다",
            author: "한강", genre: "소설", bookImage: nil,
            hostProfileImageUrl: nil, hostNickname: "noshel",
            tags: ["MEMO"],
            groupStatus: "RECRUITING", currentCount: 2, maxCapacity: 3,
            waitingCount: 0, readingPeriod: 7, customTag: "커스텀",
            groupType: "TOGETHER", tradeType: nil,
            startDate: "2025-12-16", isHot: false, pictureBadge: nil,
            displayStatus: nil
        ),
        onTap: {}
    )
    .padding()
    .background(Color("grey100"))
}
