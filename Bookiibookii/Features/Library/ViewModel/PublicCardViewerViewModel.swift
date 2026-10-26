import Combine
import SwiftUI
import UIKit

@MainActor
final class PublicCardViewerViewModel: ObservableObject {
    enum State {
        case loading
        case error
        case loaded(detail: LibraryCardDetail, style: LibraryCardShareStyle, image: UIImage?)
    }

    @Published private(set) var state: State = .loading
    @Published private(set) var isSaving = false
    @Published var toast: ToastMessage?

    private let shareToken: String
    private let libraryService: LibraryService

    init(shareToken: String, libraryService: LibraryService) {
        self.shareToken = shareToken
        self.libraryService = libraryService
    }

    func load() async {
        state = .loading
        do {
            let dto = try await libraryService.fetchPublicReadingCard(shareToken: shareToken)
            let detail = dto.toLibraryCardDetail()
            let style: LibraryCardShareStyle = dto.shareLayout?.uppercased() == "SPLIT" ? .divide : .card

            // 저장 이미지도 같은 카드를 렌더링하므로 이미지 카드는 미리 받아 둔다.
            var image: UIImage?
            if detail.cardType == .image {
                image = await SharePreviewImageRenderer.downloadImage(from: detail.imageURL)
                guard image != nil else {
                    state = .error
                    return
                }
            }
            state = .loaded(detail: detail, style: style, image: image)
        } catch {
            state = .error
        }
    }

    func saveImage() async {
        guard case let .loaded(detail, style, image) = state, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        let preview = LibraryCardSharePreview(detail: detail, style: style, loadedImage: image)
            .background(Color.white)
        guard let rendered = SharePreviewImageRenderer.render(preview, width: 360, scale: 3) else {
            toast = .failure("저장 중 오류가 발생했어요")
            return
        }

        do {
            try await CardSharePhotoSaver.save(rendered)
            toast = .success("사진을 저장했어요")
        } catch {
            toast = .failure((error as? LocalizedError)?.errorDescription ?? "사진 저장에 실패했어요")
        }
    }
}
