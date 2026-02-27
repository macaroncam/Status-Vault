# StatusVault - Product Requirements Document (PRD)
## V1 - Personal Use iOS App

**Version:** 1.0
**Target:** Personal use - single user on iPhone
**Timeline:** MVP in 2-3 weeks
**Platform:** iOS 17+ (iPhone only for V1)

---

## Executive Summary

StatusVault V1 is a local-first, privacy-focused iOS app for managing immigration documents. It uses on-device OCR to automatically extract key information from documents (I-20s, visas, EADs, passports, etc.), displays them on an intelligent timeline, and provides status tracking - all without requiring a backend server.

**Core Value Proposition:** Never lose an immigration document. Always know your current status. All data stays on your device.

---

## Technical Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     StatusVault iOS App                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Camera     │  │   Gallery    │  │   Files      │      │
│  │   Capture    │  │   Import     │  │   Import     │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │              │
│         └──────────────────┼──────────────────┘              │
│                            ▼                                 │
│                   ┌─────────────────┐                        │
│                   │  Vision Framework│                       │
│                   │  (On-Device OCR) │                       │
│                   └────────┬─────────┘                       │
│                            ▼                                 │
│                   ┌─────────────────┐                        │
│                   │ Document Parser  │                       │
│                   │  - Type Detection│                       │
│                   │  - Field Extract │                       │
│                   │  - Date Extract  │                       │
│                   └────────┬─────────┘                       │
│                            ▼                                 │
│         ┌──────────────────────────────────────┐             │
│         │        SwiftData (Local DB)          │             │
│         │  - Documents                         │             │
│         │  - ExtractedFields                   │             │
│         │  - Timeline Events                   │             │
│         └──────────┬───────────────────────────┘             │
│                    │                                         │
│         ┌──────────┴───────────────┐                         │
│         ▼                           ▼                        │
│  ┌─────────────┐          ┌──────────────────┐              │
│  │  Encrypted  │          │  Status Engine   │              │
│  │  File Store │          │  - Current Status│              │
│  │  (AES-256)  │          │  - Active Docs   │              │
│  └─────────────┘          │  - Expiry Logic  │              │
│                           └──────────────────┘              │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              User Interface (SwiftUI)                 │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  • Timeline View (main screen)                       │   │
│  │  • Document Detail View                              │   │
│  │  • Camera/Scanner View                               │   │
│  │  • Status Card                                       │   │
│  │  • Settings                                          │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         Security Layer                                │   │
│  │  - Face ID/Touch ID (LocalAuthentication)            │   │
│  │  - AES-256 encryption (CryptoKit)                     │   │
│  │  - Secure file storage                                │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         Optional: iCloud Backup                       │   │
│  │  - Encrypted before sync                              │   │
│  │  - User can enable/disable                            │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Tech Stack

| Component | Technology | Justification |
|-----------|-----------|---------------|
| **UI Framework** | SwiftUI | Modern, declarative, native iOS |
| **Language** | Swift 5.9+ | Native performance, modern syntax |
| **Database** | SwiftData | iOS 17+ native ORM, iCloud sync ready |
| **OCR Engine** | Vision Framework | On-device, free, highly accurate |
| **Encryption** | CryptoKit | Apple's native crypto, AES-256 |
| **Auth** | LocalAuthentication | Face ID/Touch ID integration |
| **Image Storage** | FileManager + AES | Encrypted local file storage |
| **PDF Handling** | PDFKit | Native PDF rendering and manipulation |
| **Camera** | AVFoundation | Native camera access |
| **Backup** | CloudKit (optional) | Native iCloud integration |

### Deployment

- **Minimum iOS:** 17.0
- **Target Devices:** iPhone only (V1)
- **Installation:** Xcode direct install (free Apple ID)
- **Data Storage:** Local device only
- **Backend:** None (fully local)

---

## Data Models

### 1. Document Model

```swift
@Model
class Document {
    // Core Identity
    var id: UUID
    var type: DocumentType
    var dateAdded: Date

    // File References
    var imageFilename: String?          // Encrypted file in Documents/
    var pdfFilename: String?            // Encrypted file in Documents/
    var thumbnailFilename: String?      // Encrypted thumbnail

    // Lifecycle States
    var state: DocumentState
    var effectiveDate: Date?            // When document becomes active
    var expiryDate: Date?               // When it naturally expires
    var supersededDate: Date?           // When replaced by another doc
    var supersededBy: Document?         // Link to replacing document

    // Extracted Fields (varies by type)
    var extractedFields: ExtractedFields?

    // User Metadata
    var userNotes: String?
    var userTags: [String]

    // Relationships
    var parentDocument: Document?       // What authorized this doc
    var childDocuments: [Document]      // What this doc enables
    var relatedDocuments: [Document]    // Loose associations

    // Timeline Position (computed)
    var timelineStartDate: Date {
        effectiveDate ?? dateAdded
    }
    var timelineEndDate: Date? {
        supersededDate ?? expiryDate
    }
}

enum DocumentType: String, Codable {
    // Core Immigration Documents
    case passport
    case i20              // F-1 student authorization
    case visaStamp        // Entry visa
    case i94              // Admission record
    case ead              // Employment Authorization Document
    case i797             // USCIS approval notice (H-1B, etc.)
    case i140             // Immigrant petition (EB green card)
    case i485             // Adjustment of Status
    case advanceParole    // Travel document during AOS
    case greenCard        // I-551

    // Supporting Documents
    case cptAuthorization // Curricular Practical Training
    case i983             // STEM OPT training plan
    case i765Receipt      // EAD application receipt
    case travelSignature  // DSO signature on I-20
    case perm             // Labor certification
    case lca              // Labor Condition Application (H-1B)

    // Other
    case other

    var displayName: String {
        switch self {
        case .i20: return "I-20"
        case .visaStamp: return "Visa Stamp"
        case .i94: return "I-94 Admission Record"
        case .ead: return "EAD Card"
        case .i797: return "I-797 Approval Notice"
        case .passport: return "Passport"
        case .greenCard: return "Green Card"
        case .i140: return "I-140 Petition"
        case .i485: return "I-485 Application"
        case .advanceParole: return "Advance Parole"
        case .cptAuthorization: return "CPT Authorization"
        case .i983: return "I-983 Training Plan"
        case .i765Receipt: return "I-765 Receipt"
        case .travelSignature: return "Travel Signature"
        case .perm: return "PERM Labor Cert"
        case .lca: return "LCA"
        case .other: return "Other Document"
        }
    }
}

enum DocumentState: String, Codable {
    case upcoming         // Filed/pending, not yet in effect
    case active           // Currently governs status
    case expiringSoon     // Active but expires within 90 days
    case expired          // Past expiry date
    case superseded       // Replaced by newer document

    var color: Color {
        switch self {
        case .upcoming: return .blue
        case .active: return .green
        case .expiringSoon: return .orange
        case .expired: return .gray
        case .superseded: return .gray.opacity(0.5)
        }
    }

    var icon: String {
        switch self {
        case .upcoming: return "clock.fill"
        case .active: return "checkmark.circle.fill"
        case .expiringSoon: return "exclamationmark.triangle.fill"
        case .expired: return "xmark.circle.fill"
        case .superseded: return "arrow.right.circle.fill"
        }
    }
}
```

