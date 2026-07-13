import SwiftUI

/// 트래커 UI 전면 재작업 동안의 임시 플레이스홀더.
/// 트래커 메인 화면으로 교체되면 제거 예정.
struct TrackerPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image("ic_tracker_32")
                .renderingMode(.template)
                .foregroundColor(Color("grey400"))
            Text("트래커는 곧 작업 예정")
                .pretendardText(size: 15, weight: .medium)
                .foregroundColor(Color("grey600"))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("grey100"))
    }
}
