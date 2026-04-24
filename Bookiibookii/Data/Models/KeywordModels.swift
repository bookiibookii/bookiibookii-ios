import Foundation

// 안드로이드 KeywordModel.kt 대응.

enum KeywordSort: String {
    case latest = "LATEST"
    case alphabetical = "ALPHABETICAL"
}

struct KeywordItemDto: Decodable, Identifiable, Equatable {
    let keywordId: Int
    let content: String

    var id: Int { keywordId }
}

struct KeywordListResultDto: Decodable, Equatable {
    let keywordSort: String
    let keywordNumber: Int
    let keywordList: [KeywordItemDto]
}

struct KeywordCreateRequest: Encodable {
    let content: String
}

struct KeywordCreateResultDto: Decodable, Equatable {
    let keywordId: Int
    let content: String
}