### 2. Extracted Fields Model

```swift
@Model
class ExtractedFields {
    var id: UUID

    // Common to all documents
    var documentNumber: String?
    var fullName: String?
    var dateOfBirth: Date?
    var nationality: String?

    // I-20 Specific
    var sevisNumber: String?
    var schoolName: String?
    var programLevel: String?        // Bachelor's, Master's, PhD
    var programName: String?         // Computer Science
    var programStartDate: Date?
    var programEndDate: Date?
    var dsoName: String?
    var dsoSignature: Bool?
    var travelSignatureDate: Date?

    // Visa Stamp Specific
    var visaType: String?            // F-1, H-1B, etc.
    var visaIssueDate: Date?
    var visaExpiryDate: Date?
    var visaEntries: String?         // M (multiple), Single
    var issuingPost: String?         // Embassy location

    // EAD Specific
    var eadCategory: String?         // C03B (STEM OPT), C09 (I-485)
    var uscisNumber: String?
    var cardNumber: String?
    var validFrom: Date?
    var validUntil: Date?

    // I-94 Specific
    var admissionNumber: String?
    var classOfAdmission: String?    // F-1, H-1B, etc.
    var admittedUntil: String?       // D/S or specific date
    var portOfEntry: String?
    var admissionDate: Date?

    // I-797 Specific
    var receiptNumber: String?
    var petitionType: String?        // H-1B, L-1, etc.
    var beneficiary: String?
    var petitioner: String?          // Employer name
    var validityStartDate: Date?
    var validityEndDate: Date?

    // Passport Specific
    var passportNumber: String?
    var issuingCountry: String?
    var passportIssueDate: Date?
    var passportExpiryDate: Date?

    // Raw OCR text (for debugging/fallback)
    var rawOCRText: String?
    var ocrConfidence: Double?       // 0.0 to 1.0
}
```

### 3. Status Snapshot Model

```swift
@Model
class StatusSnapshot {
    var id: UUID
    var asOfDate: Date

    // Current Status
    var immigrationStatus: String?    // "F-1 OPT", "H-1B", etc.
    var authorizedUntil: Date?
    var workAuthorized: Bool
    var travelAuthorized: Bool

    // Active Documents
    var activeDocuments: [Document]

    // Permissions
    var canDo: [String]              // ["work_fulltime", "travel_domestic"]
    var cannotDo: [String]           // ["work_off_campus", "freelance"]
    var mustDo: [String]             // ["maintain_fulltime_enrollment"]

    // Next Critical Date
    var nextDeadline: Date?
    var nextDeadlineType: String?    // "EAD_EXPIRY", "I20_PROGRAM_END"
    var daysUntilDeadline: Int?
}
```

### 4. Timeline Event Model

```swift
@Model
class TimelineEvent {
    var id: UUID
    var date: Date
    var eventType: EventType
    var title: String
    var description: String?
    var associatedDocument: Document?

    enum EventType: String, Codable {
        case documentAdded
        case documentExpired
        case documentSuperseded
        case statusChange
        case travelEntry
        case travelExit
        case applicationFiled
        case approvalReceived
        case milestone           // Graduation, job start, etc.
    }
}
```

---

## Feature Specifications

### Feature 1: Document Capture & Import

#### User Flow
```
User taps "+" button
  ↓
Choose source:
  • Take Photo
  • Choose from Photos
  • Import PDF
  ↓
[If camera] Camera view with guides
  • Detect document edges
  • Auto-capture when steady
  • Flash icon if lighting poor
  ↓
Preview captured image
  • Crop/rotate controls
  • Retake button
  ↓
Processing screen
  • "Analyzing document..."
  • Progress indicator
  ↓
OCR extraction runs (on-device)
  ↓
Document type detected
  ↓
Extracted fields shown for review
  • Pre-filled form with OCR results
  • User can edit any field
  • Confidence indicators (high/medium/low)
  ↓
User confirms or edits
  ↓
Document saved
  • Image encrypted and stored
  • Metadata saved to SwiftData
  • Added to timeline
  • Status snapshot updated
  ↓
Timeline view refreshes
  • New document appears
  • Active status updated
```

#### Technical Implementation

**Camera Capture:**
```swift
// Use AVFoundation for camera
import AVFoundation

class CameraService: NSObject, ObservableObject {
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()

    func capturePhoto() {
        // Capture with high quality
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func detectDocumentEdges(in image: CIImage) -> VNRectangleObservation? {
        // Use Vision to detect document boundaries
        let request = VNDetectRectanglesRequest()
        request.minimumAspectRatio = 0.3
        request.maximumObservations = 1
        // ... process and return edges
    }
}
```

**OCR Processing:**
```swift
import Vision

class OCRService {
    func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observations = request.results else {
            return ""
        }

        let recognizedText = observations
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")

        return recognizedText
    }
}
```

**Document Type Detection:**
```swift
class DocumentTypeDetector {
    func detectType(from text: String) -> DocumentType {
        let lowercased = text.lowercased()

        // Pattern matching for different document types
        if text.contains("I-20") || text.contains("SEVIS") {
            return .i20
        } else if lowercased.contains("employment authorization") {
            return .ead
        } else if text.contains("I-797") || text.contains("USCIS") {
            return .i797
        } else if text.contains("I-94") || lowercased.contains("admission number") {
            return .i94
        } else if lowercased.contains("passport") {
            return .passport
        }
        // ... more patterns

        return .other
    }
}
```

**Field Extraction:**
```swift
class FieldExtractor {
    func extractFields(from text: String, type: DocumentType) -> ExtractedFields {
        let fields = ExtractedFields()

        switch type {
        case .i20:
            fields.sevisNumber = extractSEVIS(from: text)
            fields.schoolName = extractSchool(from: text)
            fields.programStartDate = extractProgramStart(from: text)
            fields.programEndDate = extractProgramEnd(from: text)

        case .ead:
            fields.eadCategory = extractEADCategory(from: text)
            fields.uscisNumber = extractUSCISNumber(from: text)
            fields.validFrom = extractValidFrom(from: text)
            fields.validUntil = extractValidUntil(from: text)

        case .visaStamp:
            fields.visaType = extractVisaType(from: text)
            fields.visaIssueDate = extractIssueDate(from: text)
            fields.visaExpiryDate = extractExpiryDate(from: text)

        // ... more cases
        default:
            break
        }

        // Always try to extract common fields
        fields.documentNumber = extractDocumentNumber(from: text)
        fields.fullName = extractName(from: text)
        fields.dateOfBirth = extractDOB(from: text)

        fields.rawOCRText = text
        return fields
    }

    private func extractSEVIS(from text: String) -> String? {
        // Pattern: N + 10 digits (e.g., N0012345678)
        let pattern = "N\\d{10}"
        return extractPattern(pattern, from: text)
    }

    private func extractUSCISNumber(from text: String) -> String? {
        // Pattern: SRC-XXX-XXX-XXXXX or similar
        let pattern = "[A-Z]{3}-?\\d{2,3}-?\\d{3}-?\\d{3,5}"
        return extractPattern(pattern, from: text)
    }

    private func extractPattern(_ pattern: String, from text: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex?.firstMatch(in: text, range: range) else {
            return nil
        }
        return String(text[Range(match.range, in: text)!])
    }

    private func extractDates(from text: String) -> [Date] {
        // Use NSDataDetector for date extraction
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let matches = detector?.matches(in: text, range: NSRange(text.startIndex..., in: text))

        return matches?.compactMap { $0.date } ?? []
    }
}
```

