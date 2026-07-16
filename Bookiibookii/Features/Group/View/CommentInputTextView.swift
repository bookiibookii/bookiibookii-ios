import SwiftUI
import UIKit

// 댓글 입력 필드 — 안드 BasicTextField + VisualTransformation 대응.
// UITextView 래핑으로 iOS 18에서도 멘션 prefix 인라인 색상 구현.
struct CommentInputTextView: UIViewRepresentable {
    var text: String
    var mentionNickname: String?
    var focusTrigger: Int
    var onChange: (String) -> Void
    var onSubmit: () -> Void
    var onFocus: (() -> Void)?
    @Binding var contentHeight: CGFloat

    private let maxLines = 4

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.font = UIFont(name: "Pretendard Variable", size: 16) ?? .systemFont(ofSize: 16)
        tv.backgroundColor = .clear
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        tv.textContainer.lineFragmentPadding = 0
        tv.tintColor = UIColor(named: "main200")
        tv.isScrollEnabled = false
        tv.returnKeyType = .send
        context.coordinator.placeholderLabel.text = "텍스트 입력 전"
        context.coordinator.attach(to: tv)
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        context.coordinator.parent = self
        // 외부 text(답글 진입/submit 클리어)와 다르면 동기화 + 커서 끝
        if tv.text != text {
            context.coordinator.applyStyledText(tv, raw: text, keepSelectionAtEnd: true)
        } else {
            // 멘션 색상만 갱신(닉네임 변동 대비)
            context.coordinator.restyle(tv)
        }
        context.coordinator.updatePlaceholder(tv)
        context.coordinator.updateHeight(tv)

        // 답글 모드 진입 시 자동 focus (focusTrigger 변경 감지)
        if focusTrigger != context.coordinator.lastFocusTrigger {
            context.coordinator.lastFocusTrigger = focusTrigger
            if focusTrigger > 0 {
                DispatchQueue.main.async { tv.becomeFirstResponder() }
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: CommentInputTextView
        var lastFocusTrigger = 0
        let placeholderLabel = UILabel()

        init(_ parent: CommentInputTextView) { self.parent = parent }

        func attach(to tv: UITextView) {
            placeholderLabel.font = UIFont(name: "Pretendard Variable", size: 16) ?? .systemFont(ofSize: 16)
            placeholderLabel.textColor = UIColor(named: "grey500")
            placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
            tv.addSubview(placeholderLabel)
            NSLayoutConstraint.activate([
                placeholderLabel.leadingAnchor.constraint(equalTo: tv.leadingAnchor, constant: 8),
                placeholderLabel.topAnchor.constraint(equalTo: tv.topAnchor, constant: 12),
            ])
        }

        // return 키 → 개행 대신 submit
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n" {
                parent.onSubmit()
                return false
            }
            return true
        }

        // 입력창이 실제 포커스를 얻는 시점(탭 또는 becomeFirstResponder 성공)에 상위로 알림
        func textViewDidBeginEditing(_ tv: UITextView) {
            parent.onFocus?()
        }

        func textViewDidChange(_ tv: UITextView) {
            parent.onChange(tv.text)
            restyle(tv)
            updatePlaceholder(tv)
            updateHeight(tv)
        }

        // 멘션 prefix만 main200, 나머지 grey900으로 재스타일 (커서 위치 보존)
        func restyle(_ tv: UITextView) {
            let selected = tv.selectedRange
            tv.attributedText = styledAttributed(tv.text)
            tv.selectedRange = selected
            // 새 입력이 grey900이 되도록 typingAttributes 고정
            tv.typingAttributes = [
                .foregroundColor: UIColor(named: "grey900") ?? .label,
                .font: tv.font ?? .systemFont(ofSize: 16),
            ]
        }

        // 외부 주입 텍스트 반영(커서 끝)
        func applyStyledText(_ tv: UITextView, raw: String, keepSelectionAtEnd: Bool) {
            tv.attributedText = styledAttributed(raw)
            if keepSelectionAtEnd {
                tv.selectedRange = NSRange(location: (raw as NSString).length, length: 0)
            }
            tv.typingAttributes = [
                .foregroundColor: UIColor(named: "grey900") ?? .label,
                .font: tv.font ?? .systemFont(ofSize: 16),
            ]
        }

        private func styledAttributed(_ raw: String) -> NSAttributedString {
            let font = UIFont(name: "Pretendard Variable", size: 16) ?? .systemFont(ofSize: 16)
            let base = NSMutableAttributedString(
                string: raw,
                attributes: [.foregroundColor: UIColor(named: "grey900") ?? .label, .font: font]
            )
            if let nickname = parent.mentionNickname {
                let prefix = "@\(nickname) "
                if raw.hasPrefix(prefix) {
                    let nsRange = NSRange(location: 0, length: (prefix as NSString).length)
                    base.addAttribute(.foregroundColor, value: UIColor(named: "main200") ?? .systemBlue, range: nsRange)
                }
            }
            return base
        }

        func updatePlaceholder(_ tv: UITextView) {
            placeholderLabel.isHidden = !tv.text.isEmpty
        }

        // maxLines 4까지 자라고 초과 시 스크롤. contentHeight 바인딩 갱신.
        func updateHeight(_ tv: UITextView) {
            // 첫 레이아웃 패스(width=0)에서는 계산을 건너뛰어 높이 플리커 방지
            if tv.bounds.width == 0 { return }
            let lineHeight = (tv.font?.lineHeight ?? 20)
            let maxHeight = lineHeight * CGFloat(parent.maxLines) + tv.textContainerInset.top + tv.textContainerInset.bottom
            let fitting = tv.sizeThatFits(CGSize(width: tv.bounds.width, height: .greatestFiniteMagnitude)).height
            let clamped = min(fitting, maxHeight)
            tv.isScrollEnabled = fitting > maxHeight
            if abs(parent.contentHeight - clamped) > 0.5 {
                DispatchQueue.main.async { self.parent.contentHeight = clamped }
            }
        }
    }
}
