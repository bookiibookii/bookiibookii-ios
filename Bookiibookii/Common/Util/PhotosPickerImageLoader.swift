import Foundation
import PhotosUI
import SwiftUI
import UIKit

/// `PhotosPickerItem`에서 이미지를 읽을 때 `Data.self`만으로 실패하는 경우가 있어,
/// 카드 추가·온보딩 프로필 등 동일한 폴백 순서를 한곳에서 사용합니다.
///
/// `PhotosPickerItem`은 **PhotosUI**(및 SwiftUI의 피커 API) 쪽에 묶여 있으므로 두 프레임워크를 함께 import합니다.
/// 커스텀 `Transferable` 타입은 SDK마다 준수 검증이 깨질 수 있어 쓰지 않습니다.
enum PhotosPickerImageLoader {

    /// 표준 JPEG 바이트로 통일 (업로드용).
    static func jpegData(from item: PhotosPickerItem, compressionQuality: CGFloat = 0.92) async throws -> Data {
        if let data = try await item.loadTransferable(type: Data.self), !data.isEmpty {
            return normalizeToJPEG(data, quality: compressionQuality)
        }

        if let url = try await item.loadTransferable(type: URL.self) {
            let data = try Data(contentsOf: url)
            return normalizeToJPEG(data, quality: compressionQuality)
        }

        throw CocoaError(.fileReadCorruptFile)
    }

    /// 화면 표시용 `UIImage`.
    static func uiImage(from item: PhotosPickerItem, compressionQuality: CGFloat = 0.92) async throws -> UIImage {
        let data = try await jpegData(from: item, compressionQuality: compressionQuality)
        guard let image = UIImage(data: data) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return image
    }

    private static func normalizeToJPEG(_ data: Data, quality: CGFloat) -> Data {
        guard let ui = UIImage(data: data), let jpeg = ui.jpegData(compressionQuality: quality) else {
            return data
        }
        return jpeg
    }
}
