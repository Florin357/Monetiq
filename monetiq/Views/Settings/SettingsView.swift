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
    // Appearance mode is now handled through AppSettings
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showingResetConfirmation = false
    @State private var showingBiometricAlert = false
    @State private var biometricAlertMessage = ""
    @State private var biometricAlertTitle = ""
    @State private var isEnablingBiometrics = false
    @State private var showingNotificationDeniedAlert = false
    
    private var notificationManager: NotificationManager {
        NotificationManager.shared
    }
    
    private var currencies: [Currency] {
        CurrencyCatalog.shared.supportedCurrencies
    }
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
        NavigationStack {
            ScrollView {
                VStack(spacing: MonetiqTheme.Spacing.sectionSpacing) {
                
                // General Settings
                SettingsSection(title: L10n.string("settings_general")) {
                    SettingsToggleRow(
                        title: L10n.string("settings_notifications"),
                        subtitle: L10n.string("settings_notifications_subtitle"),
                        icon: "bell.fill",
                        iconColor: .blue,
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
                        title: L10n.string("settings_days_before"),
                        subtitle: L10n.string("settings_days_before_subtitle"),
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
                        title: L10n.string("settings_weekly_review"),
                        subtitle: L10n.string("settings_weekly_review_subtitle"),
                        icon: "calendar",
                        iconColor: .green,
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
                    
                    CurrencyPickerRow(
                        title: L10n.string("settings_default_currency"),
                        subtitle: L10n.string("settings_default_currency_subtitle"),
                        selection: Binding(
                            get: { settings.defaultCurrencyCode },
                            set: { newValue in
                                settings.defaultCurrencyCode = newValue
                                settings.updateTimestamp()
                                saveContext()
                            }
                        ),
                        currencies: currencies
                    )
                    
                    LanguagePickerRow(
                        title: L10n.string("settings_language"),
                        subtitle: L10n.string("settings_language_subtitle"),
                        selection: Binding(
                            get: { settings.languageOverride ?? "system" },
                            set: { newValue in
                                let finalValue = newValue == "system" ? nil : newValue
                                #if DEBUG
                                print("🌐 Settings: Language changed from '\(settings.languageOverride ?? "system")' to '\(finalValue ?? "system")'")
                                #endif
                                settings.languageOverride = finalValue
                                settings.updateTimestamp()
                                saveContext()
                            }
                        ),
                        languages: LanguageCatalog.shared.supportedLanguages
                    )
                }
                
                // Security Settings
                SettingsSection(title: L10n.string("settings_security")) {
                    SettingsToggleRow(
                        title: L10n.string("settings_biometric"),
                        subtitle: L10n.string("settings_biometric_subtitle"),
                        icon: "faceid",
                        iconColor: .purple,
                        isOn: Binding(
                            get: { settings.biometricLockEnabled },
                            set: { newValue in
                                handleBiometricToggle(enabled: newValue)
                            }
                        )
                    )
                    .disabled(isEnablingBiometrics)
                }
                
                // Appearance Settings
                SettingsSection(title: L10n.string("settings_appearance")) {
                    SettingsPickerRow(
                        title: L10n.string("settings_appearance_mode"),
                        subtitle: L10n.string("settings_appearance_mode_subtitle"),
                        selection: Binding(
                            get: { settings.appearanceMode.displayName },
                            set: { newDisplayName in
                                if let newMode = AppearanceMode.allCases.first(where: { $0.displayName == newDisplayName }) {
                                    settings.appearanceMode = newMode
                                    settings.updateTimestamp()
                                    saveContext()
                                }
                            }
                        ),
                        options: AppearanceMode.allCases.map { $0.displayName }
                    )
                }
                
                
                // Data Section
                SettingsSection(title: L10n.string("settings_data")) {
                    SettingsDestructiveActionRow(
                        title: L10n.string("settings_reset_app"),
                        subtitle: L10n.string("settings_reset_app_subtitle"),
                        action: showResetConfirmation
                    )
                }
                
                // About Section
                SettingsSection(title: L10n.string("settings_about")) {
                    // App Version & Info - Using Bundle information
                    SettingsActionRow(
                        title: L10n.string("settings_version"),
                        subtitle: AppLinks.appInfoSubtitle,
                        action: {}
                    )
                    
                    NavigationLink(destination: PrivacyPolicyView()) {
                        SettingsRowContent(
                            title: L10n.string("settings_privacy"),
                            subtitle: L10n.string("settings_privacy_subtitle")
                        )
                    }
                    
                    NavigationLink(destination: TermsOfServiceView()) {
                        SettingsRowContent(
                            title: L10n.string("settings_terms"),
                            subtitle: L10n.string("settings_terms_subtitle")
                        )
                    }
                }
                
                Spacer(minLength: MonetiqTheme.Spacing.xl)
            }
            .padding(.vertical, MonetiqTheme.Spacing.sectionSpacing)
            }
            .navigationTitle(L10n.string("settings_title"))
            .navigationBarTitleDisplayMode(.large)
            .monetiqBackground()
        }
        .onAppear {
            // Initialize settings and notification manager
            let currentSettings = AppSettings.getOrCreate(in: modelContext)
            appSettings = currentSettings
            notificationManager.setAppSettings(currentSettings)
            
            // No need to initialize toggle value - it reads directly from settings
        }
        .alert(L10n.string("settings_reset_app_confirm_title"), isPresented: $showingResetConfirmation) {
            Button(L10n.string("general_cancel"), role: .cancel) { }
            Button(L10n.string("settings_reset_app_confirm_action"), role: .destructive) {
                performAppReset()
            }
        } message: {
            Text(L10n.string("settings_reset_app_confirm_message"))
        }
        .alert(biometricAlertTitle, isPresented: $showingBiometricAlert) {
            Button(L10n.string("general_ok"), role: .cancel) { }
        } message: {
            Text(biometricAlertMessage)
        }
        .alert(L10n.string("settings_notifications_denied_title"), isPresented: $showingNotificationDeniedAlert) {
            Button(L10n.string("general_cancel"), role: .cancel) { }
            Button(L10n.string("settings_open_settings")) {
                openAppSettings()
            }
        } message: {
            Text(L10n.string("settings_notifications_denied_message"))
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
                } else {
                    // Check if permission was denied
                    let status = await notificationManager.getAuthorizationStatus()
                    if status == .denied {
                        // Revert toggle and show alert
                        await MainActor.run {
                            settings.notificationsEnabled = false
                            saveContext()
                            showingNotificationDeniedAlert = true
                        }
                    }
                }
            } else {
                // Cancel all notifications and clear badge
                await notificationManager.cancelAllNotifications()
                await notificationManager.updateBadgeCount()
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
    
    
    
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func showResetConfirmation() {
        showingResetConfirmation = true
    }
    
    private func performAppReset() {
        Task {
            let _ = await AppResetService.shared.resetApp(modelContext: modelContext)
            
            // Reset local state on main actor
            await MainActor.run {
                // Reset local state
                appSettings = nil
                
                // Reinitialize settings
                let newSettings = AppSettings.getOrCreate(in: modelContext)
                appSettings = newSettings
                notificationManager.setAppSettings(newSettings)
            }
        }
    }
    
    private func handleBiometricToggle(enabled: Bool) {
        #if DEBUG
        print("🔒 SettingsView: Biometric toggle changed to \(enabled)")
        #endif
        
        if enabled {
            // User wants to enable biometrics
            enableBiometrics()
        } else {
            // User wants to disable biometrics - always allowed, no processing needed
            settings.biometricLockEnabled = false
            settings.updateTimestamp()
            saveContext()
            
            // Unlock the app immediately
            AppLockState.shared.unlockWithoutBiometrics()
            
            #if DEBUG
            print("🔒 SettingsView: Biometrics disabled")
            #endif
        }
    }
    
    @MainActor
    private func enableBiometrics() {
        // Prevent multiple concurrent enable attempts
        guard !isEnablingBiometrics else {
            #if DEBUG
            print("🔒 SettingsView: Already enabling biometrics, ignoring")
            #endif
            return
        }
        
        isEnablingBiometrics = true
        
        #if DEBUG
        print("🔒 SettingsView: Starting biometric enable process")
        #endif
        
        Task {
            let biometricService = BiometricAuthService.shared
            let availability = biometricService.checkBiometricAvailability()
            
            await MainActor.run {
                if availability.available {
                    #if DEBUG
                    print("🔒 SettingsView: Biometrics available, prompting for authentication")
                    #endif
                    
                    // Biometrics available, prompt for authentication
                    Task {
                        let reason = L10n.string("biometric_enable_reason")
                        let result = await biometricService.authenticateWithBiometrics(reason: reason)
                        
                        await MainActor.run {
                            switch result {
                            case .success:
                                #if DEBUG
                                print("🔒 SettingsView: Authentication successful, enabling biometrics")
                                #endif
                                
                                // Authentication successful, enable biometrics
                                settings.biometricLockEnabled = true
                                settings.updateTimestamp()
                                saveContext()
                                
                                // Initialize lock state
                                AppLockState.shared.initializeLockState(biometricEnabled: true)
                                
                            case .failure(let error):
                                #if DEBUG
                                print("🔒 SettingsView: Authentication failed: \(error)")
                                #endif
                                
                                // Authentication failed, keep setting OFF and show error
                                settings.biometricLockEnabled = false
                                
                                // Show error alert (but not for user cancellation)
                                if case .userCancel = error {
                                    // User cancelled - no alert needed
                                } else {
                                    biometricAlertTitle = L10n.string("biometric_error_title")
                                    biometricAlertMessage = error.errorDescription ?? L10n.string("biometric_error_unknown")
                                    showingBiometricAlert = true
                                }
                            }
                            
                            isEnablingBiometrics = false
                        }
                    }
                } else {
                    #if DEBUG
                    print("🔒 SettingsView: Biometrics not available: \(availability.error?.errorDescription ?? "Unknown")")
                    #endif
                    
                    // Biometrics not available, keep setting OFF and show error
                    settings.biometricLockEnabled = false
                    
                    biometricAlertTitle = L10n.string("biometric_unavailable_title")
                    biometricAlertMessage = availability.error?.errorDescription ?? L10n.string("biometric_unavailable_message")
                    showingBiometricAlert = true
                    
                    isEnablingBiometrics = false
                }
            }
        }
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
                .font(MonetiqTheme.Typography.footnote)
                .foregroundColor(MonetiqTheme.Colors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, MonetiqTheme.Spacing.screenPadding)
            
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: MonetiqTheme.CornerRadius.card)
                    .fill(MonetiqTheme.Colors.surface)
            )
            .padding(.horizontal, MonetiqTheme.Spacing.screenPadding)
        }
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String?
    let iconColor: Color
    @Binding var isOn: Bool
    
    init(title: String, subtitle: String, icon: String? = nil, iconColor: Color = .blue, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self._isOn = isOn
    }
    
    var body: some View {
        HStack(spacing: MonetiqTheme.Spacing.md) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 28, height: 28)
            }
            
            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                Text(title)
                    .font(MonetiqTheme.Typography.bodyEmphasized)
                    .foregroundColor(MonetiqTheme.Colors.textPrimary)
                
                Text(subtitle)
                    .font(MonetiqTheme.Typography.footnote)
                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(MonetiqTheme.Colors.accent)
        }
        .padding(MonetiqTheme.Spacing.cardPadding)
        .background(Color.clear)
    }
}

