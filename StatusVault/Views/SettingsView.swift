import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var documents: [Document]
    @ObservedObject var authService: AuthService

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                List {
                    Section {
                        if let email = authService.currentUserEmail {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.blue)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Signed in as")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Text(email)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }

                    Section("Statistics") {
                        StatRow(icon: "doc.fill", label: "Total Documents", value: "\(documents.count)", color: .blue)
                        StatRow(icon: "checkmark.circle.fill", label: "Active Documents", value: "\(activeDocumentsCount)", color: .green)
                        StatRow(icon: "exclamationmark.triangle.fill", label: "Expiring Soon", value: "\(expiringSoonCount)", color: .orange)
                    }

                    Section("Security") {
                        InfoRow(icon: "lock.shield.fill", label: "Encryption", value: "AES-256", color: .green)
                        InfoRow(icon: "icloud.slash.fill", label: "Cloud Sync", value: "Disabled", color: .gray)
                    }

                    Section {
                        Button(role: .destructive, action: {
                            authService.logout()
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.square.fill")
                                Text("Sign Out")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
        }
    }

    private var activeDocumentsCount: Int {
        documents.filter { $0.state == .active }.count
    }

    private var expiringSoonCount: Int {
        documents.filter { $0.state == .expiringSoon }.count
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 16))
            }

            Text(label)
                .font(.subheadline)

            Spacer()

            Text(value)
                .font(.headline)
                .foregroundStyle(color)
        }
        .padding(.vertical, 4)
    }
}

struct InfoRow: View {
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
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
