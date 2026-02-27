import Foundation
import SwiftData

@Model
final class StatusSnapshot {
    var id: UUID
    var timestamp: Date
    var currentStatus: String
    var canWork: Bool
    var workExpiryDate: Date?
    var canStudy: Bool
    var studyExpiryDate: Date?
    var mustMaintainStatus: Bool
    var warnings: [String]
    var activeDocuments: [String] // Document IDs as strings

    init(currentStatus: String, canWork: Bool, canStudy: Bool, mustMaintainStatus: Bool, warnings: [String] = [], activeDocuments: [String] = []) {
        self.id = UUID()
        self.timestamp = Date()
        self.currentStatus = currentStatus
        self.canWork = canWork
        self.canStudy = canStudy
        self.mustMaintainStatus = mustMaintainStatus
        self.warnings = warnings
        self.activeDocuments = activeDocuments
    }
}