**Encrypted File Storage:**
```swift
import CryptoKit

class EncryptedFileStorage {
    private let fileManager = FileManager.default
    private let documentsDirectory: URL

    init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func saveEncrypted(image: UIImage, filename: String) throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.invalidImage
        }

        // Generate encryption key (stored in Keychain in real implementation)
        let key = SymmetricKey(size: .bits256)

        // Encrypt data
        let sealedBox = try AES.GCM.seal(imageData, using: key)

        // Save encrypted data
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        try sealedBox.combined?.write(to: fileURL)

        return filename
    }

    func loadDecrypted(filename: String) throws -> UIImage {
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        let encryptedData = try Data(contentsOf: fileURL)

        // Get key from Keychain
        let key = try retrieveKeyFromKeychain()

        // Decrypt
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)

        guard let image = UIImage(data: decryptedData) else {
            throw StorageError.corruptedImage
        }

        return image
    }

    private func retrieveKeyFromKeychain() throws -> SymmetricKey {
        // Keychain implementation
        // For V1, could use a hardcoded key or generate on first launch
        // In production, use Keychain properly
        return SymmetricKey(size: .bits256)
    }
}
```

---

### Feature 2: Timeline View

#### User Interface

```
┌─────────────────────────────────────────┐
│  ☰  StatusVault            🔍  ⚙️  ➕  │ ← Navigation bar
├─────────────────────────────────────────┤
│                                         │
│  📊 YOUR STATUS                         │
│  ┌───────────────────────────────────┐  │
│  │ F-1 OPT (STEM Extension)          │  │
│  │ Work Authorized: ✅                │  │
│  │ Valid until: Jun 15, 2026         │  │
│  │ 427 days remaining                │  │
│  └───────────────────────────────────┘  │
│                                         │
│  📅 TIMELINE                            │
│  ┌───────────────────────────────────┐  │
│  │ 2019          2021          2023  │  │
│  │ ├─────────────┼─────────────┤     │  │
│  │                                   │  │
│  │ ████████████████████████████████  │  │ ← Passport (active)
│  │ Passport • Expires 2029           │  │
│  │                                   │  │
│  │ ██████████░░░░░░░░░░░░░░░░░░░░░░  │  │ ← Visa (expired)
│  │ F-1 Visa • Expired Jul 2023       │  │
│  │                                   │  │
│  │ ▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░  │  │ ← Old I-20
│  │ I-20 #1 • Superseded              │  │
│  │         ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │  │ ← Current I-20
│  │         I-20 #2 (STEM OPT)        │  │
│  │                                   │  │
│  │              ████████████████████  │  │ ← EAD (active)
│  │              EAD • 427 days left  │  │
│  │                                   │  │
│  │         ┊    ┊                    │  │
│  │      [Exit] [Entry]               │  │ ← Travel events
│  │                                   │  │
│  └───────────────────────────────────┘  │
│                                         │
│  🔔 ALERTS                              │
│  ⚠️ EAD expires in 427 days            │
│     Consider H-1B filing in Jan        │
│                                         │
│  📄 RECENT DOCUMENTS                    │
│  [EAD Card]           Jun 15, 2024    │
│  [I-20 STEM OPT]      Jun 1, 2024     │
│  [I-983 Plan]         May 20, 2024    │
│                                         │
└─────────────────────────────────────────┘
```

#### Timeline Interaction Logic

```swift
struct TimelineView: View {
    @Query var documents: [Document]
    @State private var selectedDocument: Document?
    @State private var zoomLevel: ZoomLevel = .years

    enum ZoomLevel {
        case years      // Show 5+ years
        case months     // Show 12-24 months
        case weeks      // Show 8-16 weeks
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status Card
                CurrentStatusCard()

                // Timeline
                TimelineCanvas(
                    documents: sortedDocuments,
                    zoomLevel: zoomLevel,
                    onDocumentTap: { doc in
                        selectedDocument = doc
                    }
                )
                .gesture(MagnificationGesture()
                    .onChanged { value in
                        // Zoom in/out
                    }
                )

                // Alerts Section
                AlertsSection()

                // Recent Documents List
                RecentDocumentsList()
            }
        }
        .sheet(item: $selectedDocument) { doc in
            DocumentDetailView(document: doc)
        }
    }

    var sortedDocuments: [Document] {
        documents.sorted { $0.timelineStartDate < $1.timelineStartDate }
    }
}
```

#### Timeline Rendering Algorithm

```swift
struct TimelineCanvas: View {
    let documents: [Document]
    let zoomLevel: ZoomLevel
    let onDocumentTap: (Document) -> Void

    var body: some View {
        GeometryReader { geometry in
            let timeRange = calculateTimeRange()
            let width = geometry.size.width

            ZStack(alignment: .leading) {
                // Time axis
                TimeAxis(range: timeRange, width: width)

                // Document bars
                ForEach(documents) { doc in
                    DocumentBar(
                        document: doc,
                        timeRange: timeRange,
                        totalWidth: width
                    )
                    .onTapGesture {
                        onDocumentTap(doc)
                    }
                }

                // Event markers (travel, status changes)
                EventMarkers(timeRange: timeRange, width: width)
            }
        }
        .frame(height: CGFloat(documents.count * 60))
    }

    func calculateTimeRange() -> ClosedRange<Date> {
        guard let earliest = documents.map({ $0.timelineStartDate }).min(),
              let latest = documents.compactMap({ $0.timelineEndDate ?? Date() }).max() else {
            return Date()...Date()
        }
        return earliest...latest
    }
}

struct DocumentBar: View {
    let document: Document
    let timeRange: ClosedRange<Date>
    let totalWidth: CGFloat

    var body: some View {
        let startX = xPosition(for: document.timelineStartDate)
        let endX = xPosition(for: document.timelineEndDate ?? Date())
        let width = max(endX - startX, 50) // Minimum width for visibility

        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(document.state.color)
                .frame(width: width, height: 40)
                .overlay(
                    HStack {
                        Image(systemName: document.state.icon)
                            .font(.caption)
                        Text(document.type.displayName)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                )
                .offset(x: startX)
        }
    }

    func xPosition(for date: Date) -> CGFloat {
        let totalDuration = timeRange.upperBound.timeIntervalSince(timeRange.lowerBound)
        let offsetDuration = date.timeIntervalSince(timeRange.lowerBound)
        let ratio = offsetDuration / totalDuration
        return totalWidth * ratio
    }
}
```

---

### Feature 3: Document Lifecycle Engine

