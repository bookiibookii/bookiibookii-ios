import Foundation

/// 도서 요청 실패의 원본 상태와 사유를 서비스에서 화면까지 전달한다.
struct BookAPIError: LocalizedError {
    let statusCode: Int
    let code: String
    let message: String

    var errorDescription: String? {
        message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "도서 요청에 실패했어요. 잠시 후 다시 시도해주세요."
            : message
    }

    static func decode(from data: Data, statusCode: Int) -> BookAPIError? {
        guard let response = try? JSONDecoder().decode(SimpleResponse.self, from: data),
              !(200...299).contains(statusCode) || !response.isSuccess,
              response.code.hasPrefix("BOOK") else { return nil }
        return BookAPIError(statusCode: statusCode, code: response.code, message: response.message)
    }

    static func throwIfPresent(in data: Data, statusCode: Int) throws {
        if let error = decode(from: data, statusCode: statusCode) { throw error }
    }
}
