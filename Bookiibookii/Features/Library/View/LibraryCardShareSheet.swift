import SwiftUI

/// 독서카드 상세 화면의 공유 시트.
/// - 상단: "공유하기" 헤더 + 닫기 버튼 (`ic_close`)
/// - 미리보기 스타일 선택: `ic_divide_image`, `ic_card_image`
/// - 미리보기: `LibraryCardSharePreview`
/// - 하단: 인스타/카카오/X/링크복사 (`ic_insta`, `ic_kakao`, `ic_x`, `ic_link`)
struct LibraryCardShareSheet: View {
    let detail: LibraryCardDetail
    let onClose: () -> Void

    @State private var style: LibraryCardShareStyle = .divide
    @State private var alertMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)

            LibraryCardSharePreview(detail: detail, style: style)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)
            
            styleSelector
                .padding(.bottom, 20)

            platformButtons
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color("white"))
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
        HStack {
            Text("공유하기")
                .font(.pretendard(size: 18, weight: .medium))
                .foregroundColor(Color("grey900"))

            Spacer()

            Button(action: onClose) {
                Image("ic_close")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
    }

    private var styleSelector: some View {
        HStack(spacing: 16) {
            styleButton(.divide, asset: "ic_divide_image")
            styleButton(.card, asset: "ic_card_image")
        }
    }

    private func styleButton(_ target: LibraryCardShareStyle, asset: String) -> some View {
        Button {
            style = target
        } label: {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
    }

    private var platformButtons: some View {
        HStack(spacing: 0) {
            platformButton("ic_insta", label: "인스타그램", action: shareToInstagram)
            platformButton("ic_kakao", label: "카카오톡", action: shareToKakao)
            platformButton("ic_x", label: "X", action: shareToX)
            platformButton("ic_link", label: "링크복사", action: copyLink)
        }
    }

    private func platformButton(_ asset: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                Text(label)
                    .font(.pretendard(size: 12, weight: .regular))
                    .foregroundColor(Color("grey900"))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Share actions

    /// 현재 선택된 미리보기 스타일을 PNG로 렌더링해 인스타그램 스토리에 스티커로 공유합니다.
    /// - 인스타그램 미설치 시 안내 알럿
    /// - 렌더 실패 시 안내 알럿
    private func shareToInstagram() {
        let preview = LibraryCardSharePreview(detail: detail, style: style)
            .background(Color("white"))

        guard let image = SharePreviewImageRenderer.render(preview, width: 800, scale: 3) else {
            alertMessage = InstagramStoriesShareError.renderFailed.errorDescription
            return
        }

        Task {
            do {
                try await InstagramStoriesShare.share(
                    stickerImage: image,
                    backgroundTopColor: UIColor(named: "main100") ?? .white,
                    backgroundBottomColor: UIColor(named: "main105") ?? .white
                )
            } catch let error as InstagramStoriesShareError {
                alertMessage = error.errorDescription
            } catch {
                alertMessage = error.localizedDescription
            }
        }
    }

    private func shareToKakao() {
        // TODO: KakaoSDK 공유 연동
    }

    private func shareToX() {
        // TODO: X(Twitter) 공유 연동
    }

    private func copyLink() {
        UIPasteboard.general.string = "bookiibookii://card/\(detail.cardId)"
    }
}

#Preview {
    LibraryCardShareSheet(
        detail: LibraryCardDetail(
            cardId: 1,
            page: 122,
            memo: "감각이 살아 있는 문장들이 가득. 다시 읽고 싶은 책.",
            imageURL: nil,
            imageS3Key: nil,
            creatorName: "noshel",
            bookTitle: "괴테는 모든 것을 말했다",
            isBookmarked: false,
            createdAt: nil
        ),
        onClose: {}
    )
}