#### State Transition Logic

```swift
class DocumentLifecycleEngine {
    func updateDocumentStates(documents: [Document], asOfDate: Date = Date()) {
        for document in documents {
            let newState = calculateState(for: document, asOfDate: asOfDate)
            if document.state != newState {
                document.state = newState
                logStateChange(document: document, from: document.state, to: newState)
            }
        }
    }

    private func calculateState(for document: Document, asOfDate: Date) -> DocumentState {
        // If superseded, always superseded
        if document.supersededDate != nil {
            return .superseded
        }

        // If not yet effective
        if let effectiveDate = document.effectiveDate, effectiveDate > asOfDate {
            return .upcoming
        }

        // If expired
        if let expiryDate = document.expiryDate, expiryDate < asOfDate {
            return .expired
        }

        // If expiring soon (within 90 days)
        if let expiryDate = document.expiryDate {
            let daysUntilExpiry = Calendar.current.dateComponents([.day], from: asOfDate, to: expiryDate).day ?? 0
            if daysUntilExpiry <= 90 && daysUntilExpiry > 0 {
                return .expiringSoon
            }
        }

        // Otherwise active
        return .active
    }
}
```

#### Supersession Detection

```swift
class SupersessionDetector {
    func detectSupersession(newDocument: Document, existingDocuments: [Document]) {
        let sameTypeDocuments = existingDocuments.filter { $0.type == newDocument.type }

        switch newDocument.type {
        case .i20:
            handleI20Supersession(new: newDocument, existing: sameTypeDocuments)

        case .i94:
            handleI94Supersession(new: newDocument, existing: sameTypeDocuments)

        case .ead:
            handleEADSupersession(new: newDocument, existing: sameTypeDocuments)

        case .i797:
            handleI797Supersession(new: newDocument, existing: sameTypeDocuments)

        default:
            handleGenericSupersession(new: newDocument, existing: sameTypeDocuments)
        }
    }

    private func handleI20Supersession(new: Document, existing: [Document]) {
        // I-20 supersession rules:
        // - New I-20 always supersedes previous I-20
        // - Effective date of new I-20 is the supersession date

        guard let newEffectiveDate = new.effectiveDate ?? new.dateAdded else { return }

        for oldDoc in existing where oldDoc.state == .active {
            oldDoc.supersededDate = newEffectiveDate
            oldDoc.supersededBy = new
            oldDoc.state = .superseded

            // Link documents
            new.parentDocument = oldDoc
        }
    }

    private func handleI94Supersession(new: Document, existing: [Document]) {
        // I-94 supersession: Each entry creates new I-94
        // Old I-94 is superseded on date of new entry

        guard let admissionDate = new.extractedFields?.admissionDate else { return }

        for oldDoc in existing {
            if let oldAdmission = oldDoc.extractedFields?.admissionDate,
               oldAdmission < admissionDate {
                oldDoc.supersededDate = admissionDate
                oldDoc.supersededBy = new
                oldDoc.state = .superseded
            }
        }
    }

    private func handleEADSupersession(new: Document, existing: [Document]) {
        // EAD supersession: New EAD supersedes old on validity start date
        // BUT: Check for auto-extension rules (180-day rule for pending renewals)

        guard let newValidFrom = new.extractedFields?.validFrom else { return }

        for oldDoc in existing where oldDoc.state != .superseded {
            oldDoc.supersededDate = newValidFrom
            oldDoc.supersededBy = new
            oldDoc.state = .superseded

            // TODO V2: Implement 180-day auto-extension logic
        }
    }

    private func handleI797Supersession(new: Document, existing: [Document]) {
        // I-797 supersession is complex:
        // - Same employer + overlapping dates = extension (supersede old)
        // - Different employer = transfer (mark old as ended, new starts)

        guard let newEmployer = new.extractedFields?.petitioner else { return }

        for oldDoc in existing where oldDoc.state == .active {
            guard let oldEmployer = oldDoc.extractedFields?.petitioner else { continue }

            if newEmployer.lowercased() == oldEmployer.lowercased() {
                // Same employer = extension
                oldDoc.supersededBy = new
                oldDoc.state = .superseded
            } else {
                // Different employer = transfer
                // Old petition ends when new one starts
                if let newStartDate = new.extractedFields?.validityStartDate {
                    oldDoc.supersededDate = newStartDate
                    oldDoc.supersededBy = new
                    oldDoc.state = .superseded
                }
            }
        }
    }

    private func handleGenericSupersession(new: Document, existing: [Document]) {
        // Generic rule: newer document supersedes older if dates overlap

        guard let newStart = new.effectiveDate else { return }

        for oldDoc in existing where oldDoc.state == .active {
            oldDoc.supersededDate = newStart
            oldDoc.supersededBy = new
            oldDoc.state = .superseded
        }
    }
}
```

---

### Feature 4: Status Engine

#### Current Status Calculation

