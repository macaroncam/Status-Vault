import Foundation
import SwiftData

class DocumentLifecycleEngine {
    static let shared = DocumentLifecycleEngine()

    private init() {}

    func updateDocumentStates(documents: [Document]) {
        let now = Date()
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: now)!

        for document in documents {
            guard document.state != .superseded else { continue }

            if let expiryDate = document.expiryDate {
                if expiryDate < now {
                    document.state = .expired
                } else if expiryDate < thirtyDaysFromNow {
                    document.state = .expiringSoon
                } else {
                    document.state = .active
                }
            }

            document.updatedAt = Date()
        }
    }

    func getExpiringDocuments(documents: [Document], withinDays days: Int) -> [Document] {
        let now = Date()
        guard let futureDate = Calendar.current.date(byAdding: .day, value: days, to: now) else {
            return []
        }

        return documents.filter { document in
            guard let expiryDate = document.expiryDate else { return false }
            return expiryDate > now && expiryDate <= futureDate
        }
    }

    func getActiveDocuments(documents: [Document]) -> [Document] {
        return documents.filter { $0.state == .active || $0.state == .expiringSoon }
    }

    func supersede(document: Document, by newDocument: Document) {
        document.state = .superseded
        document.supersededDate = Date()
        document.updatedAt = Date()
    }
}
