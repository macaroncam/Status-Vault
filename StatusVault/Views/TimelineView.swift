import SwiftUI
import SwiftData

struct TimelineView: View {
    let documents: [Document]
    @State private var currentStatus: StatusSnapshot?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if let status = currentStatus {
                            CurrentStatusCard(status: status)
                        }

                        if documents.isEmpty {
                            EmptyStateView()
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Documents")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)

                                ForEach(documents.sorted(by: { ($0.createdAt) > ($1.createdAt) })) { document in
                                    DocumentRow(document: document)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Status Timeline")
            .onAppear {
                updateStatus()
            }
            .onChange(of: documents) { _, _ in
                updateStatus()
            }
        }
    }

    private func updateStatus() {
        currentStatus = StatusEngine.shared.calculateCurrentStatus(documents: Array(documents))
    }
}

struct CurrentStatusCard: View {
    let status: StatusSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)

                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Status")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(status.currentStatus)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()
            }

            Divider()

            VStack(spacing: 12) {
                StatusRow(icon: "briefcase.fill", label: "Work Authorization", value: status.canWork ? "Authorized" : "Not Authorized", color: status.canWork ? .green : .red)

                if let workExpiry = status.workExpiryDate {
                    HStack {
                        Spacer()
                        Text("Expires: \(workExpiry, style: .date)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                StatusRow(icon: "graduationcap.fill", label: "Study Authorization", value: status.canStudy ? "Authorized" : "Not Authorized", color: status.canStudy ? .green : .gray)
            }

            if !status.warnings.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Warnings")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    ForEach(status.warnings, id: \.self) { warning in
                        Text("• \(warning)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
}

struct StatusRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(color)
        }
    }
}

struct DocumentRow: View {
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

            VStack(alignment: .leading, spacing: 4) {
                Text(document.type.rawValue)
                    .font(.headline)

                if let expiryDate = document.expiryDate {
                    Text("Expires: \(expiryDate, style: .date)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(document.state.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(document.state.color))
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)
            }

            Text("No Documents Yet")
                .font(.title2)
                .fontWeight(.bold)

            Text("Add your first immigration document to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }
}