```swift
class StatusEngine {
    func calculateCurrentStatus(documents: [Document]) -> StatusSnapshot {
        let snapshot = StatusSnapshot()
        snapshot.asOfDate = Date()

        // Get all active documents
        let activeDocuments = documents.filter { $0.state == .active }
        snapshot.activeDocuments = activeDocuments

        // Determine primary status document
        if let i20 = activeDocuments.first(where: { $0.type == .i20 }) {
            snapshot.immigrationStatus = determineF1Status(i20: i20, ead: activeDocuments.first(where: { $0.type == .ead }))
        } else if let i797 = activeDocuments.first(where: { $0.type == .i797 }) {
            snapshot.immigrationStatus = determineH1BStatus(i797: i797)
        } else if let i485 = activeDocuments.first(where: { $0.type == .i485 }) {
            snapshot.immigrationStatus = "I-485 Pending (AOS)"
        } else if activeDocuments.contains(where: { $0.type == .greenCard }) {
            snapshot.immigrationStatus = "Lawful Permanent Resident"
        }

        // Work authorization
        snapshot.workAuthorized = isWorkAuthorized(documents: activeDocuments)

        // Travel authorization
        snapshot.travelAuthorized = isTravelAuthorized(documents: activeDocuments)

        // Authorized until
        snapshot.authorizedUntil = calculateAuthorizedUntil(documents: activeDocuments)

        // Permissions
        snapshot.canDo = calculatePermissions(documents: activeDocuments)
        snapshot.cannotDo = calculateRestrictions(documents: activeDocuments)
        snapshot.mustDo = calculateRequirements(documents: activeDocuments)

        // Next deadline
        if let nextExpiry = activeDocuments.compactMap({ $0.expiryDate }).min() {
            snapshot.nextDeadline = nextExpiry
            snapshot.daysUntilDeadline = Calendar.current.dateComponents([.day], from: Date(), to: nextExpiry).day
        }

        return snapshot
    }

    private func determineF1Status(i20: Document, ead: Document?) -> String {
        guard let fields = i20.extractedFields else {
            return "F-1 Student"
        }

        // Check if on OPT
        if let ead = ead {
            let category = ead.extractedFields?.eadCategory ?? ""
            if category.hasPrefix("C03") {
                if category == "C03B" {
                    return "F-1 OPT (STEM Extension)"
                } else {
                    return "F-1 OPT"
                }
            }
        }

        // Check if program ended (grace period)
        if let programEnd = fields.programEndDate, programEnd < Date() {
            let daysSinceEnd = Calendar.current.dateComponents([.day], from: programEnd, to: Date()).day ?? 0
            if daysSinceEnd <= 60 {
                return "F-1 (60-day grace period)"
            }
        }

        return "F-1 Student"
    }

    private func isWorkAuthorized(documents: [Document]) -> Bool {
        // Work authorization sources:
        // 1. Active EAD card
        if documents.contains(where: { $0.type == .ead && $0.state == .active }) {
            return true
        }

        // 2. Active H-1B I-797
        if documents.contains(where: { $0.type == .i797 && $0.state == .active }) {
            return true
        }

        // 3. Green card
        if documents.contains(where: { $0.type == .greenCard }) {
            return true
        }

        // 4. F-1 with CPT (on I-20)
        // TODO: Check I-20 page 2 for CPT authorization

        return false
    }

    private func isTravelAuthorized(documents: [Document]) -> Bool {
        // Need valid passport + status document + (visa stamp OR advance parole)

        let hasValidPassport = documents.contains { doc in
            doc.type == .passport &&
            (doc.state == .active || doc.state == .expiringSoon)
        }

        let hasVisaOrAP = documents.contains { doc in
            (doc.type == .visaStamp && doc.state == .active) ||
            (doc.type == .advanceParole && doc.state == .active)
        }

        return hasValidPassport && hasVisaOrAP
    }

    private func calculateAuthorizedUntil(documents: [Document]) -> Date? {
        // Find the earliest limiting document
        let limitingDocs = documents.filter { doc in
            [.i20, .ead, .i797, .i94].contains(doc.type)
        }

        return limitingDocs.compactMap { $0.expiryDate }.min()
    }

    private func calculatePermissions(documents: [Document]) -> [String] {
        var permissions: [String] = []

        if isWorkAuthorized(documents: documents) {
            permissions.append("Work full-time")

            // Check for employer restrictions
            if let i797 = documents.first(where: { $0.type == .i797 }) {
                if let employer = i797.extractedFields?.petitioner {
                    permissions.append("Work only for: \(employer)")
                }
            }
        }

        if documents.contains(where: { $0.type == .greenCard }) {
            permissions.append("Work for any employer")
            permissions.append("Live permanently in US")
        }

        permissions.append("Travel domestically")

        return permissions
    }

    private func calculateRestrictions(documents: [Document]) -> [String] {
        var restrictions: [String] = []

        // F-1 specific restrictions
        if documents.contains(where: { $0.type == .i20 }) {
            if !documents.contains(where: { $0.type == .ead || $0.type == .cptAuthorization }) {
                restrictions.append("Cannot work off-campus without authorization")
            }
            restrictions.append("Must maintain full-time enrollment")
        }

        // H-1B restrictions
        if documents.contains(where: { $0.type == .i797 }) {
            restrictions.append("Cannot work for other employers without transfer")
            restrictions.append("Must maintain employment (60-day grace if terminated)")
        }

        // OPT restrictions
        if let ead = documents.first(where: { $0.type == .ead }),
           ead.extractedFields?.eadCategory?.hasPrefix("C03") == true {
            restrictions.append("Cannot be unemployed for more than 90 cumulative days")
            restrictions.append("Work must be related to degree field")
        }

        return restrictions
    }

    private func calculateRequirements(documents: [Document]) -> [String] {
        var requirements: [String] = []

        // F-1 requirements
        if documents.contains(where: { $0.type == .i20 }) {
            requirements.append("Maintain full-time enrollment (unless on approved OPT)")
            requirements.append("Report address changes to school within 10 days")
        }

        // STEM OPT requirements
        if let ead = documents.first(where: { $0.type == .ead }),
           ead.extractedFields?.eadCategory == "C03B" {
            requirements.append("Submit I-983 reports every 6 months")
            requirements.append("Report employer changes to DSO within 10 days")
            requirements.append("Work at least 20 hours/week")
        }

        return requirements
    }
}
```

---

### Feature 5: Security & Authentication

#### Biometric Lock

```swift
import LocalAuthentication

class BiometricAuthService: ObservableObject {
    @Published var isUnlocked = false
    @Published var authError: String?

    func authenticate() {
        let context = LAContext()
        var error: NSError?

        // Check if biometric auth is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Fall back to passcode
            authenticateWithPasscode(context: context)
            return
        }

        let reason = "Unlock StatusVault to view your documents"

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isUnlocked = true
                } else {
                    self.authError = error?.localizedDescription
                    // Offer passcode fallback
                    self.authenticateWithPasscode(context: context)
                }
            }
        }
    }

    private func authenticateWithPasscode(context: LAContext) {
        let reason = "Unlock StatusVault with your device passcode"

        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isUnlocked = true
                } else {
                    self.authError = "Authentication failed"
                }
            }
        }
    }

    func lock() {
        isUnlocked = false
    }
}

// App-level authentication
@main
struct StatusVaultApp: App {
    @StateObject private var authService = BiometricAuthService()

    var body: some Scene {
        WindowGroup {
            if authService.isUnlocked {
                MainTabView()
                    .environmentObject(authService)
            } else {
                LockScreen(authService: authService)
            }
        }
    }
}

struct LockScreen: View {
    @ObservedObject var authService: BiometricAuthService

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("StatusVault")
                .font(.largeTitle)
                .bold()

            Text("Your immigration documents are encrypted and secure")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                authService.authenticate()
            } label: {
                Label("Unlock with Face ID", systemImage: "faceid")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            if let error = authService.authError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            authService.authenticate()
        }
    }
}
```

#### Encryption Service (Enhanced)

```swift
import CryptoKit
import Security

class EncryptionService {
    static let shared = EncryptionService()

    private let keychainService = "com.statusvault.encryption"
    private let keyTag = "encryptionKey"

    // MARK: - Key Management

    func getOrCreateKey() throws -> SymmetricKey {
        // Try to load existing key from Keychain
        if let existingKey = try? loadKeyFromKeychain() {
            return existingKey
        }

        // Generate new key
        let newKey = SymmetricKey(size: .bits256)
        try saveKeyToKeychain(newKey)
        return newKey
    }

    private func saveKeyToKeychain(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keyTag,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete any existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw EncryptionError.keychainError(status)
        }
    }

    private func loadKeyFromKeychain() throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keyTag,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let keyData = result as? Data else {
            throw EncryptionError.keychainError(status)
        }

        return SymmetricKey(data: keyData)
    }

    // MARK: - File Encryption

    func encryptFile(data: Data) throws -> Data {
        let key = try getOrCreateKey()
        let sealedBox = try AES.GCM.seal(data, using: key)

        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }

        return combined
    }

    func decryptFile(encryptedData: Data) throws -> Data {
        let key = try getOrCreateKey()
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }

    // MARK: - High-level helpers

    func saveEncryptedImage(_ image: UIImage, filename: String) throws {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw EncryptionError.invalidImage
        }

        let encryptedData = try encryptFile(data: imageData)
        let url = fileURL(for: filename)
        try encryptedData.write(to: url)
    }

    func loadDecryptedImage(filename: String) throws -> UIImage {
        let url = fileURL(for: filename)
        let encryptedData = try Data(contentsOf: url)
        let decryptedData = try decryptFile(encryptedData: encryptedData)

        guard let image = UIImage(data: decryptedData) else {
            throw EncryptionError.invalidImage
        }

        return image
    }

    func saveEncryptedPDF(_ data: Data, filename: String) throws {
        let encryptedData = try encryptFile(data: data)
        let url = fileURL(for: filename)
        try encryptedData.write(to: url)
    }

    func loadDecryptedPDF(filename: String) throws -> Data {
        let url = fileURL(for: filename)
        let encryptedData = try Data(contentsOf: url)
        return try decryptFile(encryptedData: encryptedData)
    }

    private func fileURL(for filename: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
    }
}

enum EncryptionError: LocalizedError {
    case invalidImage
    case encryptionFailed
    case decryptionFailed
    case keychainError(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Could not process image"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        }
    }
}
```