struct SettingsPickerRow: View {
    let title: String
    let subtitle: String
    @Binding var selection: String
    let options: [String]
    let optionDisplayNames: [String]?
    
    init(title: String, subtitle: String, selection: Binding<String>, options: [String], optionDisplayNames: [String]? = nil) {
        self.title = title
        self.subtitle = subtitle
        self._selection = selection
        self.options = options
        self.optionDisplayNames = optionDisplayNames
    }
    
    var body: some View {
        HStack(spacing: MonetiqTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                Text(title)
                    .font(MonetiqTheme.Typography.bodyEmphasized)
                    .foregroundColor(MonetiqTheme.Colors.textPrimary)
                
                Text(subtitle)
                    .font(MonetiqTheme.Typography.footnote)
                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Picker(title, selection: $selection) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    Text(optionDisplayNames?[index] ?? option).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .tint(MonetiqTheme.Colors.accent)
        }
        .padding(MonetiqTheme.Spacing.cardPadding)
        .background(Color.clear)
    }
}

struct SettingsActionRow: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: MonetiqTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                    Text(title)
                        .font(MonetiqTheme.Typography.bodyEmphasized)
                        .foregroundColor(MonetiqTheme.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(MonetiqTheme.Typography.footnote)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(MonetiqTheme.Typography.footnote)
                    .foregroundColor(MonetiqTheme.Colors.textTertiary)
            }
            .padding(MonetiqTheme.Spacing.cardPadding)
            .background(Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsDestructiveActionRow: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: MonetiqTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                    Text(title)
                        .font(MonetiqTheme.Typography.bodyEmphasized)
                        .foregroundColor(MonetiqTheme.Colors.error)
                    
                    Text(subtitle)
                        .font(MonetiqTheme.Typography.footnote)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(MonetiqTheme.Typography.title3)
                    .foregroundColor(MonetiqTheme.Colors.error)
            }
            .padding(MonetiqTheme.Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: MonetiqTheme.CornerRadius.md)
                    .fill(MonetiqTheme.Colors.error.opacity(0.05))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CurrencyPickerRow: View {
    let title: String
    let subtitle: String
    @Binding var selection: String
    let currencies: [Currency]
    
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
                ForEach(currencies, id: \.code) { currency in
                    Text(currency.displayName).tag(currency.code)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .tint(MonetiqTheme.Colors.accent)
        }
        .padding(MonetiqTheme.Spacing.md)
        .background(MonetiqTheme.Colors.surface)
        .cornerRadius(MonetiqTheme.CornerRadius.md)
    }
}

struct LanguagePickerRow: View {
    let title: String
    let subtitle: String
    @Binding var selection: String
    let languages: [Language]
    
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
                ForEach(languages, id: \.code) { language in
                    Text(language.displayName).tag(language.code)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .tint(MonetiqTheme.Colors.accent)
        }
        .padding(MonetiqTheme.Spacing.md)
        .background(MonetiqTheme.Colors.surface)
        .cornerRadius(MonetiqTheme.CornerRadius.md)
    }
}

// MARK: - Settings Row Content (for NavigationLink)
struct SettingsRowContent: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                Text(title)
                    .font(MonetiqTheme.Typography.body)
                    .foregroundColor(MonetiqTheme.Colors.textPrimary)
                
                Text(subtitle)
                    .font(MonetiqTheme.Typography.caption)
                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(MonetiqTheme.Typography.footnote)
                .foregroundColor(MonetiqTheme.Colors.textTertiary)
        }
        .padding(MonetiqTheme.Spacing.md)
        .background(MonetiqTheme.Colors.surface)
        .cornerRadius(MonetiqTheme.CornerRadius.md)
    }
}


#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [Counterparty.self, Loan.self, Payment.self, AppSettings.self], inMemory: true)
}
