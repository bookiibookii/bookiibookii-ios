import SwiftUI

// 안드로이드 ui/component/ClickDebounce.kt 대응 클릭 디바운스.

// 공통 버튼용 클릭 디바운스 기본 간격(초)
private let defaultClickInterval: TimeInterval = 0.5

/// 같은 버튼을 `interval` 안에 다시 눌러도 무시하는 Button 래퍼.
///
/// 더블탭으로 인한 중복 API 호출/중복 화면 전환을 버튼 레벨에서 막는 기본 안전망이다.
/// @State가 뷰 identity 단위(=버튼 인스턴스)라 타이머가 버튼마다 독립적이므로,
/// 서로 다른 버튼을 빠르게 연달아 누르는 동작에는 영향이 없다.
struct DebouncedButton<Label: View>: View {
    var interval: TimeInterval = defaultClickInterval
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var lastTapAt: Date?

    var body: some View {
        Button {
            let now = Date()
            if let lastTapAt, now.timeIntervalSince(lastTapAt) < interval { return }
            lastTapAt = now
            action()
        } label: {
            label()
        }
    }
}
