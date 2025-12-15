//
//  AppSettings.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import Foundation
import SwiftData
import SwiftUI

enum AppearanceMode: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system:
            return NSLocalizedString("appearance_system", comment: "System Default")
        case .light:
            return NSLocalizedString("appearance_light", comment: "Light")
        case .dark:
            return NSLocalizedString("appearance_dark", comment: "Dark")
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

@Model
final class AppSettings {
    var id: UUID
    var notificationsEnabled: Bool
    var daysBeforeDueNotification: Int
    var weeklyReviewEnabled: Bool
    var defaultCurrencyCode: String
    var biometricLockEnabled: Bool
    var languageOverride: String?
    var appearanceModeRaw: String?
    var createdAt: Date
    var updatedAt: Date
    
    // Computed property to work with AppearanceMode enum
    var appearanceMode: AppearanceMode {
        get {
            guard let rawValue = appearanceModeRaw else { return .system }
            return AppearanceMode(rawValue: rawValue) ?? .system
        }
        set {
            appearanceModeRaw = newValue.rawValue
        }
    }
    
    init(
        notificationsEnabled: Bool = true,
        daysBeforeDueNotification: Int = 2,
        weeklyReviewEnabled: Bool = false,
        defaultCurrencyCode: String = "RON",
        biometricLockEnabled: Bool = false,
        languageOverride: String? = nil,
        appearanceMode: AppearanceMode = .system
    ) {
        self.id = UUID()
        self.notificationsEnabled = notificationsEnabled
        self.daysBeforeDueNotification = daysBeforeDueNotification
        self.weeklyReviewEnabled = weeklyReviewEnabled
        self.defaultCurrencyCode = defaultCurrencyCode
        self.biometricLockEnabled = biometricLockEnabled
        self.languageOverride = languageOverride
        self.appearanceModeRaw = appearanceMode.rawValue
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
                // Ensure appearanceModeRaw has a valid value for migration
                if settings.appearanceModeRaw == nil {
                    settings.appearanceModeRaw = AppearanceMode.system.rawValue
                    settings.updateTimestamp()
                    try context.save()
                }
                return settings
            }
        } catch {
            print("Failed to fetch AppSettings: \(error)")
            // If there's an error (likely due to schema changes), delete all settings and recreate
            do {
                let allSettings = try context.fetch(FetchDescriptor<AppSettings>())
                for setting in allSettings {
                    context.delete(setting)
                }
                try context.save()
            } catch {
                print("Failed to clean up old AppSettings: \(error)")
            }
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



