import Combine
import Foundation

enum CardAddMode: Equatable {
    case create(userBookId: Int)
    case edit(cardId: Int, userBookId: Int)

    var isEdit: Bool {
        if case .edit = self { return true }
        return false
    }

    var editCardId: Int? {
        if case .edit(let cid, _) = self { return cid }
        return nil
    }
}

@MainActor
final class CardAddViewModel: ObservableObject {
    let mode: CardAddMode
    private let libraryService: LibraryService

    @Published var pageText = ""
    @Published var memo = ""
    @Published private(set) var previewImageData: Data?
    @Published private(set) var uploadedS3Key: String?
    @Published private(set) var isUploading = false
    @Published private(set) var isSubmitting = false
    @Published var toastMessage: String?

    /// 수정 모드에서 저장 후 변경 여부 판별용 스냅샷.
    private var baselinePage: Int?
    private var baselineMemo: String?
    private var baselineS3Key: String?

    private var replaceBackup: (Data?, String?)?

    init(mode: CardAddMode, libraryService: LibraryService) {
        self.mode = mode
        self.libraryService = libraryService
    }

    var navigationTitle: String {
        mode.isEdit ? "독서카드 수정" : "카드 추가"
    }

    var submitButtonTitle: String {
        mode.isEdit ? "완료하기" : "등록하기"
    }

    var canSubmit: Bool {
        guard let key = uploadedS3Key, !key.isEmpty else { return false }
        guard let page = parsedPage else { return false }
        guard !isUploading && !isSubmitting else { return false }

        if mode.isEdit {
            guard let bp = baselinePage,
                  let bm = baselineMemo,
                  let bk = baselineS3Key else {
                return false
            }
            let memoNow = memo.trimmingCharacters(in: .whitespacesAndNewlines)
            let changed = page != bp || memoNow != bm || key != bk
            return changed
        }

        return true
    }

    private var parsedPage: Int? {
        let t = pageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let v = Int(t), v > 0 else { return nil }
        return v
    }

    func loadEditInitialStateIfNeeded() async {
        guard case .edit(let cardId, _) = mode else { return }
        guard baselinePage == nil else { return }

        do {
            let detail = try await libraryService.fetchLibraryCardDetail(cardId: cardId)
            pageText = "\(detail.page)"
            memo = detail.memo

            let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
            baselinePage = detail.page
            baselineMemo = trimmedMemo
            let key = detail.imageS3Key ?? ""
            baselineS3Key = key
            uploadedS3Key = detail.imageS3Key

            if let urlStr = detail.imageURL, let url = URL(string: urlStr) {
                let (data, _) = try await URLSession.shared.data(from: url)
                if !data.isEmpty {
                    previewImageData = data
                }
            }
        } catch {
            toastMessage = error.localizedDescription
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
        case .create(let userBookId):
            presigned = try await libraryService.requestCardImagePresignedURL(userBookId: userBookId)
        case .edit(let cardId, _):
            presigned = try await libraryService.requestCardImagePresignedURLForUpdate(cardId: cardId)
        }
        try await libraryService.uploadCardImageToS3(presignedPutUrl: presigned.presignedPutUrl, imageData: uploadData)

        previewImageData = uploadData
        uploadedS3Key = presigned.s3Key
    }

    func submit() async -> Bool {
        guard let key = uploadedS3Key, let page = parsedPage else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        let memoTrimmed = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        let memoPayload = memoTrimmed.isEmpty ? nil : memoTrimmed

        do {
            switch mode {
            case .create(let userBookId):
                _ = try await libraryService.createLibraryCard(
                    userBookId: userBookId,
                    s3Key: key,
                    page: page,
                    memo: memoPayload
                )
            case .edit(let cardId, _):
                try await libraryService.updateLibraryCard(
                    cardId: cardId,
                    s3Key: key,
                    page: page,
                    memo: memoPayload
                )
            }
            return true
        } catch {
            toastMessage = error.localizedDescription
            return false
        }
    }
}
