import Foundation

class DocumentContextBuilder {
    static let shared = DocumentContextBuilder()

    private init() {}

    func buildContext(from documents: [Document]) -> String {
        guard !documents.isEmpty else {
            return "The user has no documents uploaded yet."
        }

        var context = "User's Immigration Documents:\n\n"

        let activeDocuments = documents.filter { $0.state == .active || $0.state == .expiringSoon }
        let expiredDocuments = documents.filter { $0.state == .expired }

        // Active documents
        if !activeDocuments.isEmpty {
            context += "Active Documents:\n"
            for doc in activeDocuments {
                context += "- \(doc.type.rawValue)"

                if let fields = doc.extractedFields {
                    if let name = fields.fullName {
                        context += " (Name: \(name))"
                    }

                    switch doc.type {
                    case .ead:
                        if let category = fields.eadCategory {
                            context += ", Category: \(category)"
                        }
                        if let validUntil = fields.validUntil {
                            context += ", Valid Until: \(formatDate(validUntil))"
                        }
                    case .i20:
                        if let sevisID = fields.sevisID {
                            context += ", SEVIS ID: \(sevisID)"
                        }
                        if let programEnd = fields.programEndDate {
                            context += ", Program Ends: \(formatDate(programEnd))"
                        }
                    case .visa:
                        if let visaType = fields.visaType {
                            context += ", Type: \(visaType)"
                        }
                    case .passport:
                        if let nationality = fields.nationality {
                            context += ", Nationality: \(nationality)"
                        }
                    default:
                        break
                    }
                }

                if let expiryDate = doc.expiryDate {
                    context += ", Expires: \(formatDate(expiryDate))"
                }

                context += ", Status: \(doc.state.rawValue)"
                context += "\n"
            }
            context += "\n"
        }

        // Expired documents
        if !expiredDocuments.isEmpty {
            context += "Expired Documents:\n"
            for doc in expiredDocuments {
                context += "- \(doc.type.rawValue)"
                if let expiryDate = doc.expiryDate {
                    context += " (Expired: \(formatDate(expiryDate)))"
                }
                context += "\n"
            }
            context += "\n"
        }

        // Calculate current status
        let statusSnapshot = StatusEngine.shared.calculateCurrentStatus(documents: documents)
        context += "Current Immigration Status:\n"
        context += "- Status: \(statusSnapshot.currentStatus)\n"
        context += "- Work Authorization: \(statusSnapshot.canWork ? "Yes" : "No")"
        if let workExpiry = statusSnapshot.workExpiryDate {
            context += " (until \(formatDate(workExpiry)))"
        }
        context += "\n"
        context += "- Study Authorization: \(statusSnapshot.canStudy ? "Yes" : "No")\n"

        if !statusSnapshot.warnings.isEmpty {
            context += "\nWarnings:\n"
            for warning in statusSnapshot.warnings {
                context += "- \(warning)\n"
            }
        }

        return context
    }

    func buildSystemPrompt() -> String {
        return """
        You are an immigration assistant for StatusVault, an app that helps users manage their U.S. immigration documents.

        Your role is to:
        1. Answer questions about U.S. immigration rules, visa types, travel restrictions, and document requirements
        2. Provide personalized advice based on the user's specific documents and immigration status
        3. Help users understand their work and study authorization
        4. Advise on travel considerations (e.g., "Can I travel to Mexico?", "Do I need a visa for Canada?")
        5. Explain document expiration impacts and what steps to take
        6. Clarify SEVIS, OPT, CPT, H-1B, and other immigration program rules

        Important guidelines:
        - Base your answers on the user's actual documents when relevant
        - Be accurate and cite official sources when possible (USCIS, DOS, etc.)
        - If you're not certain about something, say so and recommend consulting an immigration attorney
        - Be concise but thorough
        - Use clear, jargon-free language when possible, but explain technical terms when needed
        - For travel questions, consider visa requirements, work authorization, and re-entry considerations

        You will receive the user's document information as context before each conversation.
        """
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
