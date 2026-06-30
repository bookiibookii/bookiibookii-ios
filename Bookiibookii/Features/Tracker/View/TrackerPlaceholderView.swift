import SwiftUI

/// 트래커 UI 전면 재작업 동안의 임시 플레이스홀더.
/// 안드로이드 신규 트래커 화면(TrackerListResDTO 기반)으로 재구성되면 교체됩니다.
struct TrackerPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image("ic_tracker_32")
                .renderingMode(.template)
                .foregroundColor(Color("grey400"))
            Text("트래커는 곧 새롭게 찾아옵니다")
                .pretendardText(size: 15, weight: .medium)
                .foregroundColor(Color("grey600"))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("grey100"))
    }
}
