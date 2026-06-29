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
    @Published var photoImportError: String?
    @Published var nickname: String = ""
    @Published var name: String = ""
    @Published var phone: String = ""
    @Published var zipCode: String = ""
    @Published var address: String = ""
    @Published var detailAddress: String = ""
    @Published var exchangeRegion: String = ""
    @Published var isSaving = false
    @Published var saveMessage: String?
    @Published var nicknameValidationState: NicknameValidationState = .idle

    private let userService: UserService
    private var originalSnapshot = ProfileSnapshot.empty
    private var originalNickname: String = ""

    init(userService: UserService) {
        self.userService = userService
    }

    var hasChanges: Bool {
        currentSnapshot != originalSnapshot || selectedImage != nil
    }

    var canSubmit: Bool {
        !nickname.trimmed.isEmpty &&
        isNicknameValidForSubmit &&
        !name.trimmed.isEmpty &&
        !phone.trimmed.isEmpty &&
        !zipCode.trimmed.isEmpty &&
        !address.trimmed.isEmpty &&
        !detailAddress.trimmed.isEmpty
    }

    func load() async {
        do {
            let profile = try await userService.getMypage()
            profileImageURL = profile.profileImageUrl.flatMap(URL.init(string:))
            nickname = profile.nickname
            originalNickname = profile.nickname
            nicknameValidationState = .available
            name = profile.receiverName ?? ""
            phone = formatPhoneNumber(profile.phone ?? "")
            zipCode = profile.zipCode ?? ""
            address = profile.address ?? ""
            detailAddress = profile.addressDetail ?? ""
            exchangeRegion = profile.region ?? ""
            originalSnapshot = currentSnapshot
        } catch {
            print("마이페이지 정보 로드 실패: \(error)")
        }
    }

    func saveChanges() async {
        guard hasChanges, canSubmit else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            let s3Key = try await uploadProfileImageIfNeeded()

            let payload = MypageUpdateRequest(
                nickname: nickname.trimmed,
                s3Key: s3Key,
                receiverName: name.trimmed,
                phone: phone.trimmed,
                zipCode: zipCode.trimmed,
                address: address.trimmed,
                addressDetail: detailAddress.trimmed,
                meetPlace: nil,
                region: emptyToNil(exchangeRegion)
            )

            try await userService.updateMypage(payload)
            saveMessage = "수정사항이 저장되었어요."
            originalSnapshot = currentSnapshot
            selectedImage = nil
        } catch {
            saveMessage = "저장에 실패했어요. 잠시 후 다시 시도해 주세요."
        }
    }

    func consumePhotosPickerItem(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task { await loadProfilePhoto(from: item) }
    }

    private func loadProfilePhoto(from item: PhotosPickerItem) async {
        do {
            let image = try await PhotosPickerImageLoader.uiImage(from: item)
            self.selectedImage = image
            self.photoImportError = nil
        } catch {
            self.photoImportError = error.localizedDescription
        }
    }

    private func uploadProfileImageIfNeeded() async throws -> String? {
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
        let trimmed = nickname.trimmed
        guard !trimmed.isEmpty else { return }
        if trimmed == originalNickname.trimmed {
            nicknameValidationState = .available
            return
        }

        nicknameValidationState = .loading
        Task {
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
    }

    func updatePhone(_ input: String) {
        phone = formatPhoneNumber(input)
    }

    private var currentSnapshot: ProfileSnapshot {
        .init(
            nickname: nickname,
            name: name,
            phone: phone,
            zipCode: zipCode,
            address: address,
            detailAddress: detailAddress,
            exchangeRegion: exchangeRegion
        )
    }

    private func emptyToNil(_ value: String) -> String? {
        value.trimmed.isEmpty ? nil : value.trimmed
    }

    private var isNicknameValidForSubmit: Bool {
        nickname.trimmed == originalNickname.trimmed || nicknameValidationState.isAvailable
    }

    private func formatPhoneNumber(_ input: String) -> String {
        let digits = input.filter(\.isNumber)
        let limited = String(digits.prefix(11))
        switch limited.count {
        case 0...3:
            return limited
        case 4...7:
            let first = limited.prefix(3)
            let second = limited.dropFirst(3)
            return "\(first)-\(second)"
        default:
            let first = limited.prefix(3)
            let middle = limited.dropFirst(3).prefix(4)
            let last = limited.dropFirst(7)
            return "\(first)-\(middle)-\(last)"
        }
    }
}

private struct ProfileSnapshot: Equatable {
    let nickname: String
    let name: String
    let phone: String
    let zipCode: String
    let address: String
    let detailAddress: String
    let exchangeRegion: String

    static let empty = ProfileSnapshot(
        nickname: "",
        name: "",
        phone: "",
        zipCode: "",
        address: "",
        detailAddress: "",
        exchangeRegion: ""
    )
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
