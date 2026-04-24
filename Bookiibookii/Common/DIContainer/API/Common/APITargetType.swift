import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

protocol APITargetType {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem] { get }
    var body: Data? { get }
    var headers: [String: String] { get }
}

extension APITargetType {
    var baseURL: URL { URL(string: API.baseURL)! }
    var queryItems: [URLQueryItem] { [] }
    var body: Data? { nil }
    var headers: [String: String] { [:] }

    func asURLRequest() -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        var request = URLRequest(url: components.url!)
        request.httpMethod = method.rawValue
        request.httpBody = body
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return request
    }
}
