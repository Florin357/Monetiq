//
//  SettingsView.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [AppSettings]
    
    @State private var appSettings: AppSettings?
    @State private var darkModeEnabled = true // Keep as local state for now
    
    private var notificationManager: NotificationManager {
        NotificationManager.shared
    }
    
    private let currencies = ["RON", "EUR", "USD", "GBP"]
    private let daysBeforeOptions = [1, 2, 3, 5, 7]
    
    private var settings: AppSettings {
        if let appSettings = appSettings {
            return appSettings
        }
        
        let settings = AppSettings.getOrCreate(in: modelContext)
        DispatchQueue.main.async {
            self.appSettings = settings
            notificationManager.setAppSettings(settings)
        }
        return settings
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MonetiqTheme.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
                    Text("Settings")
                        .font(MonetiqTheme.Typography.largeTitle)
                        .foregroundColor(MonetiqTheme.Colors.onBackground)
                    
                    Text("Customize your Monetiq experience")
                        .font(MonetiqTheme.Typography.callout)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, MonetiqTheme.Spacing.md)
                
                // General Settings
                SettingsSection(title: "General") {
                    SettingsToggleRow(
                        title: "Push Notifications",
                        subtitle: "Get notified about upcoming payments",
                        isOn: Binding(
                            get: { settings.notificationsEnabled },
                            set: { newValue in
                                let oldValue = settings.notificationsEnabled
                                settings.notificationsEnabled = newValue
                                settings.updateTimestamp()
                                saveContext()
                                
                                if oldValue != newValue {
                                    handleNotificationsToggle(enabled: newValue)
                                }
                            }
                        )
                    )
                    
                    SettingsPickerRow(
                        title: "Days Before Due",
                        subtitle: "Notification timing",
                        selection: Binding(
                            get: { String(settings.daysBeforeDueNotification) },
                            set: { newValue in
                                let oldValue = settings.daysBeforeDueNotification
                                if let intValue = Int(newValue) {
                                    settings.daysBeforeDueNotification = intValue
                                    settings.updateTimestamp()
                                    saveContext()
                                    
                                    if oldValue != intValue {
                                        handleDaysBeforeChange()
                                    }
                                }
                            }
                        ),
                        options: daysBeforeOptions.map(String.init)
                    )
                    
                    SettingsToggleRow(
                        title: "Weekly Review",
                        subtitle: "Weekly financial review reminder",
                        isOn: Binding(
                            get: { settings.weeklyReviewEnabled },
                            set: { newValue in
                                let oldValue = settings.weeklyReviewEnabled
                                settings.weeklyReviewEnabled = newValue
                                settings.updateTimestamp()
                                saveContext()
                                
                                if oldValue != newValue {
                                    handleWeeklyReviewToggle(enabled: newValue)
                                }
                            }
                        )
                    )
                    
                    SettingsPickerRow(
                        title: "Default Currency",
                        subtitle: "Currency for new loans",
                        selection: Binding(
                            get: { settings.defaultCurrencyCode },
                            set: { newValue in
                                settings.defaultCurrencyCode = newValue
                                settings.updateTimestamp()
                                saveContext()
                            }
                        ),
                        options: currencies
                    )
                }
                
                // Security Settings
                SettingsSection(title: "Security") {
                    SettingsToggleRow(
                        title: "Biometric Authentication",
                        subtitle: "Use Face ID or Touch ID to unlock",
                        isOn: Binding(
                            get: { settings.biometricLockEnabled },
                            set: { newValue in
                                settings.biometricLockEnabled = newValue
                                settings.updateTimestamp()
                                saveContext()
                            }
                        )
                    )
                }
                
                // Appearance Settings
                SettingsSection(title: "Appearance") {
                    SettingsToggleRow(
                        title: "Dark Mode",
                        subtitle: "Use dark theme",
                        isOn: $darkModeEnabled
                    )
                }
                
                // Developer Section (for testing)
                #if DEBUG
                SettingsSection(title: "Developer") {
                    SettingsActionRow(
                        title: "Test Notification",
                        subtitle: "Send a test notification in 5 seconds",
                        action: testNotification
                    )
                    
                    SettingsActionRow(
                        title: "View Pending Notifications",
                        subtitle: "Check scheduled notifications",
                        action: viewPendingNotifications
                    )
                }
                #endif
                
                // About Section
                SettingsSection(title: "About") {
                    SettingsActionRow(
                        title: "Version",
                        subtitle: "1.0.0",
                        action: {}
                    )
                    
                    SettingsActionRow(
                        title: "Privacy Policy",
                        subtitle: "View our privacy policy",
                        action: openPrivacyPolicy
                    )
                    
                    SettingsActionRow(
                        title: "Terms of Service",
                        subtitle: "View terms and conditions",
                        action: openTermsOfService
                    )
                }
                
                Spacer(minLength: MonetiqTheme.Spacing.xl)
            }
            .padding(.vertical, MonetiqTheme.Spacing.lg)
        }
        .monetiqBackground()
        .onAppear {
            // Initialize settings and notification manager
            let currentSettings = AppSettings.getOrCreate(in: modelContext)
            appSettings = currentSettings
            notificationManager.setAppSettings(currentSettings)
        }
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
    
    private func handleNotificationsToggle(enabled: Bool) {
        Task {
            if enabled {
                // Request authorization and reschedule all notifications
                let authorized = await notificationManager.requestAuthorizationIfNeeded()
                if authorized {
                    await rescheduleAllNotifications()
                }
            } else {
                // Cancel all notifications
                await notificationManager.cancelAllNotifications()
            }
        }
    }
    
    private func handleDaysBeforeChange() {
        Task {
            if settings.notificationsEnabled {
                await rescheduleAllNotifications()
            }
        }
    }
    
    private func handleWeeklyReviewToggle(enabled: Bool) {
        Task {
            if enabled {
                await notificationManager.scheduleWeeklyReviewNotification()
            } else {
                await notificationManager.cancelWeeklyReviewNotification()
            }
        }
    }
    
    private func rescheduleAllNotifications() async {
        // Fetch all loans and reschedule notifications
        let descriptor = FetchDescriptor<Loan>()
        do {
            let loans = try modelContext.fetch(descriptor)
            await notificationManager.rescheduleAllNotifications(for: loans)
        } catch {
            print("Failed to fetch loans for notification rescheduling: \(error)")
        }
    }
    
    private func testNotification() {
        Task {
            await notificationManager.scheduleTestNotification()
        }
    }
    
    private func viewPendingNotifications() {
        Task {
            let pending = await notificationManager.getPendingNotifications()
            print("Pending notifications: \(pending.count)")
            for notification in pending {
                print("- \(notification.identifier): \(notification.content.title)")
            }
        }
    }
    
    private func openPrivacyPolicy() {
        // Placeholder for opening privacy policy
    }
    
    private func openTermsOfService() {
        // Placeholder for opening terms of service
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
            Text(title)
                .font(MonetiqTheme.Typography.headline)
                .foregroundColor(MonetiqTheme.Colors.onBackground)
                .padding(.horizontal, MonetiqTheme.Spacing.md)
            
            VStack(spacing: 1) {
                content
            }
            .monetiqSurface()
            .padding(.horizontal, MonetiqTheme.Spacing.md)
        }
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                Text(title)
                    .font(MonetiqTheme.Typography.body)
                    .foregroundColor(MonetiqTheme.Colors.onSurface)
                
                Text(subtitle)
                    .font(MonetiqTheme.Typography.caption)
                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(MonetiqTheme.Colors.accent)
        }
        .padding(MonetiqTheme.Spacing.md)
        .background(MonetiqTheme.Colors.surface)
    }
}

struct SettingsPickerRow: View {
    let title: String
    let subtitle: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                Text(title)
                    .font(MonetiqTheme.Typography.body)
                    .foregroundColor(MonetiqTheme.Colors.onSurface)
                
                Text(subtitle)
                    .font(MonetiqTheme.Typography.caption)
                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .tint(MonetiqTheme.Colors.accent)
        }
        .padding(MonetiqTheme.Spacing.md)
        .background(MonetiqTheme.Colors.surface)
    }
}

struct SettingsActionRow: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                    Text(title)
                        .font(MonetiqTheme.Typography.body)
                        .foregroundColor(MonetiqTheme.Colors.onSurface)
                    
                    Text(subtitle)
                        .font(MonetiqTheme.Typography.caption)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
            }
            .padding(MonetiqTheme.Spacing.md)
            .background(MonetiqTheme.Colors.surface)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [Counterparty.self, Loan.self, Payment.self, AppSettings.self], inMemory: true)
}
