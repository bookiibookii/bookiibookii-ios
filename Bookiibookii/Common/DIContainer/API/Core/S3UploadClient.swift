import Foundation

/// presigned URL로 raw PUT 업로드 전용 (도메인 무관 공통 헬퍼).
/// AuthInterceptor 우회 — presigned URL은 자체 서명을 가지고 있어 Authorization 헤더 불필요.
struct S3UploadClient {
    func put(data: Data, to urlString: String, contentType: String) async throws {
        guard let url = URL(string: urlString) else {
            throw S3UploadError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.upload(for: request, from: data)

        guard let http = response as? HTTPURLResponse else {
            throw S3UploadError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw S3UploadError.unexpectedStatus(http.statusCode)
        }
    }
}

enum S3UploadError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unexpectedStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:                return "업로드 URL이 올바르지 않습니다."
        case .invalidResponse:           return "업로드 응답이 비정상입니다."
        case .unexpectedStatus(let c):   return "이미지 업로드 실패 (\(c))"
        }
    }
}
