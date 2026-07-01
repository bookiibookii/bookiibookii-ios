import Foundation

struct KakaoPlaceResult: Identifiable, Equatable {
    let id: String
    let placeName: String
    let address: String
    let zipCode: String?
    let x: Double
    let y: Double
}

/// 카카오 로컬 API 장소 검색 — [참고](https://bongra.tistory.com/75)
final class KakaoLocalSearchService {
    enum SearchError: LocalizedError {
        case missingApiKey
        case invalidResponse
        case http(Int)

        var errorDescription: String? {
            switch self {
            case .missingApiKey: return "카카오 API 키가 설정되지 않았습니다."
            case .invalidResponse: return "장소 검색 결과를 불러오지 못했습니다."
            case .http(401): return "카카오 REST API 키가 올바르지 않습니다. Config.xcconfig의 KAKAO_REST_API_KEY를 확인해주세요."
        case .http(let code): return "장소 검색 실패 (\(code))"
            }
        }
    }

    private let restApiKey: String

    init() {
        let rest = Bundle.main.object(forInfoDictionaryKey: "KAKAO_REST_API_KEY") as? String
        let native = Bundle.main.object(forInfoDictionaryKey: "KAKAO_NATIVE_APP_KEY") as? String
        restApiKey = [rest, native].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty }) ?? ""
    }

    func searchPlaces(query: String) async throws -> [KakaoPlaceResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        guard !restApiKey.isEmpty else { throw SearchError.missingApiKey }

        let addressResults = try await requestAddressSearch(query: trimmed)
        if !addressResults.isEmpty {
            var merged: [KakaoPlaceResult] = []
            for item in addressResults.prefix(5) {
                let keywordResults = try await requestKeywordSearch(query: item.address)
                if keywordResults.isEmpty {
                    merged.append(item)
                } else {
                    merged.append(contentsOf: keywordResults)
                }
            }
            return deduplicate(merged)
        }

        return try await requestKeywordSearch(query: trimmed)
    }

    private func requestAddressSearch(query: String) async throws -> [KakaoPlaceResult] {
        let url = try makeURL(path: "/v2/local/search/address.json", query: query)
        let response = try await request(url: url)
        return response.documents.compactMap { doc in
            guard let x = Double(doc.x), let y = Double(doc.y) else { return nil }
            let road = doc.roadAddress?.addressName ?? doc.addressName
            return KakaoPlaceResult(
                id: "address-\(doc.addressName)-\(doc.x)-\(doc.y)",
                placeName: doc.addressName,
                address: road,
                zipCode: doc.roadAddress?.zoneNo,
                x: x,
                y: y
            )
        }
    }

    private func requestKeywordSearch(query: String) async throws -> [KakaoPlaceResult] {
        let url = try makeURL(path: "/v2/local/search/keyword.json", query: query)
        let response = try await request(url: url)
        return response.documents.compactMap { doc in
            guard let x = Double(doc.x), let y = Double(doc.y) else { return nil }
            let address = doc.roadAddressName?.isEmpty == false ? doc.roadAddressName! : doc.addressName
            let name = doc.placeName?.isEmpty == false ? doc.placeName! : address
            return KakaoPlaceResult(
                id: "keyword-\(doc.id ?? UUID().uuidString)",
                placeName: name,
                address: address,
                zipCode: nil,
                x: x,
                y: y
            )
        }
    }

    private func makeURL(path: String, query: String) throws -> URL {
        var components = URLComponents(string: "https://dapi.kakao.com\(path)")!
        components.queryItems = [URLQueryItem(name: "query", value: query)]
        guard let url = components.url else { throw SearchError.invalidResponse }
        return url
    }

    private func request(url: URL) async throws -> KakaoLocalSearchResponse {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("KakaoAK \(restApiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw SearchError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw SearchError.http(http.statusCode) }

        return try JSONDecoder().decode(KakaoLocalSearchResponse.self, from: data)
    }

    private func deduplicate(_ items: [KakaoPlaceResult]) -> [KakaoPlaceResult] {
        var seen = Set<String>()
        return items.filter { item in
            let key = "\(item.x)-\(item.y)-\(item.address)"
            return seen.insert(key).inserted
        }
    }
}

private struct KakaoLocalSearchResponse: Decodable {
    let documents: [KakaoLocalDocument]
}

private struct KakaoLocalDocument: Decodable {
    let id: String?
    let addressName: String
    let placeName: String?
    let roadAddressName: String?
    let x: String
    let y: String
    let roadAddress: KakaoRoadAddress?

    enum CodingKeys: String, CodingKey {
        case id
        case addressName = "address_name"
        case placeName = "place_name"
        case roadAddressName = "road_address_name"
        case x, y
        case roadAddress = "road_address"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        addressName = try container.decodeIfPresent(String.self, forKey: .addressName) ?? ""
        placeName = try container.decodeIfPresent(String.self, forKey: .placeName)
        roadAddressName = try container.decodeIfPresent(String.self, forKey: .roadAddressName)
        x = try container.decode(String.self, forKey: .x)
        y = try container.decode(String.self, forKey: .y)
        roadAddress = try container.decodeIfPresent(KakaoRoadAddress.self, forKey: .roadAddress)
    }
}

private struct KakaoRoadAddress: Decodable {
    let addressName: String
    let zoneNo: String?

    enum CodingKeys: String, CodingKey {
        case addressName = "address_name"
        case zoneNo = "zone_no"
    }
}
