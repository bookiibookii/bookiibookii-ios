import SwiftUI
import UIKit

/// Instagram Stories 공유 시 사용할 수 있는 결과/에러.
enum InstagramStoriesShareError: LocalizedError {
    case notInstalled
    case renderFailed
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .notInstalled: return "인스타그램이 설치되어 있지 않아요."
        case .renderFailed: return "공유 이미지를 만들지 못했어요."
        case .invalidURL:   return "공유 링크가 올바르지 않습니다."
        }
    }
}

/// Instagram Stories에 스티커 이미지를 공유하는 헬퍼.
///
/// Meta 공식 가이드대로 `UIPasteboard`에 정해진 키로 이미지·배경 색을 올린 뒤
/// `instagram-stories://share` URL 스킴으로 스토리 작성기를 띄웁니다.
///
/// - 참고: https://developers.facebook.com/docs/instagram/sharing-to-stories/ios
@MainActor
enum InstagramStoriesShare {
    private static let urlScheme = "instagram-stories://share"
    /// 만료 시간 5분. Instagram 권장값.
    private static let pasteboardExpiration: TimeInterval = 60 * 5

    /// 스티커 공유. 사용자가 위치를 자유롭게 옮길 수 있는 형태입니다.
    static func share(
        stickerImage: UIImage,
        backgroundTopColor: UIColor = .white,
        backgroundBottomColor: UIColor = .white,
        sourceApplication: String? = sourceApplicationFromInfoPlist()
    ) async throws {
        guard let url = URL(string: urlString(sourceApplication: sourceApplication)) else {
            throw InstagramStoriesShareError.invalidURL
        }
        guard UIApplication.shared.canOpenURL(url) else {
            throw InstagramStoriesShareError.notInstalled
        }
        guard let pngData = stickerImage.pngData() else {
            throw InstagramStoriesShareError.renderFailed
        }

        let pasteboardItems: [String: Any] = [
            "com.instagram.sharedSticker.stickerImage": pngData,
            "com.instagram.sharedSticker.backgroundTopColor": backgroundTopColor.hexRGBString,
            "com.instagram.sharedSticker.backgroundBottomColor": backgroundBottomColor.hexRGBString
        ]
        let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
            .expirationDate: Date().addingTimeInterval(pasteboardExpiration)
        ]
        UIPasteboard.general.setItems([pasteboardItems], options: pasteboardOptions)

        await UIApplication.shared.open(url)
    }

    /// Info.plist 의 `FacebookAppID` (또는 `FBAppID`) 값을 읽어옵니다.
    /// 비어 있으면 nil 반환 → `source_application` 쿼리 파라미터를 생략합니다.
    /// 디폴트 인자 위치(비격리 컨텍스트)에서도 호출되므로 `nonisolated` 로 둡니다.
    nonisolated static func sourceApplicationFromInfoPlist() -> String? {
        let dict = Bundle.main.infoDictionary ?? [:]
        if let id = dict["FacebookAppID"] as? String, !id.isEmpty { return id }
        if let id = dict["FBAppID"] as? String, !id.isEmpty { return id }
        return nil
    }

    nonisolated private static func urlString(sourceApplication: String?) -> String {
        guard let source = sourceApplication, !source.isEmpty else { return urlScheme }
        return "\(urlScheme)?source_application=\(source)"
    }
}

private extension UIColor {
    /// `#RRGGBB` 형식으로 변환. Instagram 페이스트보드 키는 헥사 문자열을 요구합니다.
    var hexRGBString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let red = Int(round(r * 255))
        let green = Int(round(g * 255))
        let blue = Int(round(b * 255))
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
