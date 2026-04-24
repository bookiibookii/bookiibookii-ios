import Foundation
import SwiftUI

@MainActor
final class ProfileChangeViewModel: ObservableObject {
    @Published var profileImageURL: URL?
    @Published var selectedImage: UIImage?
    @Published var nickname: String = ""
    @Published var name: String = ""
    @Published var phone: String = ""
    @Published var zipCode: String = ""
    @Published var address: String = ""
    @Published var detailAddress: String = ""
    @Published var exchangeRegion: String = ""
    @Published var isSaving = false
    @Published var saveMessage: String?

    private let userService: UserService
    private let cacheKey = "profile_change_info_cache_v1"
    private var originalSnapshot = ProfileSnapshot.empty

    init(userService: UserService) {
        self.userService = userService
    }

    var hasChanges: Bool {
        currentSnapshot != originalSnapshot || selectedImage != nil
    }

    var hasAnyInput: Bool {
        !name.isEmpty || !phone.isEmpty || !zipCode.isEmpty || !address.isEmpty || !detailAddress.isEmpty || !exchangeRegion.isEmpty
    }

    func load() async {
        do {
            let profile = try await userService.getMypage()
            profileImageURL = profile.profileImageUrl.flatMap(URL.init(string:))
            nickname = profile.nickname
        } catch {
            print("마이페이지 정보 로드 실패: \(error)")
        }

        do {
            let info = try await userService.getProfileChangeInfo()
            applyInfo(info)
            persistLocally(info)
        } catch {
            if let cached = loadLocalCache() { applyInfo(cached) }
        }
    }

    func saveChanges() async {
        guard hasChanges else { return }
        isSaving = true
        defer { isSaving = false }

        let payload = ProfileChangeUpdateRequest(
            recipientName: emptyToNil(name),
            phoneNumber: emptyToNil(phone),
            zipCode: emptyToNil(zipCode),
            address: emptyToNil(address),
            detailAddress: emptyToNil(detailAddress),
            exchangeRegion: emptyToNil(exchangeRegion)
        )

        do {
            try await userService.updateProfileChangeInfo(payload)
            saveMessage = "수정사항이 저장되었어요."
        } catch {
            saveMessage = "서버 반영에 실패해 로컬에 임시 저장했어요."
        }

        let saved = ProfileChangeInfoResult(
            recipientName: payload.recipientName,
            phoneNumber: payload.phoneNumber,
            zipCode: payload.zipCode,
            address: payload.address,
            detailAddress: payload.detailAddress,
            exchangeRegion: payload.exchangeRegion
        )
        persistLocally(saved)
        selectedImage = nil
        originalSnapshot = currentSnapshot
    }

    func clearSaveMessage() { saveMessage = nil }

    private var currentSnapshot: ProfileSnapshot {
        .init(name: name, phone: phone, zipCode: zipCode, address: address, detailAddress: detailAddress, exchangeRegion: exchangeRegion)
    }

    private func applyInfo(_ info: ProfileChangeInfoResult) {
        name = info.recipientName ?? ""
        phone = info.phoneNumber ?? ""
        zipCode = info.zipCode ?? ""
        address = info.address ?? ""
        detailAddress = info.detailAddress ?? ""
        exchangeRegion = info.exchangeRegion ?? ""
        originalSnapshot = currentSnapshot
    }

    private func persistLocally(_ info: ProfileChangeInfoResult) {
        guard let encoded = try? JSONEncoder().encode(info) else { return }
        UserDefaults.standard.set(encoded, forKey: cacheKey)
    }

    private func loadLocalCache() -> ProfileChangeInfoResult? {
        guard
            let data = UserDefaults.standard.data(forKey: cacheKey),
            let decoded = try? JSONDecoder().decode(ProfileChangeInfoResult.self, from: data)
        else { return nil }
        return decoded
    }

    private func emptyToNil(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private struct ProfileSnapshot: Equatable {
    let name: String
    let phone: String
    let zipCode: String
    let address: String
    let detailAddress: String
    let exchangeRegion: String

    static let empty = ProfileSnapshot(name: "", phone: "", zipCode: "", address: "", detailAddress: "", exchangeRegion: "")
}
