//
//  monetiqApp.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import SwiftUI
import SwiftData

@main
struct monetiqApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Counterparty.self,
            Loan.self,
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
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
