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
            AppSettings.self,
            IncomeSource.self,
            IncomePayment.self,
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
                    initializeNotificationManager()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func initializeNotificationManager() {
        let context = sharedModelContainer.mainContext
        let appSettings = AppSettings.getOrCreate(in: context)
        NotificationManager.shared.setAppSettings(appSettings)
        
        // CONSISTENCY FIX: Reconcile notifications on app launch
        Task {
            do {
                let loans = try context.fetch(FetchDescriptor<Loan>())
                await NotificationManager.shared.reconcileAllPaymentNotifications(with: loans)
            } catch {
                print("Failed to reconcile notifications on app launch: \(error)")
            }
        }
    }
}
