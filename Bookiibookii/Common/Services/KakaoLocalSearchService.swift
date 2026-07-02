import Foundation

struct KakaoPlaceResult: Identifiable, Equatable {
    let id: String
    let placeName: String
    let address: String
    let zipCode: String?
    let x: Double
    let y: Double
}

/// 카카오 로컬 API — [키워드로 장소 검색](https://developers.kakao.com/docs/ko/local/dev-guide#search-by-keyword)
final class KakaoLocalSearchService {
    enum SearchError: LocalizedError {
        case missingApiKey
        case invalidResponse
        case http(Int)

        var errorDescription: String? {
            switch self {
            case .missingApiKey:
                return "카카오 REST API 키가 설정되지 않았습니다."
            case .invalidResponse:
                return "장소 검색 결과를 불러오지 못했습니다."
            case .http(401):
                return "카카오 REST API 키가 올바르지 않습니다. Config.xcconfig의 KAKAO_REST_API_KEY를 확인해주세요."
            case .http(let code):
                return "장소 검색 실패 (\(code))"
            }
        }
    }

    private let restApiKey: String

    init() {
        restApiKey = (Bundle.main.object(forInfoDictionaryKey: "KAKAO_REST_API_KEY") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    /// GET /v2/local/search/keyword.json
    func searchByKeyword(
        query: String,
        page: Int = 1,
        size: Int = 15
    ) async throws -> [KakaoPlaceResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        guard !restApiKey.isEmpty else { throw SearchError.missingApiKey }

        var components = URLComponents(string: "https://dapi.kakao.com/v2/local/search/keyword.json")!
        components.queryItems = [
            URLQueryItem(name: "query", value: trimmed),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(min(max(size, 1), 15)))
        ]
        guard let url = components.url else { throw SearchError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("KakaoAK \(restApiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw SearchError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw SearchError.http(http.statusCode) }

        let decoded = try JSONDecoder().decode(KakaoKeywordSearchResponse.self, from: data)
        return decoded.documents.compactMap { doc in
            guard let x = Double(doc.x), let y = Double(doc.y) else { return nil }
            let address = doc.roadAddressName?.isEmpty == false ? doc.roadAddressName! : doc.addressName
            let name = doc.placeName?.isEmpty == false ? doc.placeName! : address
            return KakaoPlaceResult(
                id: doc.id ?? UUID().uuidString,
                placeName: name,
                address: address,
                zipCode: nil,
                x: x,
                y: y
            )
        }
    }
}

private struct KakaoKeywordSearchResponse: Decodable {
    let documents: [KakaoKeywordDocument]
}

private struct KakaoKeywordDocument: Decodable {
    let id: String?
    let placeName: String?
    let addressName: String
    let roadAddressName: String?
    let x: String
    let y: String

    enum CodingKeys: String, CodingKey {
        case id
        case placeName = "place_name"
        case addressName = "address_name"
        case roadAddressName = "road_address_name"
        case x, y
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        placeName = try container.decodeIfPresent(String.self, forKey: .placeName)
        addressName = try container.decodeIfPresent(String.self, forKey: .addressName) ?? ""
        roadAddressName = try container.decodeIfPresent(String.self, forKey: .roadAddressName)
        x = try container.decode(String.self, forKey: .x)
        y = try container.decode(String.self, forKey: .y)
    }
}
