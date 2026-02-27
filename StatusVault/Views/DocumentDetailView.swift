import SwiftUI
import SwiftData

struct DocumentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let document: Document
    @State private var decryptedImage: UIImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Document Image
                    if let image = decryptedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    } else {
                        ProgressView()
                            .frame(height: 200)
                    }

                    // Document Info
                    VStack(alignment: .leading, spacing: 16) {
                        InfoSection(title: "Document Information") {
                            DetailInfoRow(label: "Type", value: document.type.rawValue)
                            DetailInfoRow(label: "Status", value: document.state.rawValue, valueColor: Color(document.state.color))

                            if let expiryDate = document.expiryDate {
                                DetailInfoRow(label: "Expiry Date", value: expiryDate.formatted(date: .long, time: .omitted))
                            }

                            if let effectiveDate = document.effectiveDate {
                                DetailInfoRow(label: "Effective Date", value: effectiveDate.formatted(date: .long, time: .omitted))
                            }
                        }

                        if let fields = document.extractedFields {
                            ExtractedFieldsSection(fields: fields, documentType: document.type)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Document Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadImage()
            }
        }
    }

    private func loadImage() {
        Task {
            do {
                decryptedImage = try EncryptionService.shared.loadEncryptedImage(filename: document.encryptedImagePath)
            } catch {
                print("Failed to load image: \(error)")
            }
        }
    }
}

struct InfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(spacing: 8) {
                content
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
    }
}

struct DetailInfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(valueColor)
        }
    }
}

struct ExtractedFieldsSection: View {
    let fields: ExtractedFields
    let documentType: DocumentType

    var body: some View {
        InfoSection(title: "Extracted Information") {
            if let name = fields.fullName {
                DetailInfoRow(label: "Full Name", value: name)
            }

            if let docNumber = fields.documentNumber {
                DetailInfoRow(label: "Document Number", value: docNumber)
            }

            switch documentType {
            case .ead:
                if let category = fields.eadCategory {
                    DetailInfoRow(label: "Category", value: category)
                }
                if let validFrom = fields.validFrom {
                    DetailInfoRow(label: "Valid From", value: validFrom.formatted(date: .long, time: .omitted))
                }
                if let validUntil = fields.validUntil {
                    DetailInfoRow(label: "Valid Until", value: validUntil.formatted(date: .long, time: .omitted))
                }

            case .i20:
                if let sevisID = fields.sevisID {
                    DetailInfoRow(label: "SEVIS ID", value: sevisID)
                }
                if let school = fields.schoolName {
                    DetailInfoRow(label: "School", value: school)
                }

            case .passport:
                if let passportNum = fields.passportNumber {
                    DetailInfoRow(label: "Passport Number", value: passportNum)
                }
                if let nationality = fields.nationality {
                    DetailInfoRow(label: "Nationality", value: nationality)
                }

            default:
                EmptyView()
            }

            if let expiryDate = fields.expirationDate {
                DetailInfoRow(label: "Expiration", value: expiryDate.formatted(date: .long, time: .omitted))
            }
        }
    }
}
