import Combine
import SwiftUI
import UIKit

@MainActor
final class PublicProfileViewerViewModel: ObservableObject {
    enum State {
        case loading
        case error
        case loaded(PublicProfileResponseDTO)
    }

    @Published private(set) var state: State = .loading
    @Published private(set) var isSaving = false
    @Published var toast: ToastMessage?

    private let shareToken: String
    private let isDark: Bool
    private let userService: UserService

    init(shareToken: String, isDark: Bool, userService: UserService) {
        self.shareToken = shareToken
        self.isDark = isDark
        self.userService = userService
    }

    func load() async {
        guard !shareToken.isEmpty else {
            state = .error
            return
        }
        state = .loading
        do {
            state = .loaded(try await userService.fetchPublicProfile(shareToken: shareToken))
        } catch {
            state = .error
        }
    }

    func saveImage() async {
        guard case let .loaded(profile) = state, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        let books = Array(profile.books.prefix(7))
        let profileImage = await SharePreviewImageRenderer.downloadImage(from: profile.profileImageUrl)
        var bookImages: [UIImage?] = []
        for book in books {
            bookImages.append(await SharePreviewImageRenderer.downloadImage(from: book.image))
        }

        let content = ProfileShareCardRenderContent(
            nickname: profile.nickname,
            introduction: profile.introduction ?? "",
            profileImage: profileImage,
            books: books,
            bookImages: bookImages,
            isDark: isDark
        )
        .frame(width: 360)
        .background(isDark ? Color("grey900") : Color("white"))

        guard let rendered = SharePreviewImageRenderer.render(content, width: 360, scale: 3) else {
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
