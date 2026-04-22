import Foundation
import SwiftUI
import Combine

// 안드로이드 OnbProfileViewModel 대응
final class OnboardingProfileViewModel: ObservableObject {

    // MARK: - 닉네임 상태 (안드로이드 NicknameCheckState 대응)
    enum NicknameValidationState {
        case idle
        case loading
        case available   // SUCCESS
        case duplicate   // DUPLICATE
        case badWord     // BAD_WORD
        case error(String)

        var message: String {
            switch self {
            case .idle: return ""
            case .loading: return ""
            case .available: return "사용 가능한 닉네임입니다."
            case .duplicate: return "이미 사용 중인 닉네임입니다."
            case .badWord: return "사용할 수 없는 단어가 포함되어 있습니다."
            case .error(let msg): return msg
            }
        }

        var isAvailable: Bool {
            if case .available = self { return true }
            return false
        }

        var showsValidation: Bool {
            switch self {
            case .idle, .loading: return false
            default: return true
            }
        }

        struct ValidationStyle {
            let iconName: String
            let textColor: Color
            let bgColor: Color
            let borderColor: Color
        }

        var validationStyle: ValidationStyle {
            if case .available = self {
                return ValidationStyle(
                    iconName: "ic_check",
                    textColor: Color(red: 0, green: 0.765, blue: 0.090),
                    bgColor: Color(red: 0.906, green: 1, blue: 0.918),
                    borderColor: Color(red: 0.455, green: 0.824, blue: 0.498)
                )
            }
            return ValidationStyle(
                iconName: "ic_error",
                textColor: Color(red: 1, green: 0.302, blue: 0.302),
                bgColor: Color(red: 1, green: 0.953, blue: 0.953),
                borderColor: Color(red: 1, green: 0.733, blue: 0.733)
            )
        }
    }

    struct ReadyToAdvance: Equatable {
        let name: String
        let s3Key: String?
    }

    @Published var nickname: String = ""
    @Published var nicknameState: NicknameValidationState = .idle
    @Published var selectedImage: UIImage?
    @Published var isCompleting: Bool = false
    @Published var readyToAdvance: ReadyToAdvance? = nil

    private let userService: UserService

    init(userService: UserService) {
        self.userService = userService
    }

    // MARK: - 닉네임 중복 검사
    func checkNickname() {
        let trimmed = nickname.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        nicknameState = .loading

        Task {
            do {
                let result = try await userService.checkNickname(trimmed)
                await MainActor.run {
                    switch result.code {
                    case "SUCCESS":   self.nicknameState = .available
                    case "DUPLICATE": self.nicknameState = .duplicate
                    case "BAD_WORD":  self.nicknameState = .badWord
                    default:          self.nicknameState = .error(result.message)
                    }
                }
            } catch {
                await MainActor.run {
                    self.nicknameState = .error(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - 프로필 수집 완료 (이미지 업로드 → Steps 화면으로 이동)
    func complete() {
        guard nicknameState.isAvailable, !isCompleting else { return }
        isCompleting = true

        Task {
            do {
                let s3Key = try await uploadImageIfNeeded()
                let name = nickname.trimmingCharacters(in: .whitespaces)
                await MainActor.run {
                    self.isCompleting = false
                    self.readyToAdvance = ReadyToAdvance(name: name, s3Key: s3Key)
                }
            } catch {
                print("❌ 프로필 설정 실패: \(error)")
                await MainActor.run { self.isCompleting = false }
            }
        }
    }

    // 이미지가 선택된 경우에만 presigned URL 발급 후 S3 업로드
    private func uploadImageIfNeeded() async throws -> String? {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        let presigned = try await userService.getPresignedUrl()
        try await userService.uploadImageToS3(presignedUrl: presigned.presignedPutUrl, imageData: imageData)
        return presigned.s3Key
    }

    // 닉네임 변경 시 검증 상태 초기화
    func onNicknameChanged() {
        if case .idle = nicknameState { return }
        nicknameState = .idle
    }
}
