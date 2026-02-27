import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var documents: [Document]
    @ObservedObject var authService: AuthService

    var body: some View {
        TabView {
            TimelineView(documents: documents)
                .tabItem {
                    Label("Timeline", systemImage: "timeline.selection")
                }

            DocumentListView(documents: documents)
                .tabItem {
                    Label("Documents", systemImage: "doc.fill")
                }

            ChatView()
                .tabItem {
                    Label("Assistant", systemImage: "bubble.left.and.bubble.right.fill")
                }

            SettingsView(authService: authService)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
