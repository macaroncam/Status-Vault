import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id: UUID
    var role: MessageRole
    var content: String
    var timestamp: Date
    var conversationID: String // Group messages into conversations

    init(role: MessageRole, content: String, conversationID: String = "default") {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.conversationID = conversationID
    }
}

enum MessageRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
}
