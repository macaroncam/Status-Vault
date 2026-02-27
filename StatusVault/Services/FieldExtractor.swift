import Foundation

class FieldExtractor {
    static let shared = FieldExtractor()

    private init() {}

    func extractFields(from ocrText: String, documentType: DocumentType) -> ExtractedFields {
        let fields = ExtractedFields()
        fields.rawOCRText = ocrText

        switch documentType {
        case .i20:
            extractI20Fields(from: ocrText, into: fields)
        case .ead:
            extractEADFields(from: ocrText, into: fields)
        case .passport:
            extractPassportFields(from: ocrText, into: fields)
        case .visa:
            extractVisaFields(from: ocrText, into: fields)
        case .i94:
            extractI94Fields(from: ocrText, into: fields)
        case .i797:
            extractI797Fields(from: ocrText, into: fields)
        case .other:
            break
        }

        return fields
    }

    private func extractI20Fields(from text: String, into fields: ExtractedFields) {
        // Extract SEVIS ID (typically N followed by 10 digits)
        if let sevisID = extractPattern(from: text, pattern: "N\\d{10}") {
            fields.sevisID = sevisID
        }

        // Extract name
        if let name = extractAfterLabel(from: text, label: "Name") {
            fields.fullName = name
        }

        // Extract dates
        fields.issuedDate = extractDate(from: text, nearLabel: "Issue Date")
        fields.programEndDate = extractDate(from: text, nearLabel: "Program End Date")
    }

