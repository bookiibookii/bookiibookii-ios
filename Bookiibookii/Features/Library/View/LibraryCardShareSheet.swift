import SwiftUI
import UIKit
import Photos
import KakaoSDKShare
import KakaoSDKTemplate

/// 독서카드 공유 바텀시트 (Figma LIB-03-02).
/// 카카오톡 / 인스타그램 / X / 다운로드 / 링크 복사 — 안드로이드 `ReadingCardShareBottomSheet`와 동일 액션.
struct LibraryCardShareSheet: View {
    let detail: LibraryCardDetail
    /// 서버 `ShareLayout`: `"OVERLAY"` | `"SPLIT"`
    let shareLayout: String
    let libraryService: LibraryService
    let onClose: () -> Void

    @State private var alertMessage: String?
    @State private var isBusy = false

    private var previewStyle: LibraryCardShareStyle {
        shareLayout.uppercased() == "SPLIT" ? .divide : .card
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Figma처럼 위는 반투명 딤 — 카드 상세가 비침
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 0) {
                Capsule()
                    .fill(Color("grey200"))
                    .frame(width: 44, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                Text("공유하기")
                    .pretendardText(size: 20, weight: .semibold)
                    .foregroundColor(Color("grey900"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)

                Rectangle()
                    .fill(Color("grey200"))
                    .frame(height: 0.5)

                HStack(spacing: 0) {
                    shareOption(
                        label: "카카오톡",
                        circularBackground: Color("kakao")
                    ) {
                        Image("ic_kakao")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                    } action: {
                        Task { await shareToKakao() }
                    }

                    shareOption(label: "인스타그램", circularBackground: nil) {
                        Image("ic_insta")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                    } action: {
                        Task { await shareToInstagram() }
                    }

                    shareOption(label: "X", circularBackground: nil) {
                        Image("img_share_x")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                    } action: {
                        Task { await shareToX() }
                    }

                    shareOption(
                        label: "다운로드",
                        circularBackground: Color("grey100")
                    ) {
                        Image("ic_download")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color("grey700"))
                            .frame(width: 24, height: 24)
                    } action: {
                        Task { await downloadCard() }
                    }

                    shareOption(
                        label: "링크 복사",
                        circularBackground: Color("grey100")
                    ) {
                        Image("ic_link")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color("grey700"))
                            .frame(width: 24, height: 24)
                    } action: {
                        Task { await copyLink() }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 24)
                .padding(.bottom, 24)
                .disabled(isBusy)
                .opacity(isBusy ? 0.6 : 1)
            }
            .frame(maxWidth: .infinity)
            // 홈 인디케이터(둥근 하단) 영역까지 흰색으로 채움
            .background {
                UnevenRoundedRectangle(
                    topLeadingRadius: 20,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 20
                )
                .fill(Color("white"))
                .shadow(color: Color.black.opacity(0.1), radius: 17.5)
                .ignoresSafeArea(edges: .bottom)
            }
            .safeAreaPadding(.bottom)
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

    private func shareOption<Icon: View>(
        label: String,
        circularBackground: Color?,
        @ViewBuilder icon: () -> Icon,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Group {
                    if let circularBackground {
                        icon()
                            .frame(width: 56, height: 56)
                            .background(circularBackground)
                            .clipShape(Circle())
                    } else {
                        icon()
                            .frame(width: 56, height: 56)
                    }
                }

                Text(label)
                    .pretendardText(size: 12, weight: .regular)
                    .foregroundColor(Color("grey700"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func fetchShareURL() async throws -> ShareTokenResponseDTO {
        try await libraryService.createCardShareToken(
            cardId: detail.cardId,
            shareLayout: shareLayout
        )
    }

    private func shareToKakao() async {
        isBusy = true
        defer { isBusy = false }

        do {
            let result = try await fetchShareURL()
            let shareURL = result.shareUrl
            let token = result.shareToken
            let title = (detail.bookTitle?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap {
                $0.isEmpty ? nil : $0
            } ?? "독서카드"
            let description = detail.quotation?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                ?? detail.memo
            let imageURL = detail.imageURL.flatMap(URL.init(string:))

            let link = Link(
                webUrl: URL(string: shareURL),
                mobileWebUrl: URL(string: shareURL),
                androidExecutionParams: ["shareToken": token],
                iosExecutionParams: ["shareToken": token]
            )
            let content = Content(
                title: title,
                imageUrl: imageURL,
                description: description,
                link: link
            )
            let template = FeedTemplate(
                content: content,
                buttons: [KakaoSDKTemplate.Button(title: "보러가기", link: link)]
            )

            if ShareApi.isKakaoTalkSharingAvailable() {
                ShareApi.shared.shareDefault(templatable: template) { sharingResult, error in
                    if error != nil {
                        alertMessage = "공유에 실패했어요."
                        return
                    }
                    if let url = sharingResult?.url {
                        UIApplication.shared.open(url)
                        onClose()
                    }
                }
            } else if let url = ShareApi.shared.makeDefaultUrl(templatable: template) {
                await UIApplication.shared.open(url)
                onClose()
            } else {
                alertMessage = "카카오톡을 열 수 없어요."
            }
        } catch {
            alertMessage = (error as? LocalizedError)?.errorDescription ?? "공유에 실패했어요."
        }
    }

    private func shareToInstagram() async {
        isBusy = true
        defer { isBusy = false }

        guard let image = renderShareImage() else {
            alertMessage = InstagramStoriesShareError.renderFailed.errorDescription
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
        isBusy = true
        defer { isBusy = false }

        do {
            let result = try await fetchShareURL()
            let text = (detail.bookTitle?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap {
                $0.isEmpty ? nil : $0
            } ?? "독서카드"
            var components = URLComponents(string: "https://twitter.com/intent/tweet")
            components?.queryItems = [
                URLQueryItem(name: "text", value: text),
                URLQueryItem(name: "url", value: result.shareUrl)
            ]
            guard let intentURL = components?.url else {
                alertMessage = "X를 열 수 없어요."
                return
            }
            await UIApplication.shared.open(intentURL)
            onClose()
        } catch {
            alertMessage = (error as? LocalizedError)?.errorDescription ?? "공유에 실패했어요."
        }
    }

    private func downloadCard() async {
        isBusy = true
        defer { isBusy = false }

        guard let image = renderShareImage() else {
            alertMessage = "저장 중 오류가 발생했어요."
            return
        }

        do {
            try await CardSharePhotoSaver.save(image)
            alertMessage = "사진을 저장했어요."
        } catch {
            alertMessage = (error as? LocalizedError)?.errorDescription ?? "사진 저장에 실패했어요."
        }
    }

    private func copyLink() async {
        isBusy = true
        defer { isBusy = false }

        do {
            let result = try await fetchShareURL()
            UIPasteboard.general.string = result.shareUrl
            alertMessage = "링크를 복사했어요."
        } catch {
            alertMessage = (error as? LocalizedError)?.errorDescription ?? "링크 복사에 실패했어요."
        }
    }

    private func renderShareImage() -> UIImage? {
        let preview = LibraryCardSharePreview(detail: detail, style: previewStyle)
            .frame(width: 360)
            .background(Color("white"))
        return SharePreviewImageRenderer.render(preview, width: 360, scale: 3)
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private enum CardSharePhotoSaver {
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

