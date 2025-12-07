//
//  SettingsView.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var biometricEnabled = false
    @State private var darkModeEnabled = true
    @State private var defaultCurrency = "RON"
    
    private let currencies = ["RON", "EUR", "USD", "GBP"]
    
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
                        isOn: $notificationsEnabled
                    )
                    
                    SettingsPickerRow(
                        title: "Default Currency",
                        subtitle: "Currency for new loans",
                        selection: $defaultCurrency,
                        options: currencies
                    )
                }
                
                // Security Settings
                SettingsSection(title: "Security") {
                    SettingsToggleRow(
                        title: "Biometric Authentication",
                        subtitle: "Use Face ID or Touch ID to unlock",
                        isOn: $biometricEnabled
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
}
