import UIKit

/// S3 업로드용 이미지 압축 유틸 (안드로이드 `S3Uploader` 압축 로직 대응).
///
/// 처리 순서: 긴 변 1600px로 리사이즈(비율 유지) → EXIF 방향 정규화 →
/// JPEG 품질 0.8에서 시작해 1MB를 넘으면 0.1씩 낮춰 최소 0.1까지 반복.
/// 프로필·독서카드·배송 인증사진 등 모든 업로드 지점에서 공통 사용한다.
enum ImageCompressor {

    // 안드로이드 S3Uploader 상수 대응
    static let maxLongSidePx: CGFloat = 1600
    static let initialQuality: CGFloat = 0.8
    static let minQuality: CGFloat = 0.1
    static let qualityStep: CGFloat = 0.1
    static let maxBytes = 1_048_576   // 1MB

    /// `UIImage`를 리사이즈·압축해 업로드용 JPEG 바이트로 변환한다.
    static func compressedJPEG(from image: UIImage) -> Data? {
        let resized = resizedToFit(image, maxLongSide: maxLongSidePx)

        var quality = initialQuality
        guard var data = resized.jpegData(compressionQuality: quality) else { return nil }
        while data.count > maxBytes && quality > minQuality {
            quality -= qualityStep
            guard let next = resized.jpegData(compressionQuality: quality) else { break }
            data = next
        }
        return data
    }

    /// 이미 디코딩된 이미지 데이터(앨범 JPEG 등)를 동일 기준으로 재압축한다.
    static func compressedJPEG(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        return compressedJPEG(from: image)
    }

    /// 긴 변이 `maxLongSide`(px)를 넘으면 비율을 유지해 축소한다.
    /// `draw(in:)` 렌더링 과정에서 EXIF 방향이 정규화된다.
    private static func resizedToFit(_ image: UIImage, maxLongSide: CGFloat) -> UIImage {
        let longSide = max(image.size.width, image.size.height)
        let targetSize: CGSize
        if longSide > maxLongSide {
            let ratio = maxLongSide / longSide
            targetSize = CGSize(
                width: max(1, image.size.width * ratio),
                height: max(1, image.size.height * ratio)
            )
        } else {
            targetSize = image.size
        }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1   // 포인트=픽셀 (안드로이드 픽셀 기준과 일치)
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
