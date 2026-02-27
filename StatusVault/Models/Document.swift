import Foundation
import SwiftData

@Model
final class Document {
    var id: UUID
    var type: DocumentType
    var state: DocumentState
    var effectiveDate: Date?
    var expiryDate: Date?
    var supersededDate: Date?
    var encryptedImagePath: String
    var extractedFields: ExtractedFields?
    var createdAt: Date
    var updatedAt: Date

    init(type: DocumentType, encryptedImagePath: String) {
        self.id = UUID()
        self.type = type
        self.state = .active
        self.encryptedImagePath = encryptedImagePath
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum DocumentType: String, Codable, CaseIterable {
    case i20 = "I-20"
    case ead = "EAD"
    case passport = "Passport"
    case visa = "Visa"
    case i94 = "I-94"
    case i797 = "I-797"
    case other = "Other"

    var icon: String {
        switch self {
        case .i20: return "doc.text.fill"
        case .ead: return "person.text.rectangle.fill"
        case .passport: return "book.closed.fill"
        case .visa: return "airplane"
        case .i94: return "doc.fill"
        case .i797: return "envelope.fill"
        case .other: return "doc"
        }
    }

    var color: String {
        switch self {
        case .i20: return "blue"
        case .ead: return "green"
        case .passport: return "red"
        case .visa: return "purple"
        case .i94: return "orange"
        case .i797: return "indigo"
        case .other: return "gray"
        }
    }
}

enum DocumentState: String, Codable {
    case active = "Active"
    case expired = "Expired"
    case expiringSoon = "Expiring Soon"
    case superseded = "Superseded"

    var color: String {
        switch self {
        case .active: return "green"
        case .expired: return "red"
        case .expiringSoon: return "orange"
        case .superseded: return "gray"
        }
    }
}
