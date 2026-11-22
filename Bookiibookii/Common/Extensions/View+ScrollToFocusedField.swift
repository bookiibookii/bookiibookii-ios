import SwiftUI
import UIKit

extension View {
    /// 스크롤 안의 입력칸이 포커스되면 입력칸 전체가 키보드 위로 보이도록 스크롤한다.
    /// 입력칸에 `.id(...)`를 붙이고, 포커스된 입력칸의 id를 `focusedID`로 넘긴다.
    /// 포커스 직후에는 키보드 높이가 아직 반영되지 않았을 수 있어, 키보드가 다 올라온 뒤에도 한 번 더 맞춘다.
    func scrollToFocusedField<ID: Hashable>(_ focusedID: ID?, proxy: ScrollViewProxy) -> some View {
        modifier(ScrollToFocusedField(focusedID: focusedID, proxy: proxy))
    }
}

private struct ScrollToFocusedField<ID: Hashable>: ViewModifier {
    let focusedID: ID?
    let proxy: ScrollViewProxy

    func body(content: Content) -> some View {
        content
            .onChange(of: focusedID) { _, id in
                scroll(to: id)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                scroll(to: focusedID)
            }
    }

    private func scroll(to id: ID?) {
        guard let id else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            proxy.scrollTo(id, anchor: .bottom)
        }
    }
}
