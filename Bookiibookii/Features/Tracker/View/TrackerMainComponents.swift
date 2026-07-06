import SwiftUI

// 안드 tracker/ui/main/TrackerMainScreen.kt 대응 —
// TrackerNoticeBanner(L80–110) / TrackerCountBoard·CountColumn·CountDivider(L320–382) / TrackerEmptyCard(L410–438).

// MARK: - NoticeBanner

struct TrackerNoticeBanner: View {
    let nickname: String

    var body: some View {
        VStack(spacing: 0) {
            (
                Text(nickname)
                    .foregroundColor(Color("main200"))
                + Text("님의\n교환독서 현황을 알려드려요.")
                    .foregroundColor(Color("grey900"))
            )
            .pretendardText(size: 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)

            Rectangle()
                .fill(Color("grey100"))
                .frame(height: 1)
        }
        .frame(maxWidth: .infinity)
        .background(Color("white"))
    }
}

// MARK: - CountBoard

struct TrackerCountBoard: View {
    let total: Int
    let reading: Int
    let exchanging: Int
    let review: Int

    var body: some View {
        HStack(spacing: 0) {
            TrackerCountColumn(label: "전체", count: total)
                .frame(maxWidth: .infinity)
            TrackerCountDivider()
            TrackerCountColumn(label: "읽는 중", count: reading)
                .frame(maxWidth: .infinity)
            TrackerCountDivider()
            TrackerCountColumn(label: "교환 중", count: exchanging)
                .frame(maxWidth: .infinity)
            TrackerCountDivider()
            TrackerCountColumn(label: "후기", count: review)
                .frame(maxWidth: .infinity)
        }
        .padding(12)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct TrackerCountColumn: View {
    let label: String
    let count: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .pretendardText(size: 14)
                .foregroundColor(Color("grey700"))
            Text("\(count)")
                .pretendardText(size: 24)
                .foregroundColor(count == 0 ? Color("grey300") : Color("grey900"))
        }
    }
}

private struct TrackerCountDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color("grey100"))
            .frame(width: 1, height: 48)
    }
}

// MARK: - EmptyCard

struct TrackerEmptyCard: View {
    let onCreateGroupClick: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("참여 중인 그룹이 없어요 😭\n읽고 싶은 책으로 그룹을 만들어보세요")
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey900"))
                .multilineTextAlignment(.center)

            CardButton(
                text: "그룹 만들기",
                style: .main,
                corner: 20,
                action: onCreateGroupClick
            )
            .frame(maxWidth: .infinity)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// MARK: - Previews

#Preview("NoticeBanner") {
    TrackerNoticeBanner(nickname: "sayo")
}

#Preview("CountBoard - Empty") {
    TrackerCountBoard(total: 0, reading: 0, exchanging: 0, review: 0)
        .padding(16)
        .background(Color("uiBg"))
}

#Preview("CountBoard - Filled") {
    TrackerCountBoard(total: 3, reading: 2, exchanging: 1, review: 0)
        .padding(16)
        .background(Color("uiBg"))
}

#Preview("EmptyCard") {
    TrackerEmptyCard(onCreateGroupClick: {})
        .padding(16)
        .background(Color("uiBg"))
}
