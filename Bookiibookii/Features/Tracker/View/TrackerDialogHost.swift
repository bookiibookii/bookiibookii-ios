import SwiftUI

// 다이얼로그 오버레이 호스트. PR-A는 EmptyView(무반응). PR-B/C가 각 case에 다이얼로그 카드 + 스크림을 채운다.
// 그룹 GroupDetailView 패턴(Color.black.opacity(0.45) 스크림 + 중앙 카드) 사용 예정.
struct TrackerDialogHost: ViewModifier {
    @ObservedObject var coordinator: TrackerDialogCoordinator

    func body(content: Content) -> some View {
        content.overlay {
            switch coordinator.route {
            case nil:
                EmptyView()
            default:
                // PR-B/C에서 case별 다이얼로그 렌더. 현재는 무반응.
                EmptyView()
            }
        }
    }
}

extension View {
    func trackerDialogHost(_ coordinator: TrackerDialogCoordinator) -> some View {
        modifier(TrackerDialogHost(coordinator: coordinator))
    }
}
