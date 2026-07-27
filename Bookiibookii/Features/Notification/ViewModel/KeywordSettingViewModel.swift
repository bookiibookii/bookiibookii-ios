import Foundation
import Combine

@MainActor
final class KeywordSettingViewModel: ObservableObject {
    static let maxCount = 10
    static let maxLength = 10

    @Published private(set) var items: [KeywordItemDto] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isAdding = false
    @Published var toastMessage: String? = nil

    private let service: KeywordService

    init(service: KeywordService) { self.service = service }

    // MARK: - 로드

    func onAppear() async {
        await load()
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            // 안드로이드와 동일하게 LATEST 고정
            let result = try await service.fetchKeywords(sort: .latest)
            items = result.keywordList
        } catch let KeywordServiceError.server(msg) {
            toastMessage = msg
        } catch {
            // 네트워크/파싱 실패는 토스트 없이 조용히 무시(안드로이드 로직 기준)
        }
    }

    // MARK: - 추가

    /// 안드로이드 tryAddKeyword()와 동일한 검증 순서.
    /// - 빈 값: 무반응
    /// - 10자 초과: 토스트
    /// - 10개 초과: 토스트
    /// - 중복: 토스트
    /// - 성공: 목록 재조회 + 등록 토스트
    @discardableResult
    func addKeyword(_ raw: String) async -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        guard !isAdding else { return false }

        if trimmed.count > Self.maxLength {
            toastMessage = "키워드는 최대 \(Self.maxLength)자까지 입력할 수 있어요."
            return false
        }
        if items.count >= Self.maxCount {
            toastMessage = "키워드는 최대 \(Self.maxCount)개까지만 등록 가능합니다."
            return false
        }
        if items.contains(where: { $0.content == trimmed }) {
            toastMessage = "이미 등록된 키워드입니다."
            return false
        }

        isAdding = true
        defer { isAdding = false }

        do {
            _ = try await service.createKeyword(content: trimmed)
            await load()
            toastMessage = "키워드가 등록되었습니다."
            return true
        } catch let KeywordServiceError.server(msg) {
            toastMessage = msg
            return false
        } catch {
            toastMessage = "키워드 등록에 실패했습니다."
            return false
        }
    }

    // MARK: - 삭제

    func delete(_ keywordId: Int) async {
        do {
            try await service.deleteKeyword(keywordId: keywordId)
            await load()
        } catch let KeywordServiceError.server(msg) {
            toastMessage = msg
        } catch {
            toastMessage = "키워드 삭제에 실패했습니다."
        }
    }

    // MARK: - 유효성 (입력창 필터)

    /// 허용: 한글/영문/숫자/?, !, ,, ., _, -. 공백/이모지 등은 입력 자체 차단.
    static func sanitizeInput(_ input: String) -> String {
        let allowed = CharacterSet(charactersIn:
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789?!,._-"
        ).union(CharacterSet(charactersIn: "가"..."힣"))
        .union(CharacterSet(charactersIn: "ㄱ"..."ㅎ"))
        .union(CharacterSet(charactersIn: "ㅏ"..."ㅣ"))

        return input.unicodeScalars.filter { allowed.contains($0) }.map(String.init).joined()
    }
}
