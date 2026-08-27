import Kingfisher
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
        let content = view
            .frame(width: width)
            .fixedSize(horizontal: false, vertical: true)
        let renderer = ImageRenderer(content: content)
        renderer.scale = scale
        renderer.proposedSize = ProposedViewSize(width: width, height: nil)
        return renderer.uiImage
    }

    static func downloadImage(from urlString: String?) async -> UIImage? {
        guard let urlString, let url = URL(string: urlString) else { return nil }
        return await withCheckedContinuation { continuation in
            KingfisherManager.shared.retrieveImage(with: url) { result in
                switch result {
                case .success(let value):
                    continuation.resume(returning: value.image)
                case .failure:
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    /// 안드로이드 `compositeCardOnWhiteBackground`와 동일: 1080×1920 흰 캔버스 중앙에 카드를 올린다.
    static func compositeOnWhiteStoryCanvas(_ card: UIImage) -> UIImage {
        let canvasSize = CGSize(width: 1080, height: 1920)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let cardPixelSize = CGSize(
            width: card.size.width * card.scale,
            height: card.size.height * card.scale
        )
        let maxWidth = canvasSize.width * 0.85
        let maxHeight = canvasSize.height * 0.75
        let fit = min(maxWidth / cardPixelSize.width, maxHeight / cardPixelSize.height, 1)
        let drawSize = CGSize(width: cardPixelSize.width * fit, height: cardPixelSize.height * fit)
        let origin = CGPoint(
            x: (canvasSize.width - drawSize.width) / 2,
            y: (canvasSize.height - drawSize.height) / 2
        )

        return UIGraphicsImageRenderer(size: canvasSize, format: format).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: canvasSize))
            card.draw(in: CGRect(origin: origin, size: drawSize))
        }
    }
}
