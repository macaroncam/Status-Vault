import SwiftUI
import SwiftData

struct DocumentListView: View {
    @Environment(\.modelContext) private var modelContext
    let documents: [Document]
    @State private var showingAddDocument = false
    @State private var selectedDocument: Document?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                if documents.isEmpty {
                    EmptyStateView()
                } else {
                    List {
                        ForEach(documents.sorted(by: { ($0.createdAt) > ($1.createdAt) })) { document in
                            DocumentListRow(document: document)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedDocument = document
                                }
                        }
                        .onDelete(perform: deleteDocuments)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Documents")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingAddDocument = true
                    }) {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddDocument) {
                AddDocumentView()
            }
            .sheet(item: $selectedDocument) { document in
                DocumentDetailView(document: document)
            }
        }
    }

    private func deleteDocuments(at offsets: IndexSet) {
        for index in offsets {
            let sortedDocs = documents.sorted(by: { ($0.createdAt) > ($1.createdAt) })
            modelContext.delete(sortedDocs[index])
        }
    }
}

struct DocumentListRow: View {
    let document: Document

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(document.type.color).opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: document.type.icon)
                    .foregroundStyle(Color(document.type.color))
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(document.type.rawValue)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let fields = document.extractedFields, let name = fields.fullName {
                    Text(name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let expiryDate = document.expiryDate {
                    Text("Expires: \(expiryDate, style: .date)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(document.state.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(document.state.color))
                    )
            }
        }
        .padding(.vertical, 4)
    }
}
