//
//  AppSettings.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import Foundation
import SwiftData

@Model
final class AppSettings {
    var id: UUID
    var notificationsEnabled: Bool
    var daysBeforeDueNotification: Int
    var weeklyReviewEnabled: Bool
    var defaultCurrencyCode: String
    var biometricLockEnabled: Bool
    var languageOverride: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        notificationsEnabled: Bool = true,
        daysBeforeDueNotification: Int = 2,
        weeklyReviewEnabled: Bool = false,
        defaultCurrencyCode: String = "RON",
        biometricLockEnabled: Bool = false,
        languageOverride: String? = nil
    ) {
        self.id = UUID()
        self.notificationsEnabled = notificationsEnabled
        self.daysBeforeDueNotification = daysBeforeDueNotification
        self.weeklyReviewEnabled = weeklyReviewEnabled
        self.defaultCurrencyCode = defaultCurrencyCode
        self.biometricLockEnabled = biometricLockEnabled
        self.languageOverride = languageOverride
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func updateTimestamp() {
        self.updatedAt = Date()
    }
    
    // Singleton-style access
    static func getOrCreate(in context: ModelContext) -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        
        do {
            let existingSettings = try context.fetch(descriptor)
            if let settings = existingSettings.first {
                return settings
            }
        } catch {
            print("Failed to fetch AppSettings: \(error)")
        }
        
        // Create new settings if none exist
        let newSettings = AppSettings()
        context.insert(newSettings)
        
        do {
            try context.save()
        } catch {
            print("Failed to save new AppSettings: \(error)")
        }
        
        return newSettings
    }
}



