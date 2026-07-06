import Foundation

struct FaqItemDto: Decodable, Identifiable, Equatable {
    let id: Int
    let question: String
    let answer: String
    let displayOrder: Int?

    enum CodingKeys: String, CodingKey {
        case id, question, answer, displayOrder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let intId = try? container.decode(Int.self, forKey: .id) {
            id = intId
        } else {
            let longId = try container.decode(Int64.self, forKey: .id)
            id = Int(longId)
        }
        question = try container.decode(String.self, forKey: .question)
        answer = try container.decode(String.self, forKey: .answer)
        displayOrder = try container.decodeIfPresent(Int.self, forKey: .displayOrder)
    }
}

struct FaqItem: Identifiable, Equatable {
    let id: Int
    let question: String
    let answer: String

    init(dto: FaqItemDto) {
        id = dto.id
        question = dto.question
        answer = dto.answer
    }
}
