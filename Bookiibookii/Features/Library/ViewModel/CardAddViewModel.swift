import Combine
import Foundation

enum CardAddMode: Equatable {
    case create(userBookId: Int, cardType: LibraryCardType)
    case edit(cardId: Int, userBookId: Int, cardType: LibraryCardType)

    var isEdit: Bool {
        if case .edit = self { return true }
        return false
    }

    var editCardId: Int? {
        if case .edit(let cid, _, _) = self { return cid }
        return nil
    }
}

@MainActor
final class CardAddViewModel: ObservableObject {
    let mode: CardAddMode
    let bookTitle: String
    private let libraryService: LibraryService
    private let userService: UserService

    @Published var pageText = ""
    @Published var memo = ""
    @Published var quotation = ""
    @Published private(set) var previewImageData: Data?
    @Published private(set) var uploadedS3Key: String?
    @Published private(set) var isUploading = false
    @Published private(set) var isSubmitting = false
    @Published private(set) var authorIdentifier = ""
    @Published var toastMessage: String?

    /// 수정 모드에서 저장 후 변경 여부 판별용 스냅샷.
    private var baselinePage: Int?
    private var baselineMemo: String?
    private var baselineS3Key: String?
    private var baselineQuotation: String?

    private var replaceBackup: (Data?, String?)?

    init(
        mode: CardAddMode,
        bookTitle: String,
        libraryService: LibraryService,
        userService: UserService
    ) {
        self.mode = mode
        self.bookTitle = bookTitle
        self.libraryService = libraryService
        self.userService = userService
    }

    var navigationTitle: String {
        mode.isEdit ? "독서카드 수정" : "독서카드 추가"
    }

    var submitButtonTitle: String {
        mode.isEdit ? "수정" : "등록"
    }

    var isEditMode: Bool { mode.isEdit }

    @Published private(set) var isLoadingEditState = false

    var cardType: LibraryCardType {
        switch mode {
        case .create(_, let cardType):
            return cardType
        case .edit(_, _, let cardType):
            return cardType
        }
    }

    var canSubmit: Bool {
        guard let page = parsedPage else { return false }
        guard !isUploading && !isSubmitting else { return false }

        if mode.isEdit {
            guard let bp = baselinePage,
                  let bm = baselineMemo else {
                return false
            }
            let memoNow = memo.trimmingCharacters(in: .whitespacesAndNewlines)
            let quotationNow = quotation.trimmingCharacters(in: .whitespacesAndNewlines)

            switch cardType {
            case .image:
                guard let key = uploadedS3Key, !key.isEmpty,
                      let bk = baselineS3Key else {
                    return false
                }
                let changed = page != bp || memoNow != bm || key != bk
                return changed
            case .text:
                guard let bq = baselineQuotation else { return false }
                let changed = page != bp || memoNow != bm || quotationNow != bq
                return !quotationNow.isEmpty && changed
            }
        }

        switch cardType {
        case .image:
            return uploadedS3Key?.isEmpty == false
        case .text:
            return !quotation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private var parsedPage: Int? {
        let t = pageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let v = Int(t), v > 0 else { return nil }
        return v
    }

    func loadEditInitialStateIfNeeded() async {
        guard case .edit(let cardId, _, _) = mode else { return }
        guard baselinePage == nil else { return }

        isLoadingEditState = true
        defer { isLoadingEditState = false }

        do {
            let detail = try await libraryService.fetchLibraryCardDetail(cardId: cardId)
            pageText = "\(detail.page)"
            memo = detail.memo
            quotation = detail.quotation ?? ""

            let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedQuotation = quotation.trimmingCharacters(in: .whitespacesAndNewlines)
            baselinePage = detail.page
            baselineMemo = trimmedMemo
            baselineQuotation = trimmedQuotation
            let key = detail.imageS3Key ?? ""
            baselineS3Key = key
            uploadedS3Key = detail.imageS3Key

            if detail.cardType == .image,
               let urlStr = detail.imageURL,
               let url = URL(string: urlStr) {
                let (data, _) = try await URLSession.shared.data(from: url)
                if !data.isEmpty {
                    previewImageData = data
                }
            }
        } catch {
            toastMessage = error.localizedDescription
        }
    }

    func loadAuthorIdentifier() async {
        guard authorIdentifier.isEmpty else { return }
        do {
            let profile = try await userService.getMypage()
            let nickname = profile.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
            authorIdentifier = nickname.isEmpty ? "\(profile.userId)" : nickname
        } catch {
            authorIdentifier = "-"
        }
    }

    func beginReplacePhotoSession() {
        replaceBackup = (previewImageData, uploadedS3Key)
    }

    func restoreReplaceBackupIfNeeded() {
        guard let backup = replaceBackup else { return }
        previewImageData = backup.0
        uploadedS3Key = backup.1
        replaceBackup = nil
    }

    /// 사진은 View에서 `PhotosPickerItem` → JPEG `Data` 변환 후 전달 (View만 `PhotosUI` import).
    func handlePickedJPEG(_ jpegData: Data, isReplace: Bool) async {
        do {
            try await uploadPhoto(jpegData, isReplace: isReplace)
            if isReplace {
                replaceBackup = nil
            }
        } catch {
            if isReplace {
                if let backup = replaceBackup {
                    previewImageData = backup.0
                    uploadedS3Key = backup.1
                }
                replaceBackup = nil
            }
            toastMessage = error.localizedDescription
        }
    }

    private func uploadPhoto(_ imageData: Data, isReplace: Bool) async throws {
        isUploading = true
        defer { isUploading = false }

        // 안드로이드와 동일 기준으로 리사이즈·재압축 (1600px / 1MB 이하)
        let uploadData = ImageCompressor.compressedJPEG(from: imageData) ?? imageData

        let presigned: PresignedUrlResult
        switch mode {
        case .create(let userBookId, _):
            presigned = try await libraryService.requestCardImagePresignedURL(userBookId: userBookId)
        case .edit(_, let userBookId, _):
            presigned = try await libraryService.requestCardImagePresignedURL(userBookId: userBookId)
        }
        try await libraryService.uploadCardImageToS3(presignedPutUrl: presigned.presignedPutUrl, imageData: uploadData)

        previewImageData = uploadData
        uploadedS3Key = presigned.s3Key
    }

    func submit() async -> Bool {
        guard canSubmit, let page = parsedPage else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        let memoTrimmed = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        let memoPayload = memoTrimmed.isEmpty ? nil : memoTrimmed
        let quotationTrimmed = quotation.trimmingCharacters(in: .whitespacesAndNewlines)
        let quotationPayload = quotationTrimmed.isEmpty ? nil : quotationTrimmed

        do {
            switch mode {
            case .create(let userBookId, let cardType):
                _ = try await libraryService.createLibraryCard(
                    userBookId: userBookId,
                    cardType: cardType,
                    s3Key: cardType == .image ? uploadedS3Key : nil,
                    quotation: cardType == .text ? quotationPayload : nil,
                    page: page,
                    memo: memoPayload
                )
            case .edit(let cardId, _, let cardType):
                switch cardType {
                case .image:
                    guard let key = uploadedS3Key else { return false }
                    try await libraryService.updateLibraryCard(
                        cardId: cardId,
                        s3Key: key,
                        page: page,
                        memo: memoPayload,
                        quotation: nil
                    )
                case .text:
                    try await libraryService.updateLibraryCard(
                        cardId: cardId,
                        s3Key: nil,
                        page: page,
                        memo: memoPayload,
                        quotation: quotationPayload
                    )
                }
            }
            return true
        } catch {
            toastMessage = error.localizedDescription
            return false
        }
    }
}