    private func extractEADFields(from text: String, into fields: ExtractedFields) {
        // Extract card number (typically 3 groups: AAA-BB-CCC-DDDD)
        if let cardNumber = extractPattern(from: text, pattern: "[A-Z]{3}-\\d{2}-\\d{3}-\\d{4}") {
            fields.documentNumber = cardNumber
        }

        // Extract name - look for patterns
        let lines = text.components(separatedBy: .newlines)
        for (index, line) in lines.enumerated() {
            if line.lowercased().contains("name") && index + 1 < lines.count {
                fields.fullName = lines[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }

        // Extract EAD category
        if let category = extractPattern(from: text, pattern: "C\\d{2}[A-Z]?") {
            fields.eadCategory = category
        }

        // Extract Valid From and Valid Until dates with improved logic
        let dateLines = text.components(separatedBy: .newlines)

        for (index, line) in dateLines.enumerated() {
            let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // Look for "Valid From" or similar
            if cleanLine.lowercased().contains("valid from") || cleanLine.lowercased().contains("card expires") {
                // Try to extract date from same line first
                if let date = extractDateFromLine(cleanLine) {
                    if cleanLine.lowercased().contains("valid from") {
                        fields.validFrom = date
                    }
                }
                // Try next line if date not found on same line
                else if index + 1 < dateLines.count {
                    if let date = extractDateFromLine(dateLines[index + 1]) {
                        if cleanLine.lowercased().contains("valid from") {
                            fields.validFrom = date
                        }
                    }
                }
            }

            // Look for "Valid Until" or expiration
            if cleanLine.lowercased().contains("valid until") || cleanLine.lowercased().contains("expires") {
                if let date = extractDateFromLine(cleanLine) {
                    fields.validUntil = date
                    fields.expirationDate = date
                }
                else if index + 1 < dateLines.count {
                    if let date = extractDateFromLine(dateLines[index + 1]) {
                        fields.validUntil = date
                        fields.expirationDate = date
                    }
                }
            }
        }
    }

    private func extractPassportFields(from text: String, into fields: ExtractedFields) {
        // Extract passport number
        if let passportNum = extractPattern(from: text, pattern: "[A-Z]{1,2}\\d{7,9}") {
            fields.passportNumber = passportNum
            fields.documentNumber = passportNum
        }

        // Extract name
        if let name = extractAfterLabel(from: text, label: "Surname") {
            fields.fullName = name
        }

        // Extract dates
        fields.dateOfBirth = extractDate(from: text, nearLabel: "Date of birth")
        fields.issuedDate = extractDate(from: text, nearLabel: "Date of issue")
        fields.expirationDate = extractDate(from: text, nearLabel: "Date of expiry")
    }

    private func extractVisaFields(from text: String, into fields: ExtractedFields) {
        // Extract visa type (F-1, H-1B, etc.)
        if let visaType = extractPattern(from: text, pattern: "[A-Z]-\\d[A-Z]?") {
            fields.visaType = visaType
        }

        fields.issuedDate = extractDate(from: text, nearLabel: "Issue Date")
        fields.expirationDate = extractDate(from: text, nearLabel: "Expiration Date")
    }

    private func extractI94Fields(from text: String, into fields: ExtractedFields) {
        // Extract admission number
        if let admissionNum = extractPattern(from: text, pattern: "\\d{11}") {
            fields.admissionNumber = admissionNum
        }

        // Extract class of admission
        if let classAdmission = extractAfterLabel(from: text, label: "Class of Admission") {
            fields.classOfAdmission = classAdmission
        }

        fields.admitUntilDate = extractDate(from: text, nearLabel: "Admit Until Date")
    }

    private func extractI797Fields(from text: String, into fields: ExtractedFields) {
        // Extract receipt number (WAC, EAC, LIN, SRC, NBC, MSC, IOE)
        if let receiptNum = extractPattern(from: text, pattern: "[A-Z]{3}\\d{10}") {
            fields.receiptNumber = receiptNum
        }

        if let beneficiary = extractAfterLabel(from: text, label: "Beneficiary") {
            fields.beneficiaryName = beneficiary
        }

        fields.issuedDate = extractDate(from: text, nearLabel: "Notice Date")
        fields.expirationDate = extractDate(from: text, nearLabel: "Valid From")
    }

    // Helper methods
    private func extractPattern(from text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }

        return (text as NSString).substring(with: match.range)
    }

    private func extractAfterLabel(from text: String, label: String) -> String? {
        let lines = text.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            if line.lowercased().contains(label.lowercased()) {
                // Try same line first
                let components = line.components(separatedBy: ":")
                if components.count > 1 {
                    let value = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if !value.isEmpty {
                        return value
                    }
                }

                // Try next line
                if index + 1 < lines.count {
                    let nextLine = lines[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if !nextLine.isEmpty {
                        return nextLine
                    }
                }
            }
        }

        return nil
    }

    private func extractDate(from text: String, nearLabel: String) -> Date? {
        let lines = text.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            if line.lowercased().contains(nearLabel.lowercased()) {
                // Try current line
                if let date = extractDateFromLine(line) {
                    return date
                }

                // Try next line
                if index + 1 < lines.count {
                    if let date = extractDateFromLine(lines[index + 1]) {
                        return date
                    }
                }
            }
        }

        return nil
    }

    private func extractDateFromLine(_ line: String) -> Date? {
        let dateFormats = [
            "MM/dd/yyyy",
            "MM-dd-yyyy",
            "dd/MM/yyyy",
            "dd-MM-yyyy",
            "MMM dd, yyyy",
            "MMMM dd, yyyy",
            "dd MMM yyyy",
            "dd MMMM yyyy",
            "yyyy-MM-dd"
        ]

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        // Clean the line
        let cleaned = line.replacingOccurrences(of: "[^a-zA-Z0-9/\\-,\\s]", with: "", options: .regularExpression)

        for format in dateFormats {
            formatter.dateFormat = format

            // Try to find date in the string
            let words = cleaned.components(separatedBy: .whitespaces)
            for i in 0..<words.count {
                // Try 1-4 consecutive words
                for length in 1...min(4, words.count - i) {
                    let dateString = words[i..<(i+length)].joined(separator: " ")
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }
            }
        }

        return nil
    }
}
