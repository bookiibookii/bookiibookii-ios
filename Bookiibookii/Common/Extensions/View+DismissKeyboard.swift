import SwiftUI
import UIKit

// 빈 영역 탭 시 키보드를 내린다. iOS는 안드와 달리 시스템 기본 "키보드 내리기"가 없어 앱이 직접 구현해야 함.
// - 윈도우에 UITapGestureRecognizer를 달아 화면 어디를 탭해도 반응(cancelsTouchesInView=false → 버튼/제스처는 안 막음).
// - 텍스트 입력(UITextField/UITextView)·컨트롤 위 탭은 델리게이트에서 무시 → 필드 탭 편집/버튼 동작 방해 안 함.
extension View {
    func dismissKeyboardOnTap() -> some View {
        background(KeyboardDismissTapper())
    }

    // 이 뷰(및 하위) 위 탭은 키보드를 내리지 않음. dismissKeyboardOnTap과 함께 쓰는 예외 지정
    // (예: 댓글 입력바 — 칩/여백 탭 시 키보드가 내려가면 안 됨).
    func keyboardDismissExcluded() -> some View {
        background(KeyboardDismissExcludeMarker())
    }
}

// 키보드 dismiss 제외 영역 레지스트리 — 마커가 등록한 컨테이너(및 하위) 위 탭은 dismiss 안 함.
final class KeyboardDismissExcludeRegistry {
    static let shared = KeyboardDismissExcludeRegistry()
    private let views = NSHashTable<UIView>.weakObjects()

    func register(_ view: UIView) { views.add(view) }

    // touch된 뷰의 조상 중 등록된 뷰가 있으면 제외 대상
    func contains(_ view: UIView?) -> Bool {
        var current = view
        while let v = current {
            if views.contains(v) { return true }
            current = v.superview
        }
        return false
    }
}

// 제외 마커 — .background로 삽입되어 자신의 superview(입력바 콘텐츠와 공유하는 컨테이너)를 제외 등록.
private struct KeyboardDismissExcludeMarker: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let container = uiView.superview {
                KeyboardDismissExcludeRegistry.shared.register(container)
            }
        }
    }
}

private struct KeyboardDismissTapper: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        // 자신은 터치를 받지 않는 투명 뷰(제스처는 윈도우에 붙임).
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard context.coordinator.tap == nil else { return }
        if let window = uiView.window {
            install(on: window, context.coordinator)
        } else {
            // 최초 레이아웃 시 아직 윈도우에 안 붙었을 수 있어 한 틱 뒤 재시도.
            DispatchQueue.main.async {
                if context.coordinator.tap == nil, let window = uiView.window {
                    install(on: window, context.coordinator)
                }
            }
        }
    }

    private func install(on window: UIWindow, _ coordinator: Coordinator) {
        let tap = UITapGestureRecognizer(target: coordinator, action: #selector(Coordinator.handleTap))
        tap.cancelsTouchesInView = false
        tap.delegate = coordinator
        window.addGestureRecognizer(tap)
        coordinator.tap = tap
        coordinator.window = window
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        if let tap = coordinator.tap {
            coordinator.window?.removeGestureRecognizer(tap)
        }
        coordinator.tap = nil
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var tap: UITapGestureRecognizer?
        weak var window: UIWindow?

        @objc func handleTap() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        // 텍스트 입력/컨트롤 위 탭, 그리고 명시적 제외 영역(입력바 등) 위 탭은 무시 → 필드 편집·버튼 탭 정상 동작.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            if KeyboardDismissExcludeRegistry.shared.contains(touch.view) { return false }
            var view = touch.view
            while let current = view {
                if current is UIControl || current is UITextField || current is UITextView {
                    return false
                }
                view = current.superview
            }
            return true
        }
    }
}
