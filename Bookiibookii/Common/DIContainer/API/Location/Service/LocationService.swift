import Foundation

// 안드로이드 LocationApi 호출부 대응 — 희망 교환 장소 / 배송지 관리.
final class LocationService {
    private let interceptor: AuthInterceptor

    init(interceptor: AuthInterceptor) {
        self.interceptor = interceptor
    }

    // MARK: - 희망 교환 장소 (직접 교환)

    /// GET /api/mypage/addresses/exchanges
    func fetchExchanges() async throws -> [ExchangeAddress] {
        try await requestList(target: .fetchExchanges)
    }

    /// POST /api/mypage/addresses/exchanges
    func addExchange(_ body: ExchangeAddressRequest) async throws {
        try await requestStatusOnly(target: .addExchange(body))
    }

    /// PUT /api/mypage/addresses/exchanges/{id}
    func updateExchange(id: Int, body: ExchangeAddressRequest) async throws {
        try await requestStatusOnly(target: .updateExchange(id: id, body: body))
    }

    /// DELETE /api/mypage/addresses/exchanges/{id}
    func deleteExchange(id: Int) async throws {
        try await requestStatusOnly(target: .deleteExchange(id: id))
    }

    /// PATCH /api/mypage/addresses/exchanges/{id}/default
    func setDefaultExchange(id: Int) async throws {
        try await requestStatusOnly(target: .setDefaultExchange(id: id))
    }

    // MARK: - 배송지 (택배 교환)

    /// GET /api/mypage/addresses/deliveries
    func fetchDeliveries() async throws -> [DeliveryAddress] {
        try await requestList(target: .fetchDeliveries)
    }

    /// POST /api/mypage/addresses/deliveries
    func addDelivery(_ body: DeliveryAddressRequest) async throws {
        try await requestStatusOnly(target: .addDelivery(body))
    }

    /// PUT /api/mypage/addresses/deliveries/{id}
    func updateDelivery(id: Int, body: DeliveryAddressRequest) async throws {
        try await requestStatusOnly(target: .updateDelivery(id: id, body: body))
    }

    /// DELETE /api/mypage/addresses/deliveries/{id}
    func deleteDelivery(id: Int) async throws {
        try await requestStatusOnly(target: .deleteDelivery(id: id))
    }

    /// PATCH /api/mypage/addresses/deliveries/{id}/default
    func setDefaultDelivery(id: Int) async throws {
        try await requestStatusOnly(target: .setDefaultDelivery(id: id))
    }

    // MARK: - 공통 헬퍼

    private func requestList<T: Decodable>(target: LocationAPITarget) async throws -> [T] {
        let (data, http) = try await interceptor.request(target.asURLRequest())
        guard (200...299).contains(http.statusCode) else {
            throw LocationServiceError.http(http.statusCode)
        }
        let response = try JSONDecoder().decode(ApiResponseDTO<[T]>.self, from: data)
        guard response.isSuccess, let result = response.result else {
            throw LocationServiceError.server(response.message)
        }
        return result
    }

    private func requestStatusOnly(target: LocationAPITarget) async throws {
        let (data, http) = try await interceptor.request(target.asURLRequest())
        guard (200...299).contains(http.statusCode) else {
            if let msg = (try? JSONDecoder().decode(ApiResponseDTO<String>.self, from: data))?.message {
                throw LocationServiceError.server(msg)
            }
            throw LocationServiceError.http(http.statusCode)
        }
    }
}

enum LocationServiceError: LocalizedError {
    case http(Int)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .http(let code): return "서버 오류 (\(code))"
        case .server(let msg): return msg
        }
    }
}
