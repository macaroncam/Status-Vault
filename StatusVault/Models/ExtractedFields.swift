import Foundation
import SwiftData

@Model
final class ExtractedFields {
    // Common fields
    var fullName: String?
    var documentNumber: String?
    var issuedDate: Date?
    var expirationDate: Date?
    var countryOfIssuance: String?

    // I-20 specific
    var sevisID: String?
    var schoolName: String?
    var degreeLevel: String?
    var majorField: String?
    var programEndDate: Date?

    // EAD specific
    var eadCategory: String?
    var validFrom: Date?
    var validUntil: Date?

    // Passport specific
    var passportNumber: String?
    var nationality: String?
    var dateOfBirth: Date?
    var placeOfBirth: String?

    // Visa specific
    var visaType: String?
    var visaNumber: String?
    var entriesAllowed: String?

    // I-94 specific
    var admissionNumber: String?
    var classOfAdmission: String?
    var admitUntilDate: Date?

    // I-797 specific
    var receiptNumber: String?
    var caseType: String?
    var petitionerName: String?
    var beneficiaryName: String?

    // Raw OCR text for debugging
    var rawOCRText: String?

    init() {
        // Empty initializer
    }
}
