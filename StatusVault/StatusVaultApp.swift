//
//  StatusVaultApp.swift
//  StatusVault
//
//  Created by Cam on 2/26/26.
//

import SwiftUI
import SwiftData

@main
struct StatusVaultApp: App {
    @StateObject private var authService = AuthService()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Document.self,
            ExtractedFields.self,
            StatusSnapshot.self,
            TimelineEvent.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                MainTabView(authService: authService)
                    .modelContainer(sharedModelContainer)
            } else {
                LockScreen(authService: authService)
            }
        }
    }
}
