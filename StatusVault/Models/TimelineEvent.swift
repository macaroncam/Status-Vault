import Foundation
import SwiftData

@Model
final class TimelineEvent {
    var id: UUID
    var eventDate: Date
    var eventType: EventType
    var eventDescription: String
    var documentID: String? // Reference to Document
    var metadata: String? // JSON string for additional data

    init(eventDate: Date, eventType: EventType, eventDescription: String, documentID: String? = nil) {
        self.id = UUID()
        self.eventDate = eventDate
        self.eventType = eventType
        self.eventDescription = eventDescription
        self.documentID = documentID
    }
}

enum EventType: String, Codable {
    case documentAdded = "Document Added"
    case documentExpired = "Document Expired"
    case statusChanged = "Status Changed"
    case expirationWarning = "Expiration Warning"
    case documentSuperseded = "Document Superseded"

    var icon: String {
        switch self {
        case .documentAdded: return "plus.circle.fill"
        case .documentExpired: return "exclamationmark.triangle.fill"
        case .statusChanged: return "arrow.triangle.2.circlepath"
        case .expirationWarning: return "clock.fill"
        case .documentSuperseded: return "arrow.turn.up.right"
        }
    }
}
