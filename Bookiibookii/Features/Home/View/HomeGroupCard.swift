import SwiftUI

// 안드 HomeGroupCard / 카드 매핑 대응 — 탐색 탭 리스트형 그룹 카드.

/// 그룹 카드 표시용 공통 데이터. GroupItemDto / AppliedGroupItem / HomeSectionItem 에서 매핑.
struct HomeGroupCardData: Identifiable {
    let groupId: Int
    let bookImage: String?
    let title: String
    let author: String?
    let genre: String?
    let tradeType: String?      // "DIRECT" | "DELIVERY" | 기타
    let readingPeriod: Int
    let hostNickname: String?
    let hostProfileImageUrl: String?
    let groupName: String?

    var id: Int { groupId }

    /// 교환방식 한글 라벨 (DIRECT→직접, DELIVERY→택배).
    var tradeTypeLabel: String {
        switch tradeType {
        case "DIRECT":   return "직접"
        case "DELIVERY": return "택배"
        default:         return tradeType ?? ""
        }
    }

    var authorGenre: String {
        var s = ""
        if let a = author { s += a }
        if let g = genre { s += "(\(g))" }
        return s
    }
}

extension GroupItemDto {
    var homeCardData: HomeGroupCardData {
        HomeGroupCardData(
            groupId: groupId, bookImage: bookImage, title: title ?? "", author: author,
            genre: genre, tradeType: tradeType, readingPeriod: readingPeriod ?? 0,
            hostNickname: hostNickname, hostProfileImageUrl: hostProfileImageUrl,
            groupName: groupName
        )
    }
}

extension AppliedGroupItem {
    var homeCardData: HomeGroupCardData {
        HomeGroupCardData(
            groupId: groupId, bookImage: bookImage, title: bookTitle ?? "", author: author,
            genre: nil, tradeType: tradeType, readingPeriod: readingPeriod,
            hostNickname: hostNickname, hostProfileImageUrl: hostProfileImageUrl,
            groupName: groupName
        )
    }
}

extension HomeSectionItem {
    // 책 항목과 그룹 항목을 겸하는 DTO라 groupId가 없을 수 있다.
    // 없는 id를 만들어내면 존재하지 않는 그룹 상세로 진입하므로 nil로 두고 렌더링에서 제외한다.
    var homeGroupCardData: HomeGroupCardData? {
        guard let groupId else { return nil }
        return HomeGroupCardData(
            groupId: groupId, bookImage: bookImage, title: bookTitle ?? "", author: author,
            genre: genre, tradeType: tradeType, readingPeriod: readingPeriod ?? 0,
            hostNickname: hostNickname, hostProfileImageUrl: hostProfileImageUrl,
            groupName: groupName
        )
    }
}

// MARK: - 책 표지 / 프로필 공통 뷰

struct HomeBookCover: View {
    let imageUrl: String?
    var width: CGFloat
    var height: CGFloat

    var body: some View {
        BookCover(imageUrl: imageUrl)
            .frame(width: width, height: height)
    }
}

struct HomeExchangeBadge: View {
    let text: String
    var body: some View {
        Text(text)
            .pretendardText(size: 11, weight: .medium)
            .foregroundColor(Color("main200"))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color("main100")))
    }
}

// MARK: - 리스트형 그룹 카드 (내 그룹 / 신청한 그룹)

struct HomeGroupCard: View {
    let data: HomeGroupCardData
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 16) {
                HomeBookCover(imageUrl: data.bookImage, width: 72, height: 100)

                VStack(alignment: .leading, spacing: 0) {
                    // 상단: 교환방식 칩 + 제목 + 저자(장르)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            if !data.tradeTypeLabel.isEmpty {
                                HomeExchangeBadge(text: data.tradeTypeLabel)
                            }
                            Text(data.title.stripBookSubtitle())
                                .pretendardText(size: 16, weight: .medium)
                                .foregroundColor(Color("grey900"))
                                .lineLimit(1)
                        }
                        if !data.authorGenre.isEmpty {
                            Text(data.authorGenre)
                                .pretendardText(size: 14)
                                .foregroundColor(Color("grey500"))
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 0)

                    // 하단: 예상 독서 기간 + 호스트 정보
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("예상 독서 기간")
                                .pretendardText(size: 14)
                                .foregroundColor(Color("grey700"))
                            (
                                Text("\(data.readingPeriod)")
                                    .foregroundColor(Color("grey800"))
                                + Text("일")
                                    .foregroundColor(Color("grey700"))
                            )
                            .pretendardText(size: 14)
                        }
                        HStack(spacing: 4) {
                            ProfilePlaceholder(imageUrl: data.hostProfileImageUrl, size: 20)
                            Text(data.hostNickname ?? "")
                                .pretendardText(size: 15)
                                .foregroundColor(Color("grey700"))
                            Text("·")
                                .pretendardText(size: 15)
                                .foregroundColor(Color("grey700"))
                            Text(data.groupName ?? "")
                                .pretendardText(size: 15)
                                .foregroundColor(Color("grey500"))
                                .lineLimit(1)
                        }
                    }
                }
                .frame(height: 100)
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color("white")))
        }
        .buttonStyle(.plain)
    }
}
