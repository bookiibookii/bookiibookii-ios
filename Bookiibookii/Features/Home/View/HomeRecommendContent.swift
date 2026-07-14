import SwiftUI

// 안드 homeRecommendContent + HomeRecommendGroupCard + HomeRecommendBookSections 대응.

private enum HomeLayout {
    static let supported: Set<String> = [
        HomeLayoutType.groupCardCarousel,
        HomeLayoutType.bookThumbnailCarousel,
        HomeLayoutType.bookThumbnailGrid
    ]
}

// MARK: - 추천 탭 콘텐츠

struct HomeRecommendContent: View {
    let sections: [HomeSection]
    var onGroupTap: (Int) -> Void
    var onBookTap: (HomeSectionItem) -> Void

    private var visibleSections: [HomeSection] {
        sections.filter { !$0.items.isEmpty && HomeLayout.supported.contains($0.layoutType) }
    }

    var body: some View {
        VStack(spacing: 8) {
            Color("grey100").frame(height: 8)
            ForEach(Array(visibleSections.enumerated()), id: \.offset) { _, section in
                sectionView(section)
            }
            Color.clear.frame(height: 80)
        }
    }

    @ViewBuilder
    private func sectionView(_ section: HomeSection) -> some View {
        switch section.layoutType {
        case HomeLayoutType.groupCardCarousel:
            HomeGroupCarouselSection(section: section, onGroupTap: onGroupTap)
        case HomeLayoutType.bookThumbnailCarousel:
            HomeBookCarouselSection(section: section, onBookTap: onBookTap)
        case HomeLayoutType.bookThumbnailGrid:
            HomeBookGridSection(section: section, onBookTap: onBookTap)
        default:
            EmptyView()
        }
    }
}

// MARK: - 섹션 헤더

private struct HomeSectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .pretendardText(size: 20)
                .foregroundColor(Color("grey900"))
            Text(subtitle)
                .pretendardText(size: 16)
                .foregroundColor(Color("grey600"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 그룹 카드 캐러셀 섹션

private struct HomeGroupCarouselSection: View {
    let section: HomeSection
    var onGroupTap: (Int) -> Void
    @State private var scrolledIndex: Int?

    // 안드 HorizontalPager(pageSize=Fixed(334.dp), pageSpacing=12, contentPadding=16)와 동일.
    // 카드 너비를 화면보다 좁게 고정 → 오른쪽 다음 카드가 살짝 보임(peek).
    private let horizontalInset: CGFloat = 16
    private let cardSpacing: CGFloat = 12
    private let cardWidth: CGFloat = 334

    private var cards: [HomeGroupCardData] { section.items.map { $0.homeGroupCardData } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader(title: section.title, subtitle: section.subtitle)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: cardSpacing) {
                    ForEach(Array(cards.enumerated()), id: \.offset) { index, data in
                        HomeRecommendGroupCard(data: data, onTap: { onGroupTap(data.groupId) })
                            .frame(width: cardWidth)
                            .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, horizontalInset, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrolledIndex, anchor: .leading)
            .frame(height: 200)

            if cards.count > 1 {
                HStack(spacing: 6) {
                    ForEach(cards.indices, id: \.self) { i in
                        Circle()
                            .fill(i == (scrolledIndex ?? 0) ? Color("grey400") : Color("grey200"))
                            .frame(width: 8, height: 8)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
    }
}

// 추천 그룹 카드 (그림자 + 자세히 보기 버튼)
private struct HomeRecommendGroupCard: View {
    let data: HomeGroupCardData
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    HomeBookCover(imageUrl: data.bookImage, width: 72, height: 100)

                    VStack(alignment: .leading, spacing: 0) {
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
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text("예상 독서 기간")
                                    .pretendardText(size: 14)
                                    .foregroundColor(Color("grey700"))
                                (
                                    Text("\(data.readingPeriod)").foregroundColor(Color("grey800"))
                                    + Text("일").foregroundColor(Color("grey700"))
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

                Text("자세히 보기")
                    .pretendardText(size: 15)
                    .foregroundColor(Color("main200"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color("main100")))
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color("white")))
            .shadow(color: Color.black.opacity(0.08), radius: 5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 책 썸네일 (캐러셀 / 그리드 공용)

private struct HomeBookThumbnail: View {
    let book: HomeSectionItem
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                KFImageCover(imageUrl: book.bookImage)
                VStack(alignment: .leading, spacing: 0) {
                    Text((book.title ?? "").stripBookSubtitle())
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey900"))
                        .lineLimit(1)
                    Text((book.author ?? "").removingAuthorRole())
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey500"))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

// 책 표지 — 가변 너비(부모 frame)에 120:168 비율.
private struct KFImageCover: View {
    let imageUrl: String?
    var body: some View {
        BookCover(imageUrl: imageUrl)
            .aspectRatio(120.0 / 168.0, contentMode: .fit)
    }
}

private struct HomeBookCarouselSection: View {
    let section: HomeSection
    var onBookTap: (HomeSectionItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HomeSectionHeader(title: section.title, subtitle: section.subtitle)
                .padding(.leading, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 8) {
                    ForEach(Array(section.items.enumerated()), id: \.offset) { _, book in
                        HomeBookThumbnail(book: book, onTap: { onBookTap(book) })
                            .frame(width: 120)
                    }
                }
                .padding(.leading, 16)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
    }
}

private struct HomeBookGridSection: View {
    let section: HomeSection
    var onBookTap: (HomeSectionItem) -> Void
    private let columns = 3

    private var rows: [[HomeSectionItem]] {
        stride(from: 0, to: section.items.count, by: columns).map {
            Array(section.items[$0..<min($0 + columns, section.items.count)])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HomeSectionHeader(title: section.title, subtitle: section.subtitle)
            VStack(spacing: 8) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, rowBooks in
                    HStack(alignment: .top, spacing: 8) {
                        ForEach(Array(rowBooks.enumerated()), id: \.offset) { _, book in
                            HomeBookThumbnail(book: book, onTap: { onBookTap(book) })
                                .frame(maxWidth: .infinity)
                        }
                        if rowBooks.count < columns {
                            ForEach(0..<(columns - rowBooks.count), id: \.self) { _ in
                                Color.clear.frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
    }
}

private extension String {
    /// 알라딘 author "한강 (지은이)" 형태에서 역할 표기 제거.
    func removingAuthorRole() -> String {
        replacingOccurrences(of: "(지은이)", with: "")
            .replacingOccurrences(of: #"\s*,\s*$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
}
