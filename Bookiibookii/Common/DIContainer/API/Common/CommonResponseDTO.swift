import Foundation

/// 서버 공통 응답 포맷.
struct ApiResponseDTO<T: Decodable>: Decodable {
    let isSuccess: Bool
    let code: String
    let message: String
    let result: T?
}

struct APIErrorResponseDTO: Decodable {
    let message: String
}

/// `result: null` 또는 빈 객체 응답 디코딩용.
struct EmptyDTO: Decodable {}
