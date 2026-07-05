import SwiftUI
import Combine

// 키보드 높이 관찰 — 안드 WindowInsets.ime 대응.
// SwiftUI 기본 키보드 회피를 끄고(.ignoresSafeArea(.keyboard)) 수동으로 시트 높이/입력필드 패딩 제어할 때 사용.
final class KeyboardObserver: ObservableObject {
    @Published var height: CGFloat = 0

    private var cancellables = Set<AnyCancellable>()

    init() {
        let willShow = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { note -> CGFloat? in
                (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height
            }

        let willHide = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        willShow.merge(with: willHide)
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.height, on: self)
            .store(in: &cancellables)
    }
}
