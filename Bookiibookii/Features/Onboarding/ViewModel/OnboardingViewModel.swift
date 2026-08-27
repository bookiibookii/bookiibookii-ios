import Combine
import Foundation
import PhotosUI
import SwiftUI

// 안드로이드 OnbViewModel 대응 — 4단계(프로필 · 인생책 · 기록방식 · 자기소개) 통합 상태/로직
@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - 닉네임 검증 상태 (안드로이드 NicknameCheckState 대응)
    enum NicknameValidationState {
        case idle, loading, available, duplicate, badWord
        case error(String)

        var message: String {
            switch self {
            case .idle, .loading: return ""
            case .available: return "사용 가능한 닉네임입니다."
            case .duplicate:  return "이미 사용 중인 닉네임입니다."
            case .badWord:    return "사용할 수 없는 단어가 포함되어 있습니다."
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

    // MARK: - 단계
    @Published var currentStep: Int = 1   // 1...4
    static let totalSteps = 4

    // MARK: - Step 1: 프로필
    @Published var nickname: String = ""
    @Published var nicknameState: NicknameValidationState = .idle
    @Published var selectedImage: UIImage?
    /// 기본 프로필 이미지 선택 시 서버에 `s3Key: "DEFAULT"` 전달.
    private var isUsingDefaultImage = false
    @Published var photoImportError: String?
    @Published var gender: Gender? = nil
    @Published var birthDate: Date? = nil

    // MARK: - Step 2: 인생책 (최대 3권)
    @Published var lifeBooks: [BookItem?] = [nil, nil, nil]
    @Published var searchQuery: String = ""
    @Published var searchResults: [BookItem] = []
    @Published var isSearching: Bool = false

    // MARK: - Step 3: 기록 방식
    @Published var recordMethods: Set<RecordMethod> = []
    @Published var isUnknownMethod: Bool = false

    // MARK: - Step 4: 자기소개 (최대 50자)
    @Published var introduction: String = ""
    static let introMaxLength = 50

    // MARK: - 완료 상태
    @Published var isSubmitting: Bool = false
    @Published var isCompleted: Bool = false
    /// 제출 실패 사유 — 토스트로 노출되고 2초 뒤 자동으로 nil이 된다.
    @Published var toast: ToastMessage?

    private let userService: UserService
    private let groupService: GroupService
    private var searchTask: Task<Void, Never>?

    init(userService: UserService, groupService: GroupService) {
        self.userService = userService
        self.groupService = groupService
    }

    // MARK: - 단계별 다음 버튼 활성화 (안드로이드 OnbStepScreen 조건 대응)
    var canGoNext: Bool {
        switch currentStep {
        case 1: return nicknameState.isAvailable && gender != nil && birthDate != nil
        case 2: return lifeBooks.contains { $0 != nil }
        case 3: return !recordMethods.isEmpty || isUnknownMethod
        case 4: return true
        default: return false
        }
    }

    var isLastStep: Bool { currentStep >= Self.totalSteps }

    func goNext() {
        guard canGoNext else { return }
        if isLastStep {
            submit()
        } else {
            currentStep += 1
        }
    }

    /// false 반환 시 화면 자체를 pop (1단계에서 뒤로)
    @discardableResult
    func goBack() -> Bool {
        guard currentStep > 1 else { return false }
        currentStep -= 1
        return true
    }

    // MARK: - Step 1: 닉네임
    func onNicknameChanged() {
        if case .idle = nicknameState { return }
        nicknameState = .idle
    }

    func checkNickname() {
        let trimmed = nickname.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        nicknameState = .loading
        Task {
            do {
                let result = try await userService.checkNickname(trimmed)
                switch result.code {
                case "SUCCESS":   nicknameState = .available
                case "DUPLICATE": nicknameState = .duplicate
                case "BAD_WORD":  nicknameState = .badWord
                default:          nicknameState = .error(result.message)
                }
            } catch {
                nicknameState = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - Step 1: 프로필 사진 (카메라 촬영 결과)
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

    // MARK: - Step 1: 프로필 사진 (PhotosPicker)
    func consumePhotosPickerItem(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            do {
                let image = try await PhotosPickerImageLoader.uiImage(from: item)
                selectedImage = image
                isUsingDefaultImage = false
                photoImportError = nil
            } catch {
                photoImportError = error.localizedDescription
            }
        }
    }

    // MARK: - Step 2: 인생책 검색/선택
    func onSearchQueryChanged() {
        searchTask?.cancel()
        let keyword = searchQuery.trimmingCharacters(in: .whitespaces)
        guard keyword.count >= 1 else {
            searchResults = []
            isSearching = false
            return
        }
        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 디바운스 0.3s
            guard !Task.isCancelled else { return }
            do {
                let books = try await groupService.searchBooks(keyword: keyword)
                guard !Task.isCancelled else { return }
                searchResults = books
            } catch {
                searchResults = []
            }
            isSearching = false
        }
    }

    func selectBook(_ book: BookItem, at slot: Int) {
        guard lifeBooks.indices.contains(slot) else { return }
        // 이미 선택된 책 중복 방지
        guard !lifeBooks.compactMap({ $0?.isbn13 }).contains(book.isbn13) else { return }
        lifeBooks[slot] = book
    }

    /// 안드로이드 setLifeBook 대응 — 빈 슬롯을 누르면 위치와 무관하게 첫 빈 칸을 채우고,
    /// 채워진 슬롯(수정)이면 해당 슬롯을 교체한다.
    func setLifeBook(_ book: BookItem, at slotIndex: Int) {
        guard lifeBooks.indices.contains(slotIndex) else { return }
        // 이미 선택된 책 중복 방지
        guard !lifeBooks.compactMap({ $0?.isbn13 }).contains(book.isbn13) else { return }
        var books = lifeBooks
        let target: Int
        if books[slotIndex] == nil {
            target = books.firstIndex(where: { $0 == nil }) ?? slotIndex
        } else {
            target = slotIndex
        }
        books[target] = book
        lifeBooks = books
    }

    /// 검색 다이얼로그 열 때 초기화
    func clearBookSearch() {
        searchTask?.cancel()
        searchQuery = ""
        searchResults = []
        isSearching = false
    }

    func removeBook(at slot: Int) {
        guard lifeBooks.indices.contains(slot) else { return }
        lifeBooks[slot] = nil
        // null 슬롯을 뒤로 정렬 (안드로이드 동작 대응)
        let filled = lifeBooks.compactMap { $0 }
        lifeBooks = filled + Array(repeating: nil, count: 3 - filled.count)
    }

    var selectedBookCount: Int { lifeBooks.compactMap { $0 }.count }

    // MARK: - Step 3: 기록 방식 토글 (안드로이드 OnbViewModel 로직 대응)
    func toggleMethod(_ method: RecordMethod) {
        isUnknownMethod = false
        if method.isExclusive {
            recordMethods = recordMethods.contains(method) ? [] : [method]
        } else {
            recordMethods.remove(.any)
            if recordMethods.contains(method) {
                recordMethods.remove(method)
            } else {
                recordMethods.insert(method)
            }
        }
    }

    func toggleUnknownMethod() {
        isUnknownMethod.toggle()
        if isUnknownMethod { recordMethods = [] }
    }

    // MARK: - 최종 제출
    private func submit() {
        guard !isSubmitting else { return }
        isSubmitting = true

        Task {
            do {
                let s3Key = try await uploadImageIfNeeded()

                let tags: [String]
                if isUnknownMethod {
                    tags = ["NO_IDEA"]
                } else {
                    tags = recordMethods.map { $0.serverValue }
                }

                let request = OnboardingRequest(
                    name: nickname.trimmingCharacters(in: .whitespaces),
                    gender: gender?.serverValue,
                    birth: birthDate.map(Self.birthFormatter.string(from:)),
                    tags: tags,
                    s3Key: s3Key,
                    userBooks: lifeBooks.compactMap { $0 }.map { OnboardingBook(isbn13: $0.isbn13) },
                    introduction: introduction.trimmingCharacters(in: .whitespaces)
                )

                try await userService.completeOnboarding(request)
                TokenManager.shared.isOnboardingDone = true
                isSubmitting = false
                isCompleted = true
            } catch {
                print("❌ 온보딩 완료 실패: \(error)")
                isSubmitting = false
                toast = .failure(Self.submitFailureToast(for: error))
            }
        }
    }

    /// 제출 실패 원인을 토스트 문구로 변환한다.
    /// 서버가 내려준 실패 사유(UserError)는 그대로 노출하고,
    /// 네트워크·디코딩 예외는 재시도를 유도하는 안내 문구로 대체한다.
    private static func submitFailureToast(for error: Error) -> String {
        if let userError = error as? UserError {
            let message = (userError.errorDescription ?? "").trimmingCharacters(in: .whitespaces)
            return message.isEmpty ? "잠시 후 다시 시도해주세요." : message
        }
        return "네트워크 연결을 확인한 뒤 다시 시도해주세요."
    }

    private func uploadImageIfNeeded() async throws -> String? {
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

    private static let birthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
