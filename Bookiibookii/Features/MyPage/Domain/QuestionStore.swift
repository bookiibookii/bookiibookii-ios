import Foundation

struct QuestionItem: Identifiable, Codable, Equatable {
    enum Status: String, Codable { case waiting, answered }
    let id: Int
    let author: String
    let createdAt: Date
    let title: String
    let content: String
    let status: Status
    let answerAuthor: String?
    let answerDate: Date?
    let answerContent: String?
}

struct QuestionCreatePayload {
    let title: String
    let content: String
}

extension QuestionItem {
    init(dto: InquiryListItemDto) {
        self.id = dto.inquiryId
        self.author = dto.nickname
        self.createdAt = dto.createdAt
        self.title = dto.title
        self.content = dto.content
        self.status = dto.supportStatus.uppercased() == "RESOLVED" ? .answered : .waiting
        self.answerAuthor = dto.supportStatus.uppercased() == "RESOLVED" ? "부키부키 팀" : nil
        self.answerDate = dto.resolvedAt
        self.answerContent = dto.adminReply
    }
}
