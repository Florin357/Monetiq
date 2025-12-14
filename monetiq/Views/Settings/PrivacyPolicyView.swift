//
//  PrivacyPolicyView.swift
//  monetiq
//
//  Created by Florin Mihai on 14.12.2025.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                        Text(L10n.string("about_privacy_title"))
                            .font(MonetiqTheme.Typography.title)
                            .foregroundColor(MonetiqTheme.Colors.onSurface)
                        
                        Text(L10n.string("about_privacy_last_updated"))
                            .font(MonetiqTheme.Typography.caption)
                            .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                        SectionView(
                            title: "Data Storage",
                            content: "Monetiq is designed with privacy in mind. All your financial data is stored locally on your device using Apple's secure Core Data framework. No data is transmitted to external servers or third-party services."
                        )
                        
                        SectionView(
                            title: "Data Collection",
                            content: "We do not collect, store, or transmit any personal information, financial data, or usage analytics. Your loan information, payment schedules, and settings remain entirely on your device."
                        )
                        
                        SectionView(
                            title: "Data Security",
                            content: "Your data is protected by your device's built-in security features, including device encryption and biometric authentication (when enabled). We recommend using a device passcode and enabling biometric authentication for additional security."
                        )
                        
                        SectionView(
                            title: "Data Backup",
                            content: "If you have iCloud backup enabled, your Monetiq data may be included in your device backup. This backup is encrypted and managed entirely by Apple according to their privacy policies."
                        )
                        
                        SectionView(
                            title: "Third-Party Services",
                            content: "Monetiq does not integrate with any third-party analytics, advertising, or data collection services. The app operates entirely offline and does not require an internet connection."
                        )
                        
                        SectionView(
                            title: "Contact",
                            content: "If you have any questions about this privacy policy or data handling, please contact us through the App Store review system or developer contact information."
                        )
                    }
                    
                    Text(L10n.string("about_privacy_disclaimer"))
                        .font(MonetiqTheme.Typography.caption)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                        .padding(.top, MonetiqTheme.Spacing.lg)
                }
                .padding(MonetiqTheme.Spacing.md)
            }
            .monetiqBackground()
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.string("about_close")) {
                        dismiss()
                    }
                    .foregroundColor(MonetiqTheme.Colors.accent)
                }
            }
        }
    }
}

struct SectionView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
            Text(title)
                .font(MonetiqTheme.Typography.headline)
                .foregroundColor(MonetiqTheme.Colors.onSurface)
            
            Text(content)
                .font(MonetiqTheme.Typography.body)
                .foregroundColor(MonetiqTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MonetiqTheme.Spacing.md)
        .background(MonetiqTheme.Colors.surface)
        .cornerRadius(MonetiqTheme.CornerRadius.md)
    }
}

#Preview {
    PrivacyPolicyView()
}
