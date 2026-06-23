import SwiftUI

// 피그마 node 3544-74773 대응.
// 탭에 따라 문구만 스왑됨. 버튼 탭 시 그룹 탭으로 이동.
struct TrackerEmptyCard: View {
    let tab: TrackerTab
    let onNavigateToGroup: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(tab.emptyTitle)
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey900"))
                    .multilineTextAlignment(.center)

                Text(tab.emptyDescription)
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey600"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            Button(action: onNavigateToGroup) {
                Text("그룹 둘러보기")
                    .pretendardText(size: 15)
                    .foregroundColor(Color("grey100"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color("grey900"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

#Preview("내 그룹") {
    TrackerEmptyCard(tab: .myGroup, onNavigateToGroup: {})
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("grey100"))
}

#Preview("참여한 그룹") {
    TrackerEmptyCard(tab: .joined, onNavigateToGroup: {})
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("grey100"))
}
