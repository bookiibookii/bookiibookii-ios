import SwiftUI
import Kingfisher
import Photos
import UIKit

/// 마이페이지 프로필 공유 다이얼로그.
/// 라이트/다크 토글에 따라 카드 미리보기 테마가 바뀌고,
/// 하단에서 인스타·X·다운로드·링크 복사를 제공합니다.
struct ProfileShareSheet: View {
    let nickname: String
    let introduction: String
    let profileImageURL: String?
    let books: [MypageUserBook]
    let userService: UserService
    let onClose: () -> Void

    @State private var isDark = false
    @State private var alertMessage: String?
    @State private var isSharing = false

    private var sheetBackground: Color {
        isDark ? Color("grey900") : Color("white")
    }

    private var titleColor: Color {
        isDark ? Color("white") : Color("grey900")
    }

    private var actionLabelColor: Color {
        isDark ? Color("white") : Color("grey900")
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        header
                            .padding(.horizontal, 24)
                            .padding(.top, 24)

                        ProfileShareCardContent(
                            nickname: nickname,
                            introduction: introduction,
                            profileImageURL: profileImageURL,
                            books: books,
                            isDark: isDark
                        )
                        .padding(.top, 20)
                    }
                }

                shareActions
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
            .background(sheetBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 20)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.85)
        }
        .alert("안내", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("확인", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("프로필 공유")
                .pretendardText(size: 20, weight: .semibold)
                .foregroundColor(titleColor)

            ProfileShareDayNightToggle(isDark: $isDark)

            Spacer(minLength: 0)

            Button(action: onClose) {
                Image("ic_x")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .frame(width: 32, height: 32)
                    .background(Color("grey100"))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var shareActions: some View {
        HStack(spacing: 0) {
            shareActionButton(asset: "ic_insta", label: "인스타그램", circularBackground: false) {
                Task { await shareToInstagram() }
            }
            shareActionButton(asset: "img_share_x", label: "X", circularBackground: false) {
                Task { await shareToX() }
            }
            shareActionButton(asset: "ic_download", label: "다운로드", circularBackground: true) {
                Task { await downloadCard() }
            }
            shareActionButton(asset: "ic_link", label: "링크 복사", circularBackground: true) {
                Task { await copyShareLink() }
            }
        }
        .disabled(isSharing)
        .opacity(isSharing ? 0.6 : 1)
    }

    private func shareActionButton(
        asset: String,
        label: String,
        circularBackground: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Group {
                    if circularBackground {
                        Image(asset)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color("grey900"))
                            .frame(width: 24, height: 24)
                            .frame(width: 56, height: 56)
                            .background(Color("grey100"))
                            .clipShape(Circle())
                    } else {
                        Image(asset)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                    }
                }

                Text(label)
                    .pretendardText(size: 14, weight: .regular)
                    .foregroundColor(actionLabelColor)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func shareToInstagram() async {
        isSharing = true
        defer { isSharing = false }

        guard let image = await renderShareCardImage() else {
            alertMessage = "공유 이미지를 만들지 못했어요."
            return
        }

        do {
            try await InstagramStoriesShare.share(
                stickerImage: image,
                backgroundTopColor: .white,
                backgroundBottomColor: .white
            )
            onClose()
        } catch let error as InstagramStoriesShareError {
            alertMessage = error.errorDescription
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func shareToX() async {
        isSharing = true
        defer { isSharing = false }

        do {
            let url = try await fetchShareURL()
            let text = "\(nickname)님의 부키부키 프로필"
            var components = URLComponents(string: "https://twitter.com/intent/tweet")
            components?.queryItems = [
                URLQueryItem(name: "text", value: text),
                URLQueryItem(name: "url", value: url)
            ]
            guard let intentURL = components?.url else {
                alertMessage = "X를 열 수 없어요."
                return
            }
            await UIApplication.shared.open(intentURL)
            onClose()
        } catch {
            alertMessage = (error as? LocalizedError)?.errorDescription ?? "링크 생성에 실패했어요."
        }
    }

    private func downloadCard() async {
        isSharing = true
        defer { isSharing = false }

        guard let image = await renderShareCardImage() else {
            alertMessage = "저장 중 오류가 발생했어요."
            return
        }

        do {
            try await ProfileSharePhotoSaver.save(image)
            alertMessage = "사진을 저장했어요."
        } catch {
            alertMessage = (error as? LocalizedError)?.errorDescription ?? "사진 저장에 실패했어요."
        }
    }

    private func copyShareLink() async {
        isSharing = true
        defer { isSharing = false }

        do {
            let url = try await fetchShareURL()
            UIPasteboard.general.string = url
            alertMessage = "링크를 복사했어요."
        } catch {
            alertMessage = (error as? LocalizedError)?.errorDescription ?? "링크 생성에 실패했어요."
        }
    }

    private func fetchShareURL() async throws -> String {
        let result = try await userService.createProfileShareToken()
        if isDark {
            return result.shareUrl.contains("?")
                ? "\(result.shareUrl)&dark=1"
                : "\(result.shareUrl)?dark=1"
        }
        return result.shareUrl
    }

    private func renderShareCardImage() async -> UIImage? {
        let profileImage = await downloadImage(from: profileImageURL)
        var bookImages: [UIImage?] = []
        for book in books.prefix(7) {
            bookImages.append(await downloadImage(from: book.image))
        }

        let content = ProfileShareCardRenderContent(
            nickname: nickname,
            introduction: introduction,
            profileImage: profileImage,
            books: Array(books.prefix(7)),
            bookImages: bookImages,
            isDark: isDark
        )
        .frame(width: 360)
        .background(isDark ? Color("grey900") : Color("white"))

        return SharePreviewImageRenderer.render(content, width: 360, scale: 3)
    }

    private func downloadImage(from urlString: String?) async -> UIImage? {
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
}

// MARK: - Day / Night Toggle

private struct ProfileShareDayNightToggle: View {
    @Binding var isDark: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isDark.toggle()
            }
        } label: {
            HStack(spacing: 0) {
                if isDark {
                    Image("ic_dark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Spacer(minLength: 0)
                    Circle()
                        .fill(Color("white"))
                        .frame(width: 24, height: 24)
                } else {
                    Circle()
                        .fill(Color("white"))
                        .frame(width: 24, height: 24)
                    Spacer(minLength: 0)
                    Image("ic_light")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                }
            }
            .padding(4)
            .frame(width: 52, height: 32)
            .background(isDark ? Color("grey800") : Color("grey300"))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isDark ? "라이트 모드로 전환" : "다크 모드로 전환")
    }
}

// MARK: - Card Content (live preview)

struct ProfileShareCardContent: View {
    let nickname: String
    let introduction: String
    let profileImageURL: String?
    let books: [MypageUserBook]
    let isDark: Bool

    private var cardBg: Color { isDark ? Color("grey900") : Color("white") }
    private var textColor: Color { isDark ? Color("white") : Color("grey900") }
    private var mottoBg: Color { isDark ? Color("grey800") : Color("uiBg") }
    private var mottoBorder: Color { isDark ? Color("grey700") : Color("grey200") }
    private var mottoText: Color { isDark ? Color("white") : Color("grey600") }
    private var separatorBg: Color {
        isDark ? Color("grey800").opacity(0.3) : Color("grey100")
    }

    private var displayBooks: [MypageUserBook] { Array(books.prefix(7)) }

    private var rowCounts: (Int, Int) {
        let count = displayBooks.count
        switch count {
        case 0...4: return (count, 0)
        case 5: return (2, 3)
        case 6: return (3, 3)
        default: return (3, min(count - 3, 4))
        }
    }

    var body: some View {
        let (row1, row2) = rowCounts
        let maxRow = max(row1, row2, 4)

        VStack(spacing: 0) {
            Image("ic_bookii_text")
                .resizable()
                .scaledToFit()
                .frame(width: 113, height: 12)
                .padding(.horizontal, 24)

            VStack(spacing: 8) {
                profileImage
                    .frame(width: 92, height: 92)
                    .clipShape(Circle())

                Text(nickname.isEmpty ? "-" : nickname)
                    .pretendardText(size: 20, weight: .semibold)
                    .foregroundColor(textColor)
            }
            .padding(.top, 16)
            .padding(.horizontal, 24)

            VStack(spacing: 4) {
                Image("ic_quote")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)

                Text(introduction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                     ? "한 줄 소개를 입력해주세요"
                     : introduction)
                    .pretendardText(size: 15, weight: .medium)
                    .foregroundColor(mottoText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, 8)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity)
            .background(mottoBg)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(mottoBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.top, 16)
            .padding(.horizontal, 24)

            Image("ic_repressentative_book")
                .resizable()
                .scaledToFit()
                .frame(width: 167, height: 24)
                .padding(.top, 12)

            separatorBg.frame(height: 10)

            if row1 > 0 {
                bookCoverRow(
                    books: Array(displayBooks.prefix(row1)),
                    maxRowCount: maxRow
                )
            }

            if row2 > 0 {
                separatorBg.frame(height: 10)
                bookCoverRow(
                    books: Array(displayBooks.dropFirst(row1).prefix(row2)),
                    maxRowCount: maxRow
                )
            }

            separatorBg.frame(height: 10)
        }
        .frame(maxWidth: .infinity)
        .background(cardBg)
    }

    private var profileImage: some View {
        Group {
            if let urlStr = profileImageURL, let url = URL(string: urlStr) {
                KFImage(url)
                    .placeholder { placeholderProfile }
                    .resizable()
                    .scaledToFill()
            } else {
                placeholderProfile
            }
        }
    }

    private var placeholderProfile: some View {
        Image("ic_profile_placeholder")
            .resizable()
            .scaledToFill()
    }

    private func bookCoverRow(books: [MypageUserBook], maxRowCount: Int) -> some View {
        GeometryReader { proxy in
            let gap: CGFloat = 4
            let columns = CGFloat(max(maxRowCount, 1))
            let bookWidth = (proxy.size.width - gap * (columns - 1)) / columns
            let bookHeight = bookWidth * (104.0 / 72.0)

            HStack(spacing: gap) {
                ForEach(Array(books.enumerated()), id: \.offset) { _, book in
                    bookCover(imageURL: book.image)
                        .frame(width: bookWidth, height: bookHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .aspectRatio(CGFloat(max(maxRowCount, 1)) * 72.0 / 104.0, contentMode: .fit)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .background(cardBg)
    }

    private func bookCover(imageURL: String?) -> some View {
        Group {
            if let imageURL, let url = URL(string: imageURL) {
                KFImage(url)
                    .placeholder { Color("grey200") }
                    .resizable()
                    .scaledToFill()
            } else {
                Color("grey200")
            }
        }
    }
}

// MARK: - Card Content (renderable with preloaded UIImages)

private struct ProfileShareCardRenderContent: View {
    let nickname: String
    let introduction: String
    let profileImage: UIImage?
    let books: [MypageUserBook]
    let bookImages: [UIImage?]
    let isDark: Bool

    private var cardBg: Color { isDark ? Color("grey900") : Color("white") }
    private var textColor: Color { isDark ? Color("white") : Color("grey900") }
    private var mottoBg: Color { isDark ? Color("grey800") : Color("uiBg") }
    private var mottoBorder: Color { isDark ? Color("grey700") : Color("grey200") }
    private var mottoText: Color { isDark ? Color("white") : Color("grey600") }
    private var separatorBg: Color {
        isDark ? Color("grey800").opacity(0.3) : Color("grey100")
    }

    private var rowCounts: (Int, Int) {
        let count = books.count
        switch count {
        case 0...4: return (count, 0)
        case 5: return (2, 3)
        case 6: return (3, 3)
        default: return (3, min(count - 3, 4))
        }
    }

    var body: some View {
        let (row1, row2) = rowCounts
        let maxRow = max(row1, row2, 4)

        VStack(spacing: 0) {
            Image("ic_bookii_text")
                .resizable()
                .scaledToFit()
                .frame(width: 113, height: 12)
                .padding(.horizontal, 24)

            VStack(spacing: 8) {
                Group {
                    if let profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image("ic_profile_placeholder")
                            .resizable()
                            .scaledToFill()
                    }
                }
                .frame(width: 92, height: 92)
                .clipShape(Circle())

                Text(nickname.isEmpty ? "-" : nickname)
                    .pretendardText(size: 20, weight: .semibold)
                    .foregroundColor(textColor)
            }
            .padding(.top, 16)
            .padding(.horizontal, 24)

            VStack(spacing: 4) {
                Image("ic_quote")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)

                Text(introduction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                     ? "한 줄 소개를 입력해주세요"
                     : introduction)
                    .pretendardText(size: 15, weight: .medium)
                    .foregroundColor(mottoText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, 8)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity)
            .background(mottoBg)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(mottoBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.top, 16)
            .padding(.horizontal, 24)

            Image("ic_repressentative_book")
                .resizable()
                .scaledToFit()
                .frame(width: 167, height: 24)
                .padding(.top, 12)

            separatorBg.frame(height: 10)

            if row1 > 0 {
                renderBookRow(
                    images: Array(bookImages.prefix(row1)),
                    maxRowCount: maxRow
                )
            }

            if row2 > 0 {
                separatorBg.frame(height: 10)
                renderBookRow(
                    images: Array(bookImages.dropFirst(row1).prefix(row2)),
                    maxRowCount: maxRow
                )
            }

            separatorBg.frame(height: 10)
        }
        .frame(maxWidth: .infinity)
        .background(cardBg)
    }

    private func renderBookRow(images: [UIImage?], maxRowCount: Int) -> some View {
        GeometryReader { proxy in
            let gap: CGFloat = 4
            let columns = CGFloat(max(maxRowCount, 1))
            let bookWidth = (proxy.size.width - gap * (columns - 1)) / columns
            let bookHeight = bookWidth * (104.0 / 72.0)

            HStack(spacing: gap) {
                ForEach(Array(images.enumerated()), id: \.offset) { _, image in
                    Group {
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Color("grey200")
                        }
                    }
                    .frame(width: bookWidth, height: bookHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .aspectRatio(CGFloat(max(maxRowCount, 1)) * 72.0 / 104.0, contentMode: .fit)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .background(cardBg)
    }
}

// MARK: - Photo Saver

private enum ProfileSharePhotoSaver {
    enum SaveError: LocalizedError {
        case denied
        case failed

        var errorDescription: String? {
            switch self {
            case .denied: return "사진 보관함 접근 권한이 필요해요."
            case .failed: return "사진 저장에 실패했어요."
            }
        }
    }

    static func save(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw SaveError.denied
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? SaveError.failed)
                }
            }
        }
    }
}

#Preview {
    ProfileShareSheet(
        nickname: "김스카이",
        introduction: "역시나 누군가를 사랑하고\n사랑해야 할 당신을 위해",
        profileImageURL: nil,
        books: [
            MypageUserBook(title: "책1", auth: "저자", image: nil),
            MypageUserBook(title: "책2", auth: "저자", image: nil),
            MypageUserBook(title: "책3", auth: "저자", image: nil),
            MypageUserBook(title: "책4", auth: "저자", image: nil),
            MypageUserBook(title: "책5", auth: "저자", image: nil)
        ],
        userService: UserService(interceptor: AuthInterceptor(authService: AuthService())),
        onClose: {}
    )
}
