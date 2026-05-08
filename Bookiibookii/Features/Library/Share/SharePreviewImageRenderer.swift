import SwiftUI
import UIKit

/// SwiftUI `View`를 고정 너비로 렌더링해 `UIImage`로 만드는 헬퍼.
///
/// 카드 공유 미리보기처럼 콘텐츠 높이가 가변인 뷰를 인스타 스토리 등 외부 공유에
/// 적절한 크기의 PNG 이미지로 만들기 위해 사용합니다.
@MainActor
enum SharePreviewImageRenderer {
    /// 지정된 너비로 SwiftUI 뷰를 렌더링합니다. 높이는 콘텐츠가 결정합니다.
    /// - Parameters:
    ///   - view: 렌더링할 SwiftUI 뷰
    ///   - width: 점(pt) 기준 너비. 기본 800pt → 3배 스케일이면 약 2400px.
    ///   - scale: 픽셀 스케일. 인스타 스토리 스티커는 3x 정도면 충분히 선명합니다.
    static func render<V: View>(_ view: V, width: CGFloat = 800, scale: CGFloat = 3) -> UIImage? {
        let renderer = ImageRenderer(content: view.frame(width: width))
        renderer.scale = scale
        return renderer.uiImage
    }
}
