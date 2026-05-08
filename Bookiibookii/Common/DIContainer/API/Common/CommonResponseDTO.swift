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

/// `result` 필드가 없는(또는 무시해도 되는) 응답을 디코딩할 때 사용.
struct EmptyResult: Decodable {}
