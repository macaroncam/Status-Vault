import Foundation
import SwiftData

class StatusEngine {
    static let shared = StatusEngine()

    private init() {}

    func calculateCurrentStatus(documents: [Document]) -> StatusSnapshot {
        let activeDocuments = documents.filter { $0.state == .active || $0.state == .expiringSoon }

        var canWork = false
        var canStudy = false
        var mustMaintainStatus = false
        var workExpiryDate: Date?
        var studyExpiryDate: Date?
        var warnings: [String] = []
        var currentStatus = "Unknown"

        // Check for work authorization
        let eadDocs = activeDocuments.filter { $0.type == .ead }
        if let latestEAD = eadDocs.sorted(by: { ($0.expiryDate ?? Date.distantPast) > ($1.expiryDate ?? Date.distantPast) }).first {
            canWork = true
            workExpiryDate = latestEAD.expiryDate

            if latestEAD.state == .expiringSoon {
                warnings.append("EAD card expiring soon")
            }
        }

        // Check for study authorization
        let i20Docs = activeDocuments.filter { $0.type == .i20 }
        if let latestI20 = i20Docs.sorted(by: { ($0.expiryDate ?? Date.distantPast) > ($1.expiryDate ?? Date.distantPast) }).first {
            canStudy = true
            mustMaintainStatus = true
            studyExpiryDate = latestI20.expiryDate
            currentStatus = "F-1 Student"

            if latestI20.state == .expiringSoon {
                warnings.append("I-20 expiring soon")
            }
        }

        // Check for visa status
        let visaDocs = activeDocuments.filter { $0.type == .visa }
        if let latestVisa = visaDocs.sorted(by: { ($0.expiryDate ?? Date.distantPast) > ($1.expiryDate ?? Date.distantPast) }).first {
            if let fields = latestVisa.extractedFields, let visaType = fields.visaType {
                currentStatus = "\(visaType) Visa Holder"
            }

            if latestVisa.state == .expiringSoon {
                warnings.append("Visa expiring soon")
            }
        }

        // Check for expired documents
        let expiredDocs = documents.filter { $0.state == .expired }
        if !expiredDocs.isEmpty {
            warnings.append("\(expiredDocs.count) document(s) expired")
        }

        let activeDocIDs = activeDocuments.map { $0.id.uuidString }

        return StatusSnapshot(
            currentStatus: currentStatus,
            canWork: canWork,
            canStudy: canStudy,
            mustMaintainStatus: mustMaintainStatus,
            warnings: warnings,
            activeDocuments: activeDocIDs
        )
    }

    func generateTimelineEvents(for document: Document) -> [TimelineEvent] {
        var events: [TimelineEvent] = []

        // Document added event
        events.append(TimelineEvent(
            eventDate: document.createdAt,
            eventType: .documentAdded,
            eventDescription: "\(document.type.rawValue) added to vault",
            documentID: document.id.uuidString
        ))

        // Expiration warning event (30 days before)
        if let expiryDate = document.expiryDate {
            if let warningDate = Calendar.current.date(byAdding: .day, value: -30, to: expiryDate) {
                events.append(TimelineEvent(
                    eventDate: warningDate,
                    eventType: .expirationWarning,
                    eventDescription: "\(document.type.rawValue) expiring in 30 days",
                    documentID: document.id.uuidString
                ))
            }

            // Expiration event
            events.append(TimelineEvent(
                eventDate: expiryDate,
                eventType: .documentExpired,
                eventDescription: "\(document.type.rawValue) expired",
                documentID: document.id.uuidString
            ))
        }

        // Superseded event
        if let supersededDate = document.supersededDate {
            events.append(TimelineEvent(
                eventDate: supersededDate,
                eventType: .documentSuperseded,
                eventDescription: "\(document.type.rawValue) superseded by newer document",
                documentID: document.id.uuidString
            ))
        }

        return events
    }
}