---

### Feature 6: Document Detail View

```swift
struct DocumentDetailView: View {
    @Bindable var document: Document
    @State private var isEditing = false
    @State private var showingImage = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Document Preview
                DocumentPreviewCard(document: document)
                    .onTapGesture {
                        showingImage = true
                    }

                // Status Badge
                StatusBadge(state: document.state)

                // Key Information
                if let fields = document.extractedFields {
                    ExtractedFieldsCard(fields: fields, type: document.type)
                }

                // Timeline Dates
                TimelineDatesCard(document: document)

                // Related Documents
                if !document.childDocuments.isEmpty {
                    RelatedDocumentsCard(
                        title: "Enabled Documents",
                        documents: document.childDocuments
                    )
                }

                if let parent = document.parentDocument {
                    RelatedDocumentsCard(
                        title: "Authorized By",
                        documents: [parent]
                    )
                }

                if let supersededBy = document.supersededBy {
                    RelatedDocumentsCard(
                        title: "Superseded By",
                        documents: [supersededBy]
                    )
                }

                // User Notes
                NotesSection(notes: $document.userNotes)

                // Actions
                ActionButtons(document: document)
            }
            .padding()
        }
        .navigationTitle(document.type.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $showingImage) {
            FullScreenImageView(document: document)
        }
        .sheet(isPresented: $isEditing) {
            EditDocumentView(document: document)
        }
    }
}

struct ExtractedFieldsCard: View {
    let fields: ExtractedFields
    let type: DocumentType

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Extracted Information")
                .font(.headline)

            switch type {
            case .i20:
                I20Fields(fields: fields)
            case .ead:
                EADFields(fields: fields)
            case .visaStamp:
                VisaFields(fields: fields)
            case .passport:
                PassportFields(fields: fields)
            default:
                GenericFields(fields: fields)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct I20Fields: View {
    let fields: ExtractedFields

    var body: some View {
        VStack(spacing: 12) {
            if let sevis = fields.sevisNumber {
                FieldRow(label: "SEVIS Number", value: sevis)
            }
            if let school = fields.schoolName {
                FieldRow(label: "School", value: school)
            }
            if let program = fields.programName {
                FieldRow(label: "Program", value: program)
            }
            if let start = fields.programStartDate {
                FieldRow(label: "Program Start", value: start.formatted(date: .abbreviated, time: .omitted))
            }
            if let end = fields.programEndDate {
                FieldRow(label: "Program End", value: end.formatted(date: .abbreviated, time: .omitted))
            }
            if let travelSig = fields.travelSignatureDate {
                FieldRow(label: "Travel Signature", value: travelSig.formatted(date: .abbreviated, time: .omitted))
                let expiryDate = Calendar.current.date(byAdding: .month, value: 6, to: travelSig)!
                FieldRow(label: "Signature Valid Until", value: expiryDate.formatted(date: .abbreviated, time: .omitted))
            }
        }
    }
}

struct FieldRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .bold()
        }
    }
}
```

---

## Implementation Phases

### Phase 1: Foundation (Week 1)
**Goal:** Basic app structure with secure storage

- [x] Xcode project setup
- [x] SwiftData models (Document, ExtractedFields)
- [x] Biometric authentication (Face ID)
- [x] Basic UI navigation (TabView)
- [x] Camera capture view
- [x] Encrypted file storage service
- [x] Basic document list view

**Deliverable:** Can take photos, save encrypted locally, view in list

---

### Phase 2: OCR & Intelligence (Week 2)
**Goal:** Automatic document processing

- [ ] Vision Framework integration
- [ ] Document type detection
- [ ] Field extraction for top 5 types:
  - [ ] I-20 parser
  - [ ] EAD parser
  - [ ] Visa stamp parser
  - [ ] Passport parser
  - [ ] I-94 parser
- [ ] Document lifecycle state logic
- [ ] Supersession detection
- [ ] Status engine (calculate current status)

**Deliverable:** Upload I-20, automatically extracts SEVIS, dates, status

---

### Phase 3: Timeline & Status (Week 3)
**Goal:** Visual timeline and status tracking

- [ ] Timeline canvas view
- [ ] Document bars with color coding
- [ ] Status card ("What can I do now?")
- [ ] Document detail view
- [ ] Edit extracted fields
- [ ] Deadline alerts (local notifications)

**Deliverable:** Full timeline view showing immigration journey

---

### Phase 4: Polish & Testing (Week 4)
**Goal:** Production-ready for personal use

- [ ] UI polish and animations
- [ ] Error handling
- [ ] Edge cases (missing fields, bad OCR)
- [ ] Settings view
- [ ] Export functionality (PDF)
- [ ] Comprehensive testing
- [ ] TestFlight deployment

**Deliverable:** Deployed to personal iPhone, ready to use

---

## User Flows

### Flow 1: First-Time Setup

```
Launch app
  ↓
Face ID prompt
  ↓
Welcome screen
  • "Your immigration story, organized"
  • "All documents stay encrypted on your device"
  • [Get Started]
  ↓
Empty state
  • "Add your first document"
  • Large + button
  ↓
[User adds first document via camera]
  ↓
OCR extracts fields
  ↓
"Great! Your I-20 has been added"
  • Shows extracted info
  • "Add more documents to build your timeline"
  ↓
Timeline shows first document
```

### Flow 2: Daily Use - Check Status

```
Open app
  ↓
Face ID unlock
  ↓
Timeline view (main screen)
  ↓
Top card shows:
  • "F-1 OPT (STEM Extension)"
  • "Work Authorized: Yes"
  • "Valid until: Jun 15, 2026 (427 days)"
  ↓
Scroll timeline to see all documents
  ↓
Tap any document → Detail view
  • View full image
  • See extracted fields
  • Read notes
```

### Flow 3: Adding a New Document

