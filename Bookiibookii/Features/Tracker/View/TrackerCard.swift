import SwiftUI
import Kingfisher

// 안드로이드 item_trk.xml (delivery/direct) / item_tracker_none.xml (together) 대응.
// 215pt 카드, 상단 공통(커버+제목+저자/카테고리+with) + 디바이더 + 하단 진행도 영역(타입별 분기)
struct TrackerCard: View {
    let item: TrackerItem
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            topSection
            Spacer(minLength: 0)
            divider
            progressArea
        }
        .frame(height: 215)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    // MARK: - 상단 (커버 + 정보)

    private var topSection: some View {
        HStack(alignment: .top, spacing: 12) {
            cover
            info
            Spacer(minLength: 0)
        }
        .padding(.leading, 16)
        .padding(.trailing, 24)
        .padding(.top, 16)
    }

    private var cover: some View {
        KFImage(item.coverImageUrl.flatMap(URL.init(string:)))
            .placeholder { Color("grey200") }
            .retry(maxCount: 2)
            .cancelOnDisappear(true)
            .resizable()
            .scaledToFill()
            .frame(width: 60, height: 85)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(item.bookTitle)
                .font(.pretendard(size: 16, weight: .medium))
                .foregroundColor(Color("grey800"))
                .lineLimit(1)
                .truncationMode(.tail)

            authorLine
                .padding(.top, 4)

            withLine
                .padding(.top, 12)
        }
    }

    private var authorLine: some View {
        HStack(spacing: 4) {
            Text(item.bookAuthor)
                .font(.pretendard(size: 12))
                .foregroundColor(Color("grey600"))
                .lineLimit(1)
            let category = TrackerCategoryMapper.displayKo(item.bookCategory)
            if !category.isEmpty {
                Text(category)
                    .font(.pretendard(size: 12))
                    .foregroundColor(Color("grey600"))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }

    @ViewBuilder
    private var withLine: some View {
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

    // MARK: - 디바이더

    private var divider: some View {
        Rectangle()
            .fill(Color("grey100"))
            .frame(height: 1)
            .padding(.horizontal, 16)
    }

    // MARK: - 하단 진행도 영역 (타입별 분기)

    @ViewBuilder
    private var progressArea: some View {
        switch item.exchangeType {
        case .delivery, .direct:
            TrackerRelayProgressBar(
                role: item.role,
                currentStep: item.currentStepIndex,
                stepDates: item.stepDates,
                hostProfileUrl: item.hostProfileImageUrl,
                guestProfileUrl: item.guestProfileImageUrl
            )
            .padding(.top, 12)
            .padding(.bottom, 14)
        case .none:
            TrackerReadingRateBar(
                myReadingRate: item.myReadingRate ?? 0,
                groupReadingRate: item.groupReadingRate ?? 0
            )
            .padding(.bottom, 14)
        }
    }
}

#Preview("릴레이 Host - 배송 중") {
    TrackerCard(
        item: TrackerItem(
            id: 1, groupId: 1,
            role: .host, exchangeType: .delivery,
            bookTitle: "참을 수 없는 존재의 가벼움",
            bookAuthor: "밀란 쿤데라", bookCategory: "NOVEL_GENRE",
            coverImageUrl: nil, withUserName: "noshel",
            stepDates: ["2024-12-16", "2024-12-20", nil, nil],
            currentStepIndex: 1,
            hostProfileImageUrl: nil,
            guestProfileImageUrl: nil,
            myReadingRate: nil, groupReadingRate: nil
        ),
        onTap: {}
    )
    .padding()
    .background(Color("grey100"))
}

#Preview("릴레이 Guest - 게스트 읽는 중") {
    TrackerCard(
        item: TrackerItem(
            id: 2, groupId: 2,
            role: .guest, exchangeType: .delivery,
            bookTitle: "살인자의 기억법",
            bookAuthor: "김영하", bookCategory: "NOVEL_GENRE",
            coverImageUrl: nil, withUserName: "noshel",
            stepDates: ["2024-12-16", "2024-12-20", "2024-12-23", nil],
            currentStepIndex: 2,
            hostProfileImageUrl: nil,
            guestProfileImageUrl: nil,
            myReadingRate: nil, groupReadingRate: nil
        ),
        onTap: {}
    )
    .padding()
    .background(Color("grey100"))
}

#Preview("함께읽기") {
    TrackerCard(
        item: TrackerItem(
            id: 3, groupId: 3,
            role: .host, exchangeType: ExchangeType.none,
            bookTitle: "데미안",
            bookAuthor: "헤르만 헤세", bookCategory: "NOVEL_GENRE",
            coverImageUrl: nil, withUserName: "noshel  +29",
            stepDates: [], currentStepIndex: 0,
            hostProfileImageUrl: nil, guestProfileImageUrl: nil,
            myReadingRate: 79, groupReadingRate: 53
        ),
        onTap: {}
    )
    .padding()
    .background(Color("grey100"))
}
