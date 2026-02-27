import Foundation

class DocumentTypeDetector {
    static let shared = DocumentTypeDetector()

    private init() {}

    func detectType(from ocrText: String) -> DocumentType {
        let lowercased = ocrText.lowercased()

        // I-20 detection
        if lowercased.contains("sevis") || lowercased.contains("i-20") || lowercased.contains("certificate of eligibility") {
            return .i20
        }

        // EAD detection
        if lowercased.contains("employment authorization") || lowercased.contains("ead") || lowercased.contains("i-766") {
            return .ead
        }

        // Passport detection
        if lowercased.contains("passport") {
            return .passport
        }

        // Visa detection
        if lowercased.contains("visa") && !lowercased.contains("immigrant visa") {
            return .visa
        }

        // I-94 detection
        if lowercased.contains("i-94") || lowercased.contains("arrival/departure") {
            return .i94
        }

        // I-797 detection
        if lowercased.contains("i-797") || lowercased.contains("notice of action") || lowercased.contains("uscis") {
            return .i797
        }

        return .other
    }
}