```
Timeline view
  ↓
Tap + button
  ↓
Action sheet:
  • Take Photo
  • Choose from Photos
  • Import PDF
  ↓
[User selects "Take Photo"]
  ↓
Camera view
  • Guide overlay
  • "Align document in frame"
  • Auto-capture when stable
  ↓
Preview
  • Crop/rotate tools
  • [Retake] or [Use Photo]
  ↓
Processing screen
  • "Analyzing your EAD card..."
  • Progress spinner
  ↓
Review extracted fields
  • Document type: EAD
  • Category: C03B
  • Valid from: Jun 16, 2024
  • Valid until: Jun 15, 2026
  • USCIS Number: SRC-XXX-XXX
  • [Edit] or [Save]
  ↓
Document saved
  • Toast: "EAD card added ✓"
  • Timeline auto-scrolls to new document
  • Status card updates
```

---

## Edge Cases & Error Handling

### OCR Failures

**Problem:** Poor image quality, low confidence extraction

**Solution:**
```swift
if ocrConfidence < 0.6 {
    // Show warning banner
    "Low confidence extraction. Please review fields carefully."
    // Allow manual entry
    // Highlight low-confidence fields in yellow
}
```

### Missing Critical Fields

**Problem:** Document number not found

**Solution:**
```swift
if extractedFields.documentNumber == nil {
    // Prompt user
    "We couldn't find the document number. Please enter it manually."
    // Required field - can't save without it
}
```

### Duplicate Documents

**Problem:** User uploads same document twice

**Solution:**
```swift
func detectDuplicate(newDoc: Document, existing: [Document]) -> Document? {
    for doc in existing {
        if doc.type == newDoc.type,
           doc.extractedFields?.documentNumber == newDoc.extractedFields?.documentNumber {
            // Found potential duplicate
            return doc
        }
    }
    return nil
}

// In UI:
if let duplicate = detectDuplicate(...) {
    showAlert(
        "This document may already exist",
        "Do you want to replace it or keep both?"
    )
}
```

### Biometric Auth Unavailable

**Problem:** Device doesn't have Face ID/Touch ID

**Solution:**
```swift
// Fall back to device passcode
context.evaluatePolicy(.deviceOwnerAuthentication, ...)

// If that fails, optional: app-specific PIN
// For V1: Just require device passcode
```

### File System Errors

**Problem:** Out of storage, file corruption

**Solution:**
```swift
do {
    try encryptedData.write(to: url)
} catch let error as NSError {
    if error.domain == NSCocoaErrorDomain {
        switch error.code {
        case NSFileWriteOutOfSpaceError:
            showAlert("Storage full", "Please free up space and try again")
        case NSFileWriteNoPermissionError:
            showAlert("Permission denied", "Please check app permissions")
        default:
            showAlert("Save failed", "Error: \(error.localizedDescription)")
        }
    }
}
```

---

## Testing Strategy

### Unit Tests

```swift
class DocumentLifecycleTests: XCTestCase {
    func testI20Supersession() {
        let old = createMockI20(effectiveDate: date("2020-01-01"))
        let new = createMockI20(effectiveDate: date("2023-01-01"))

        let detector = SupersessionDetector()
        detector.detectSupersession(newDocument: new, existingDocuments: [old])

        XCTAssertEqual(old.state, .superseded)
        XCTAssertEqual(old.supersededBy?.id, new.id)
    }

    func testEADExpiryState() {
        let ead = createMockEAD(validUntil: Date().addingTimeInterval(60 * 86400)) // 60 days

        let engine = DocumentLifecycleEngine()
        engine.updateDocumentStates(documents: [ead])

        XCTAssertEqual(ead.state, .expiringSoon)
    }

    func testStatusEngine_F1OPT() {
        let i20 = createMockI20(programEnd: date("2023-05-15"))
        let ead = createMockEAD(category: "C03B", validUntil: date("2026-06-15"))

        let engine = StatusEngine()
        let status = engine.calculateCurrentStatus(documents: [i20, ead])

        XCTAssertEqual(status.immigrationStatus, "F-1 OPT (STEM Extension)")
        XCTAssertTrue(status.workAuthorized)
    }
}

class OCRServiceTests: XCTestCase {
    func testExtractSEVISNumber() {
        let text = "SEVIS ID: N0012345678"
        let extractor = FieldExtractor()
        let fields = extractor.extractFields(from: text, type: .i20)

        XCTAssertEqual(fields.sevisNumber, "N0012345678")
    }

    func testExtractUSCISNumber() {
        let text = "Receipt Number: SRC-21-123-45678"
        let extractor = FieldExtractor()
        let fields = extractor.extractFields(from: text, type: .i797)

        XCTAssertEqual(fields.receiptNumber, "SRC-21-123-45678")
    }
}
```

### Integration Tests

```swift
class E2EDocumentFlowTests: XCTestCase {
    func testFullDocumentCapturePipeline() async throws {
        // Load test image
        let testImage = UIImage(named: "test_i20")!

        // Run OCR
        let ocrService = OCRService()
        let text = try await ocrService.extractText(from: testImage)

        // Detect type
        let detector = DocumentTypeDetector()
        let type = detector.detectType(from: text)
        XCTAssertEqual(type, .i20)

        // Extract fields
        let extractor = FieldExtractor()
        let fields = extractor.extractFields(from: text, type: type)
        XCTAssertNotNil(fields.sevisNumber)

        // Save document
        let doc = Document(type: type, extractedFields: fields)
        // ... save to SwiftData

        // Verify encryption
        let encryptionService = EncryptionService.shared
        try encryptionService.saveEncryptedImage(testImage, filename: "test.jpg")
        let loaded = try encryptionService.loadDecryptedImage(filename: "test.jpg")
        XCTAssertNotNil(loaded)
    }
}
```

### UI Tests

```swift
class StatusVaultUITests: XCTestCase {
    func testBiometricAuth() {
        let app = XCUIApplication()
        app.launch()

        // Should show lock screen
        XCTAssertTrue(app.staticTexts["StatusVault"].exists)
        XCTAssertTrue(app.buttons["Unlock with Face ID"].exists)

        // Tap unlock
        app.buttons["Unlock with Face ID"].tap()

        // Simulate biometric success (in simulator)
        // ... navigate to timeline
    }

    func testAddDocument() {
        let app = XCUIApplication()
        app.launch()

        // Unlock
        unlockApp(app)

        // Tap add button
        app.buttons["+"].tap()

        // Select camera
        app.buttons["Take Photo"].tap()

        // Should show camera view
        XCTAssertTrue(app.otherElements["cameraView"].exists)
    }
}
```

---

## Performance Considerations

### OCR Performance
- **Target:** < 2 seconds for typical document
- **Optimization:** Run OCR on background thread
- **Quality:** Use `.accurate` recognition level (higher quality, slower)

```swift
func processDocument(_ image: UIImage) async {
    await MainActor.run {
        showLoadingIndicator("Analyzing document...")
    }

    async let ocrTask = ocrService.extractText(from: image)
    async let thumbnailTask = generateThumbnail(image)

    let (text, thumbnail) = await (try? ocrTask, thumbnailTask)

    await MainActor.run {
        hideLoadingIndicator()
        presentResults(text: text, thumbnail: thumbnail)
    }
}
```

