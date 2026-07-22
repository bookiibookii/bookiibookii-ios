import Foundation
import Combine
import PhotosUI
import SwiftUI

@MainActor
final class ProfileChangeViewModel: ObservableObject {
    enum NicknameValidationState: Equatable {
        case idle
        case loading
        case available
        case duplicate
        case badWord
        case error(String)

        var message: String {
            switch self {
            case .idle, .loading: return ""
            case .available: return "사용 가능한 닉네임입니다."
            case .duplicate: return "이미 사용 중인 닉네임입니다."
            case .badWord: return "사용할 수 없는 단어가 포함되어 있습니다."
            case .error(let message): return message
            }
        }

        var isAvailable: Bool {
            if case .available = self { return true }
            return false
        }
    }

    @Published var profileImageURL: URL?
    @Published var selectedImage: UIImage?
    @Published var isUsingDefaultImage = false
    @Published var photoImportError: String?
    @Published var nickname: String = ""
    @Published var gender: Gender?
    @Published var birthDate: Date?
    @Published var isSaving = false
    @Published var saveMessage: String?
    @Published var nicknameValidationState: NicknameValidationState = .idle

    private let userService: UserService
    private var originalSnapshot = ProfileSnapshot.empty
    private var originalNickname: String = ""
    private var hadProfileImage = false

    init(userService: UserService) {
        self.userService = userService
    }

    var hasChanges: Bool {
        currentSnapshot != originalSnapshot
            || selectedImage != nil
            || (isUsingDefaultImage && hadProfileImage)
    }

    var canSubmit: Bool {
        !nickname.trimmed.isEmpty &&
        isNicknameValidForSubmit &&
        gender != nil &&
        birthDate != nil
    }

    func load() async {
        do {
            let profile = try await userService.getMypage()
            profileImageURL = profile.profileImageUrl.flatMap(URL.init(string:))
            hadProfileImage = profileImageURL != nil
            isUsingDefaultImage = false
            selectedImage = nil
            nickname = profile.nickname
            originalNickname = profile.nickname
            nicknameValidationState = .available
            gender = Gender.from(server: profile.gender)
            birthDate = Self.parseBirthDate(profile.birthDate)
            originalSnapshot = currentSnapshot
        } catch {
            print("프로필 정보 로드 실패: \(error)")
        }
    }

    func saveChanges() async {
        guard hasChanges, canSubmit else { return }
        isSaving = true
        defer { isSaving = false }

        if nickname.trimmed != originalNickname.trimmed {
            await checkNicknameDuplicatedAsync()
            guard nicknameValidationState.isAvailable else {
                saveMessage = nicknameValidationState.message.isEmpty
                    ? "닉네임 중복 확인이 필요합니다."
                    : nicknameValidationState.message
                return
            }
        }

        do {
            let s3Key = try await uploadProfileImageIfNeeded()
            guard let birth = birthDate else { return }

            let payload = MypageUpdateRequest(
                nickname: nickname.trimmed,
                gender: gender?.serverValue,
                birth: Self.birthFormatter.string(from: birth),
                s3Key: s3Key
            )
            try await userService.updateMypage(payload)

            let updated = try await userService.getMypage()
            profileImageURL = updated.profileImageUrl.flatMap(URL.init(string:))
            hadProfileImage = profileImageURL != nil

            saveMessage = "수정사항이 저장되었어요."
            originalSnapshot = currentSnapshot
            originalNickname = nickname.trimmed
            selectedImage = nil
            isUsingDefaultImage = false
        } catch {
            saveMessage = "저장에 실패했어요. 잠시 후 다시 시도해 주세요."
        }
    }

    func consumePhotosPickerItem(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task { await loadProfilePhoto(from: item) }
    }

    func setCapturedImage(_ image: UIImage) {
        selectedImage = image
        isUsingDefaultImage = false
        photoImportError = nil
    }

    func selectDefaultImage() {
        selectedImage = nil
        isUsingDefaultImage = true
        photoImportError = nil
    }

    private func loadProfilePhoto(from item: PhotosPickerItem) async {
        do {
            let image = try await PhotosPickerImageLoader.uiImage(from: item)
            setCapturedImage(image)
        } catch {
            photoImportError = error.localizedDescription
        }
    }

    private func uploadProfileImageIfNeeded() async throws -> String? {
        if isUsingDefaultImage {
            return "DEFAULT"
        }
        guard let image = selectedImage,
              let imageData = ImageCompressor.compressedJPEG(from: image) else {
            return nil
        }
        let presigned = try await userService.getPresignedUrl()
        try await userService.uploadImageToS3(presignedUrl: presigned.presignedPutUrl, imageData: imageData)
        return presigned.s3Key
    }

    func clearSaveMessage() { saveMessage = nil }

    func onNicknameChanged(_ newValue: String) {
        nickname = String(newValue.prefix(10))
        if nickname.trimmed == originalNickname.trimmed {
            nicknameValidationState = .available
        } else {
            nicknameValidationState = .idle
        }
    }

    func checkNicknameDuplicated() {
        Task { await checkNicknameDuplicatedAsync() }
    }

    private func checkNicknameDuplicatedAsync() async {
        let trimmed = nickname.trimmed
        guard !trimmed.isEmpty else { return }
        if trimmed == originalNickname.trimmed {
            nicknameValidationState = .available
            return
        }

        nicknameValidationState = .loading
        do {
            let result = try await userService.checkNickname(trimmed)
            switch result.code {
            case "SUCCESS": nicknameValidationState = .available
            case "DUPLICATE": nicknameValidationState = .duplicate
            case "BAD_WORD": nicknameValidationState = .badWord
            default: nicknameValidationState = .error(result.message)
            }
        } catch {
            nicknameValidationState = .error(error.localizedDescription)
        }
    }

    private var currentSnapshot: ProfileSnapshot {
        ProfileSnapshot(
            nickname: nickname,
            gender: gender,
            birthDate: birthDate
        )
    }

    private var isNicknameValidForSubmit: Bool {
        nickname.trimmed == originalNickname.trimmed || nicknameValidationState.isAvailable
    }

    private static let birthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let birthParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static func parseBirthDate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        return birthParser.date(from: value)
    }
}

private struct ProfileSnapshot: Equatable {
    let nickname: String
    let gender: Gender?
    let birthDate: Date?

    static let empty = ProfileSnapshot(nickname: "", gender: nil, birthDate: nil)
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
