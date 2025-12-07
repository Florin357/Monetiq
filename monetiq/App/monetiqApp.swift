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
            Payment.self,
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
                .onAppear {
                    // Add sample data for development
                    #if DEBUG
                    addSampleDataIfNeeded()
                    #endif
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func addSampleDataIfNeeded() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Loan>()
        
        do {
            let existingLoans = try context.fetch(descriptor)
            if existingLoans.isEmpty {
                SampleData.createSampleData(in: context)
            }
        } catch {
            print("Failed to check for existing data: \(error)")
        }
    }
}
