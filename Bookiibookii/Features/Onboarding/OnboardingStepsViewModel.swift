import Foundation
import Combine

// MARK: - Step 1: 독서 취향 장르 (ReadingPreference 대응)

enum StepGenre: CaseIterable, Hashable {
    case econBiz, sciIt, novelGenre, poemEssay
    case homeHobby, artCulture, humanHistory
    case selfDev, polSoc, esc

    var displayName: String {
        switch self {
        case .econBiz:      return "경제/경영"
        case .sciIt:        return "과학/IT"
        case .novelGenre:   return "소설/장르"
        case .poemEssay:    return "시/에세이"
        case .homeHobby:    return "가정/취미"
        case .artCulture:   return "예술/문화"
        case .humanHistory: return "인문/역사"
        case .selfDev:      return "자기계발"
        case .polSoc:       return "정치/사회"
        case .esc:          return "기타"
        }
    }

    var serverValue: String {
        switch self {
        case .econBiz:      return "ECON_BIZ"
        case .sciIt:        return "SCI_IT"
        case .novelGenre:   return "NOVEL_GENRE"
        case .poemEssay:    return "POEM_ESSAY"
        case .homeHobby:    return "HOME_HOBBY"
        case .artCulture:   return "ART_CULTURE"
        case .humanHistory: return "HUMAN_HISTORY"
        case .selfDev:      return "SELF_DEV"
        case .polSoc:       return "POL_SOC"
        case .esc:          return "ESC"
        }
    }

    // 피그마 기준 행 구성 (row_1, row_2, row_3)
    static let rows: [[StepGenre]] = [
        [.econBiz, .sciIt, .novelGenre, .poemEssay],
        [.homeHobby, .artCulture, .humanHistory],
        [.selfDev, .polSoc, .esc]
    ]
}

// MARK: - Step 2: 독서 기록 방식 (RecordMethod 대응)

enum StepMethod: CaseIterable, Hashable {
    case memo, postit, photo, focus

    var displayName: String {
        switch self {
        case .memo:   return "펜으로 밑줄을 긋고 메모해요!"
        case .postit: return "포스트잇이나 인덱스를 활용해요!"
        case .photo:  return "사진을 찍어 기록해요!"
        case .focus:  return "기록보다는 읽는 것에 집중해요!"
        }
    }

    var iconSystemName: String {
        switch self {
        case .memo:   return "pencil"
        case .postit: return "bookmark.fill"
        case .photo:  return "camera"
        case .focus:  return "book.closed"
        }
    }

    var serverValue: String {
        switch self {
        case .memo:   return "MEMO"
        case .postit: return "POSTIT"
        case .photo:  return "CLEAN"
        case .focus:  return "CLEAN"
        }
    }
}

// MARK: - Step 3: 독서 페이스 (ReadingPace 대응)

enum StepPace: CaseIterable, Hashable {
    case fast, normal, slow, unknown

    var badge: String? {
        switch self {
        case .fast:    return "약 3일"
        case .normal:  return "약 1주"
        case .slow:    return "약 1개월"
        case .unknown: return nil
        }
    }

    var displayName: String {
        switch self {
        case .fast:    return "앉은 자리에서 뚝딱!"
        case .normal:  return "매일매일 꾸준히"
        case .slow:    return "틈날 때마다 여유롭게"
        case .unknown: return "아직 내 속도를 모르겠어요"
        }
    }

    var serverValue: String {
        switch self {
        case .fast:    return "FAST"
        case .normal:  return "NORMAL"
        case .slow:    return "SLOW"
        case .unknown: return "UNKNOWN"
        }
    }
}

// MARK: - ViewModel

final class OnboardingStepsViewModel: ObservableObject {

    // MARK: Step 내비게이션
    @Published var currentStep: Int = 1

    // MARK: Step 1: 장르 (최대 3개 다중 선택)
    @Published var selectedGenres: Set<StepGenre> = []

    // MARK: Step 2: 독서 기록 방식
    @Published var selectedMethods: Set<StepMethod> = []
    @Published var isAllMethodsSelected: Bool = false
    @Published var isMethodUnknown: Bool = false

    // MARK: Step 3: 독서 페이스 (단일 선택)
    @Published var selectedPace: StepPace? = nil

    // MARK: 완료 상태
    @Published var isCompleting: Bool = false
    @Published var isCompleted: Bool = false

    let name: String
    let s3Key: String?
    private let userService: UserService

    init(name: String, s3Key: String?, userService: UserService) {
        self.name = name
        self.s3Key = s3Key
        self.userService = userService
    }

    // MARK: - 단계별 다음 버튼 활성화 조건

    var canGoNext: Bool {
        switch currentStep {
        case 1: return !selectedGenres.isEmpty
        case 2: return !selectedMethods.isEmpty || isAllMethodsSelected || isMethodUnknown
        case 3: return selectedPace != nil
        default: return false
        }
    }

    // MARK: - 다음 단계 또는 완료

    func goNext() {
        if currentStep < 3 {
            currentStep += 1
        } else {
            completeOnboarding()
        }
    }

    // false 반환 시 프로필 화면으로 pop
    @discardableResult
    func goBack() -> Bool {
        guard currentStep > 1 else { return false }
        currentStep -= 1
        return true
    }

    // MARK: - Step 1 장르 토글 (최대 3개)

    func toggleGenre(_ genre: StepGenre) {
        if selectedGenres.contains(genre) {
            selectedGenres.remove(genre)
        } else {
            guard selectedGenres.count < 3 else { return }
            selectedGenres.insert(genre)
        }
    }

    // MARK: - Step 2 기록 방식 토글

    func toggleMethod(_ method: StepMethod) {
        isMethodUnknown = false
        isAllMethodsSelected = false
        if selectedMethods.contains(method) {
            selectedMethods.remove(method)
        } else {
            selectedMethods.insert(method)
        }
    }

    func toggleAllMethods() {
        isMethodUnknown = false
        let all = Set(StepMethod.allCases)
        if selectedMethods == all {
            selectedMethods = []
            isAllMethodsSelected = false
        } else {
            selectedMethods = all
            isAllMethodsSelected = true
        }
    }

    func toggleMethodUnknown() {
        isMethodUnknown.toggle()
        if isMethodUnknown {
            selectedMethods = []
            isAllMethodsSelected = false
        }
    }

    // MARK: - Step 3 페이스 단일 선택

    func selectPace(_ pace: StepPace) {
        selectedPace = (selectedPace == pace) ? nil : pace
    }

    // MARK: - 온보딩 최종 API 호출

    private func completeOnboarding() {
        guard !isCompleting else { return }
        isCompleting = true

        Task {
            do {
                let genreValues = selectedGenres.map { $0.serverValue }

                let methodValues: [String]
                if isMethodUnknown {
                    methodValues = ["UNKNOWN"]
                } else {
                    methodValues = Array(Set(selectedMethods.map { $0.serverValue }))
                }

                let speedValue = selectedPace?.serverValue ?? "UNKNOWN"

                let tags: [OnboardingTag] = [
                    OnboardingTag(type: "GENRE", value: genreValues),
                    OnboardingTag(type: "METHOD", value: methodValues),
                    OnboardingTag(type: "SPEED", value: [speedValue])
                ]

                let request = OnboardingRequest(name: name, tags: tags, s3Key: s3Key)
                try await userService.completeOnboarding(request)

                await MainActor.run {
                    self.isCompleting = false
                    self.isCompleted = true
                }
            } catch {
                print("❌ 온보딩 완료 실패: \(error)")
                await MainActor.run { self.isCompleting = false }
            }
        }
    }
}
