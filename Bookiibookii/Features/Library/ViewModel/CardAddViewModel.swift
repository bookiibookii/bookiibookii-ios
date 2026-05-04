import Combine
import Foundation

@MainActor
final class CardAddViewModel: ObservableObject {
    let userBookId: Int
    private let libraryService: LibraryService

    @Published var pageText = ""
    @Published var memo = ""
    @Published private(set) var previewImageData: Data?
    @Published private(set) var uploadedS3Key: String?
    @Published private(set) var isUploading = false
    @Published private(set) var isSubmitting = false
    @Published var toastMessage: String?

    private var replaceBackup: (Data?, String?)?

    init(userBookId: Int, libraryService: LibraryService) {
        self.userBookId = userBookId
        self.libraryService = libraryService
    }

    var canSubmit: Bool {
        uploadedS3Key != nil && parsedPage != nil && !isUploading && !isSubmitting
    }

    private var parsedPage: Int? {
        let t = pageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let v = Int(t), v > 0 else { return nil }
        return v
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

        let presigned = try await libraryService.requestCardImagePresignedURL(userBookId: userBookId)
        try await libraryService.uploadCardImageToS3(presignedPutUrl: presigned.presignedPutUrl, imageData: imageData)

        previewImageData = imageData
        uploadedS3Key = presigned.s3Key
    }

    func submit() async -> Bool {
        guard let key = uploadedS3Key, let page = parsedPage else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        let memoTrimmed = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        let memoPayload = memoTrimmed.isEmpty ? nil : memoTrimmed

        do {
            _ = try await libraryService.createLibraryCard(
                userBookId: userBookId,
                s3Key: key,
                page: page,
                memo: memoPayload
            )
            return true
        } catch {
            toastMessage = error.localizedDescription
            return false
        }
    }
}
