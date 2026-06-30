import SwiftUI

// 안드 homeMyGroupsContent / homeAppliedContent 대응.

// MARK: - 공통 레이아웃 (카운트 라벨 + 캡션 + 빈 상태 모달 / 카드 목록)

private struct HomeListTabLayout: View {
    let count: Int
    let caption: String
    let emptyMessage: String
    let emptyButtonTitle: String
    var onEmptyButtonTap: () -> Void
    let cards: [HomeGroupCardData]
    var onGroupTap: (Int) -> Void

    var body: some View {
        VStack(spacing: 8) {
            Color("grey100").frame(height: 8)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    (
                        Text("\(count)") + Text(" 권")
                    )
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey900"))
                    Text(caption)
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey500"))
                }

                if cards.isEmpty {
                    emptyModal
                } else {
                    ForEach(cards) { data in
                        HomeGroupCard(data: data, onTap: { onGroupTap(data.groupId) })
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Color.clear.frame(height: 80)
        }
    }

    private var emptyModal: some View {
        VStack(spacing: 20) {
            Text(emptyMessage)
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey900"))
                .multilineTextAlignment(.center)
            Button(action: onEmptyButtonTap) {
                Text(emptyButtonTitle)
                    .pretendardText(size: 15)
                    .foregroundColor(Color("white"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color("main200")))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color("white")))
    }
}

// MARK: - 내 그룹 탭

struct HomeMyGroupsContent: View {
    let myGroups: [GroupItemDto]
    var onGroupTap: (Int) -> Void
    var onCreateGroupTap: () -> Void

    var body: some View {
        HomeListTabLayout(
            count: myGroups.count,
            caption: "매칭을 기다리는 그룹만 보여요.",
            emptyMessage: "매칭을 기다리는 내 그룹이 없어요.\n새로운 교환독서를 시작해볼까요?",
            emptyButtonTitle: "그룹 만들기",
            onEmptyButtonTap: onCreateGroupTap,
            cards: myGroups.map { $0.homeCardData },
            onGroupTap: onGroupTap
        )
    }
}

// MARK: - 신청한 그룹 탭

struct HomeAppliedContent: View {
    let appliedGroups: [AppliedGroupItem]
    var onGroupTap: (Int) -> Void
    var onExploreGroupTap: () -> Void

    var body: some View {
        HomeListTabLayout(
            count: appliedGroups.count,
            caption: "매칭을 기다리는 그룹만 보여요.",
            emptyMessage: "매칭을 기다리는 신청 내역이 없어요.\n새로운 교환독서를 시작해볼까요?",
            emptyButtonTitle: "그룹 탐색하기",
            onEmptyButtonTap: onExploreGroupTap,
            cards: appliedGroups.map { $0.homeCardData },
            onGroupTap: onGroupTap
        )
    }
}
