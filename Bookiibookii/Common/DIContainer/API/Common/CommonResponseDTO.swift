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