### Image Compression
- **Storage:** JPEG at 85% quality (good balance)
- **Thumbnails:** 200x300px for timeline
- **Full images:** Keep original resolution for OCR accuracy

### Database Queries
- **Index:** `@Query(sort: \Document.dateAdded, order: .reverse)`
- **Pagination:** Load 50 documents at a time
- **Caching:** Cache current status snapshot

---

## Security Considerations

### Threat Model

**Threats we protect against:**
1. ✅ Device theft → Biometric lock + encryption
2. ✅ Backup extraction → Files encrypted before iCloud
3. ✅ Local file access → AES-256 encryption at rest
4. ✅ Screenshot capture → Can add screen recording detection (V2)

**Out of scope for V1:**
1. ❌ State-level adversaries
2. ❌ Jailbroken device attacks
3. ❌ Physical coercion attacks

### Data Retention

```swift
class DataDeletionService {
    func deleteAllData() throws {
        // Delete all documents from SwiftData
        let documents = try modelContext.fetch(FetchDescriptor<Document>())
        for doc in documents {
            modelContext.delete(doc)
        }
        try modelContext.save()

        // Delete all encrypted files
        let fileManager = FileManager.default
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let files = try fileManager.contentsOfDirectory(at: documentsDir, includingPropertiesForKeys: nil)
        for file in files {
            try fileManager.removeItem(at: file)
        }

        // Delete encryption key from Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.statusvault.encryption"
        ]
        SecItemDelete(query as CFDictionary)

        print("All user data permanently deleted")
    }
}
```

### Privacy Policy (Plain English)

```
StatusVault Privacy Policy

What we collect:
- Nothing. Your documents stay on your device.

What we do with your data:
- Nothing. We never see it.

Who we share with:
- No one. There's no backend server.

Your rights:
- Delete everything anytime: Settings → Delete All Data

Optional iCloud:
- If you enable iCloud backup, your encrypted documents sync via Apple
- We still can't see them (they're encrypted before upload)
- Apple's privacy policy applies to iCloud data

Questions? hello@statusvault.app
```

---

## Future Enhancements (V2+)

### Backend Integration (When Needed)
```
Use cases for adding a backend:
1. AI advisor (Claude API calls)
2. USCIS case tracking (scrape processing times)
3. Multi-device sync (beyond iCloud)
4. Attorney sharing (temporary secure links)
5. Community features (anonymous Q&A)

Tech stack recommendation:
- Firebase Cloud Functions (serverless)
- Firestore (NoSQL database)
- Firebase Auth (user management)
- OR: Supabase (open source alternative)
```

### Advanced Features
- **Smart recommendations:** "Based on your timeline, you're eligible for H-1B in 6 months"
- **Attorney integration:** Direct export to immigration lawyer portals
- **Travel planner:** "You need a visa appointment 60 days before travel"
- **Document templates:** Auto-fill I-765, I-131 based on your vault
- **Family accounts:** Manage spouse/children documents
- **Web app:** View (read-only) on desktop

---

## Success Metrics (Personal Use)

Since this is V1 for personal use, success is measured by:

1. **Reliability**
   - [ ] All documents stored successfully (0 data loss)
   - [ ] Face ID works 100% of the time
   - [ ] App doesn't crash

2. **Utility**
   - [ ] Can find any document in < 10 seconds
   - [ ] OCR accuracy > 90% for key fields
   - [ ] Status card always shows correct current status
   - [ ] Never miss a deadline due to lack of tracking

3. **Usability**
   - [ ] Upload new document in < 60 seconds
   - [ ] Timeline is visually clear and informative
   - [ ] App feels fast and responsive

4. **Adoption (if shared)**
   - [ ] 10 beta testers using daily within 1 month
   - [ ] Positive feedback on ease of use
   - [ ] Feature requests indicate real pain points solved

---

## Development Environment Setup

### Prerequisites
```bash
# Xcode 15.0+
# macOS 14.0+ (for SwiftData)
# iOS 17.0+ target device/simulator
```

### Project Structure
```
StatusVault/
├── StatusVaultApp.swift
├── Models/
│   ├── Document.swift
│   ├── ExtractedFields.swift
│   ├── StatusSnapshot.swift
│   └── TimelineEvent.swift
├── Views/
│   ├── Timeline/
│   │   ├── TimelineView.swift
│   │   ├── TimelineCanvas.swift
│   │   ├── DocumentBar.swift
│   │   └── EventMarker.swift
│   ├── Documents/
│   │   ├── DocumentDetailView.swift
│   │   ├── DocumentListView.swift
│   │   └── EditDocumentView.swift
│   ├── Camera/
│   │   ├── CameraView.swift
│   │   ├── DocumentScannerView.swift
│   │   └── ImagePreviewView.swift
│   ├── Status/
│   │   ├── StatusCardView.swift
│   │   └── AlertsView.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── AboutView.swift
├── Services/
│   ├── OCR/
│   │   ├── OCRService.swift
│   │   ├── DocumentTypeDetector.swift
│   │   └── FieldExtractor.swift
│   ├── Storage/
│   │   ├── EncryptionService.swift
│   │   └── FileStorageService.swift
│   ├── Auth/
│   │   └── BiometricAuthService.swift
│   └── Logic/
│       ├── DocumentLifecycleEngine.swift
│       ├── SupersessionDetector.swift
│       └── StatusEngine.swift
├── Utilities/
│   ├── Extensions/
│   │   ├── Date+Extensions.swift
│   │   ├── String+Extensions.swift
│   │   └── Color+Extensions.swift
│   └── Constants.swift
├── Resources/
│   ├── Assets.xcassets
│   └── Localizable.strings
└── Tests/
    ├── UnitTests/
    ├── IntegrationTests/
    └── UITests/
```

### Dependencies
```swift
// Package.swift or use Swift Package Manager in Xcode

// None needed for V1! All native:
// - SwiftUI (built-in)
// - SwiftData (built-in iOS 17+)
// - Vision (built-in)
// - CryptoKit (built-in)
// - LocalAuthentication (built-in)
// - PDFKit (built-in)
```

---

## Conclusion

StatusVault V1 is a **fully local, privacy-first iOS app** that solves a real problem: managing the complex lifecycle of immigration documents.

**Key Design Principles:**
1. **Privacy First:** Everything stays on device, encrypted
2. **Intelligence Built-In:** OCR + lifecycle rules automate tracking
3. **Simple UX:** Timeline makes complex document chains visual
4. **No Backend Required:** Faster to build, zero hosting costs, maximum privacy

**What makes this impressive as a side project:**
- Real-world domain expertise (immigration law complexity)
- On-device AI/ML (Vision Framework)
- Strong security posture (encryption, biometrics)
- Complex state management (document lifecycle engine)
- Polished native iOS experience

**Ready to ship when:**
- All V1 features implemented
- Works reliably on your personal documents
- No crashes, smooth performance
- Tested on real iPhone (not just simulator)

---

**Next Step:** Start building! Begin with Phase 1 (Foundation) and let's get the basic app structure working.
