import SwiftUI
import SwiftData
import PhotosUI

struct AddDocumentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var isProcessing = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 30) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                            .shadow(radius: 5)

                        if isProcessing {
                            ProgressView("Processing document...")
                                .padding()
                        } else {
                            ModernButton(title: "Save Document", icon: "checkmark.circle.fill", gradient: [.green, .blue]) {
                                Task {
                                    await processAndSaveDocument()
                                }
                            }

                            ModernButton(title: "Retake", icon: "arrow.clockwise", gradient: [.orange, .red]) {
                                selectedImage = nil
                            }
                        }
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "doc.viewfinder")
                                .font(.system(size: 80))
                                .foregroundStyle(.blue.opacity(0.6))

                            Text("Add Immigration Document")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Take a photo or select from your library")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 40)

                        VStack(spacing: 16) {
                            ModernButton(title: "Take Photo", icon: "camera.fill", gradient: [.blue, .purple]) {
                                sourceType = .camera
                                showingCamera = true
                            }

                            ModernButton(title: "Choose from Library", icon: "photo.fill", gradient: [.purple, .pink]) {
                                sourceType = .photoLibrary
                                showingImagePicker = true
                            }
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Add Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: sourceType)
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
            }
        }
    }

    private func processAndSaveDocument() async {
        guard let image = selectedImage else { return }

        isProcessing = true

        do {
            // Perform OCR
            let ocrText = try await OCRService.shared.performOCR(on: image)

            // Detect document type
            let documentType = DocumentTypeDetector.shared.detectType(from: ocrText)

            // Extract fields
            let extractedFields = FieldExtractor.shared.extractFields(from: ocrText, documentType: documentType)

            // Encrypt and save image
            let document = Document(type: documentType, encryptedImagePath: "")
            let encryptedPath = try EncryptionService.shared.saveEncryptedImage(image, documentID: document.id)
            document.encryptedImagePath = encryptedPath

            // Assign extracted fields
            document.extractedFields = extractedFields
            document.effectiveDate = extractedFields.validFrom ?? extractedFields.issuedDate
            document.expiryDate = extractedFields.expirationDate ?? extractedFields.validUntil

            // Save to database
            modelContext.insert(document)
            try modelContext.save()

            // Update document states
            let allDocuments = try modelContext.fetch(FetchDescriptor<Document>())
            DocumentLifecycleEngine.shared.updateDocumentStates(documents: allDocuments)

            dismiss()
        } catch {
            print("Error processing document: \(error)")
            isProcessing = false
        }
    }
}

struct ModernButton: View {
    let title: String
    let icon: String
    let gradient: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)

                Text(title)
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: gradient),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .shadow(color: gradient.first?.opacity(0.4) ?? .clear, radius: 8, x: 0, y: 4)
        }
    }
}

// UIKit ImagePicker wrapper
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
