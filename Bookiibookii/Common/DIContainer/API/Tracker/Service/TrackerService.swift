import Foundation
import UIKit

// 안드로이드 TrkMainViewModel.loadHostTrackers / loadGuestTrackers 대응.
// ApiResponseDTO<[Dto]> 디코딩 후 도메인 모델(TrackerItem)로 매핑해서 반환.
final class TrackerService {
    private let interceptor: AuthInterceptor
    private let s3: S3UploadClient

    init(interceptor: AuthInterceptor, s3: S3UploadClient = S3UploadClient()) {
        self.interceptor = interceptor
        self.s3 = s3
    }

    /// GET /api/groups/me/trackers/host
    func fetchHostTrackers() async throws -> [TrackerItem] {
        let request = TrackerAPITarget.hostList.asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw TrackerServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<[HostTrackerListItemDto]>.self, from: data)
        guard response.isSuccess else {
            throw TrackerServiceError.server(response.message)
        }
        return (response.result ?? []).map { $0.toTrackerItem() }
    }

    /// GET /api/groups/me/trackers/guest
    func fetchGuestTrackers() async throws -> [TrackerItem] {
        let request = TrackerAPITarget.guestList.asURLRequest()
        let (data, http) = try await interceptor.request(request)
        guard (200...299).contains(http.statusCode) else {
            throw TrackerServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<[GuestTrackerListItemDto]>.self, from: data)
        guard response.isSuccess else {
            throw TrackerServiceError.server(response.message)
        }
        return (response.result ?? []).map { $0.toTrackerItem() }
    }

    // MARK: - 택배 교환 단순 액션

    /// GET /api/groups/{groupId}/tracker
    func fetchDetail(groupId: Int) async throws -> TrackerDetailResponse {
        try await requestDetail(target: .detail(groupId: groupId))
    }

    /// PATCH /api/groups/{groupId}/tracker/reading
    func startReading(groupId: Int) async throws -> TrackerDetailResponse {
        try await requestDetail(target: .startReading(groupId: groupId))
    }

    /// PATCH /api/groups/{groupId}/tracker/extension?days=
    func requestExtension(groupId: Int, days: Int = 3) async throws -> TrackerDetailResponse {
        try await requestDetail(target: .requestExtension(groupId: groupId, days: days))
    }

    /// PATCH /api/groups/{groupId}/tracker/done
    func markDone(groupId: Int) async throws -> TrackerDetailResponse {
        try await requestDetail(target: .markDone(groupId: groupId))
    }

    /// PATCH /api/groups/{groupId}/tracker/reception/verification
    func verifyReception(groupId: Int) async throws -> TrackerDetailResponse {
        try await requestDetail(target: .verifyReception(groupId: groupId))
    }

    /// GET /api/groups/{groupId}/tracker/images/delivery
    func fetchShippingImageURL(groupId: Int) async throws -> URL {
        try await requestImageURL(target: .shippingImage(groupId: groupId))
    }

    /// GET /api/groups/{groupId}/tracker/images/received
    func fetchReceivedImageURL(groupId: Int) async throws -> URL {
        try await requestImageURL(target: .receivedImage(groupId: groupId))
    }

    // MARK: - 공통 디코딩 헬퍼

    private func requestDetail(target: TrackerAPITarget) async throws -> TrackerDetailResponse {
        let (data, http) = try await interceptor.request(target.asURLRequest())
        guard (200...299).contains(http.statusCode) else {
            throw TrackerServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<TrackerDetailResponse>.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw TrackerServiceError.server(response.message)
        }
        return result
    }

    private func requestImageURL(target: TrackerAPITarget) async throws -> URL {
        let (data, http) = try await interceptor.request(target.asURLRequest())
        guard (200...299).contains(http.statusCode) else {
            throw TrackerServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<TrackerImageResponse>.self, from: data)
        guard response.isSuccess,
              let urlString = response.result?.imageUrl,
              let url = URL(string: urlString) else {
            throw TrackerServiceError.server(response.message)
        }
        return url
    }

    /// POST /api/groups/{groupId}/tracker/images/presigned-url
    private func fetchPresignedUrl(groupId: Int) async throws -> TrackerPresignedUrlResponse {
        let (data, http) = try await interceptor.request(
            TrackerAPITarget.presignedUrl(groupId: groupId).asURLRequest()
        )
        guard (200...299).contains(http.statusCode) else {
            throw TrackerServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<TrackerPresignedUrlResponse>.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw TrackerServiceError.server(response.message)
        }
        return result
    }

    // MARK: - 업로드 묶음 (presignedUrl → S3 PUT → 도메인 API)

    /// POST /api/groups/{groupId}/tracker/delivery (이미지 업로드 포함)
    func startShipping(
        groupId: Int,
        deliveryCompany: String,
        trackingNumber: String,
        image: UIImage
    ) async throws -> TrackerDetailResponse {
        let s3Key = try await uploadImage(groupId: groupId, image: image)
        let body = TrackerShippingStartRequest(
            deliveryCompany: deliveryCompany,
            trackingNumber: trackingNumber,
            s3Key: s3Key
        )
        return try await requestDetail(
            target: .startShipping(groupId: groupId, body: body)
        )
    }

    /// PATCH /api/groups/{groupId}/tracker/reception (이미지 업로드 포함)
    func registerReceipt(
        groupId: Int,
        image: UIImage
    ) async throws -> TrackerDetailResponse {
        let s3Key = try await uploadImage(groupId: groupId, image: image)
        let body = TrackerReceiveRequest(s3Key: s3Key)
        return try await requestDetail(
            target: .registerReceipt(groupId: groupId, body: body)
        )
    }

    private func uploadImage(groupId: Int, image: UIImage) async throws -> String {
        guard let jpeg = image.jpegData(compressionQuality: 0.85) else {
            throw TrackerServiceError.imageEncodingFailed
        }
        let presigned = try await fetchPresignedUrl(groupId: groupId)
        try await s3.put(data: jpeg, to: presigned.presignedPutUrl, contentType: "image/jpeg")
        return presigned.s3Key
    }
}

enum TrackerServiceError: LocalizedError {
    case http(Int)
    case server(String)
    case imageEncodingFailed

    var errorDescription: String? {
        switch self {
        case .http(let code):       return "서버 오류 (\(code))"
        case .server(let msg):      return msg
        case .imageEncodingFailed:  return "이미지를 변환하지 못했습니다."
        }
    }
}
