//
//  AppResetService.swift
//  monetiq
//
//  Created by Florin Mihai on 14.12.2025.
//

import Foundation
import SwiftData
import UserNotifications

@MainActor
class AppResetService {
    static let shared = AppResetService()
    
    private init() {}
    
    /// Completely resets the app to a fresh install state
    /// - Parameter modelContext: The SwiftData model context
    /// - Returns: A reset token that can be used to force UI refresh
    func resetApp(modelContext: ModelContext) async -> UUID {
        print("🔄 Starting complete app reset...")
        
        // 1. Cancel all notifications
        await cancelAllNotifications()
        
        // 2. Delete all SwiftData entities
        await deleteAllSwiftDataEntities(modelContext: modelContext)
        
        // 3. Reset app settings to defaults
        resetAppSettings(modelContext: modelContext)
        
        // 4. Clear any UserDefaults/AppStorage if needed
        clearUserDefaults()
        
        // 5. Trigger UI refresh via AppState
        AppState.shared.triggerAppReset()
        let resetToken = AppState.shared.resetToken
        
        print("✅ App reset completed successfully")
        return resetToken
    }
    
    private func cancelAllNotifications() async {
        print("🔄 Cancelling all notifications...")
        
        let center = UNUserNotificationCenter.current()
        
        // Cancel all pending notifications
        center.removeAllPendingNotificationRequests()
        
        // Remove all delivered notifications
        center.removeAllDeliveredNotifications()
        
        print("✅ All notifications cancelled")
    }
    
    private func deleteAllSwiftDataEntities(modelContext: ModelContext) async {
        print("🔄 Deleting all SwiftData entities...")
        
        do {
            // Delete all Payments
            let paymentDescriptor = FetchDescriptor<Payment>()
            let payments = try modelContext.fetch(paymentDescriptor)
            for payment in payments {
                modelContext.delete(payment)
            }
            print("✅ Deleted \(payments.count) payments")
            
            // Delete all Loans
            let loanDescriptor = FetchDescriptor<Loan>()
            let loans = try modelContext.fetch(loanDescriptor)
            for loan in loans {
                modelContext.delete(loan)
            }
            print("✅ Deleted \(loans.count) loans")
            
            // Delete all Counterparties
            let counterpartyDescriptor = FetchDescriptor<Counterparty>()
            let counterparties = try modelContext.fetch(counterpartyDescriptor)
            for counterparty in counterparties {
                modelContext.delete(counterparty)
            }
            print("✅ Deleted \(counterparties.count) counterparties")
            
            // Delete all AppSettings (they will be recreated with defaults)
            let settingsDescriptor = FetchDescriptor<AppSettings>()
            let settings = try modelContext.fetch(settingsDescriptor)
            for setting in settings {
                modelContext.delete(setting)
            }
            print("✅ Deleted \(settings.count) app settings")
            
            // Save the deletions
            try modelContext.save()
            print("✅ All SwiftData entities deleted and saved")
            
        } catch {
            print("❌ Error deleting SwiftData entities: \(error)")
        }
    }
    
    private func resetAppSettings(modelContext: ModelContext) {
        print("🔄 Resetting app settings to defaults...")
        
        // Create new default settings
        let defaultSettings = AppSettings(
            notificationsEnabled: true,
            daysBeforeDueNotification: 2,
            weeklyReviewEnabled: false,
            defaultCurrencyCode: "RON",
            biometricLockEnabled: false,
            languageOverride: nil, // System default
            appearanceMode: .system // System default
        )
        
        modelContext.insert(defaultSettings)
        
        do {
            try modelContext.save()
            print("✅ Default app settings created")
        } catch {
            print("❌ Error creating default settings: \(error)")
        }
    }
    
    private func clearUserDefaults() {
        print("🔄 Clearing UserDefaults...")
        
        // Clear any app-specific UserDefaults keys if they exist
        // For now, we're using SwiftData for settings, but this is here for future use
        let _ = UserDefaults.standard
        
        // Remove any app-specific keys (add them here if needed in the future)
        // UserDefaults.standard.removeObject(forKey: "SomeAppSpecificKey")
        
        print("✅ UserDefaults cleared")
    }
}
