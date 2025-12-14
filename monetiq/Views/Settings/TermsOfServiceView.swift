//
//  TermsOfServiceView.swift
//  monetiq
//
//  Created by Florin Mihai on 14.12.2025.
//

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                        Text(L10n.string("about_terms_title"))
                            .font(MonetiqTheme.Typography.title)
                            .foregroundColor(MonetiqTheme.Colors.onSurface)
                        
                        Text(L10n.string("about_terms_last_updated"))
                            .font(MonetiqTheme.Typography.caption)
                            .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                        SectionView(
                            title: "Acceptance of Terms",
                            content: "By downloading and using Monetiq, you agree to these terms of service. If you do not agree with these terms, please do not use the application."
                        )
                        
                        SectionView(
                            title: "Description of Service",
                            content: "Monetiq is a personal finance management application designed to help you track loans, payments, and calculate loan terms. The app operates entirely on your device and does not provide financial advice."
                        )
                        
                        SectionView(
                            title: "User Responsibilities",
                            content: "You are responsible for the accuracy of the financial information you enter into the app. Monetiq is a tool for personal organization and calculation - always verify important financial decisions with qualified professionals."
                        )
                        
                        SectionView(
                            title: "Disclaimer",
                            content: "Monetiq is provided 'as is' without warranties of any kind. The calculations and information provided are for reference purposes only. We are not responsible for any financial decisions made based on the app's calculations."
                        )
                        
                        SectionView(
                            title: "Data Ownership",
                            content: "You retain full ownership of all data you enter into Monetiq. The app does not claim any rights to your financial information, and all data remains on your device."
                        )
                        
                        SectionView(
                            title: "Limitation of Liability",
                            content: "In no event shall Monetiq or its developers be liable for any damages arising from the use or inability to use the application, including but not limited to financial losses or data loss."
                        )
                        
                        SectionView(
                            title: "Changes to Terms",
                            content: "These terms may be updated from time to time. Continued use of the application after changes constitutes acceptance of the new terms."
                        )
                    }
                    
                    Text(L10n.string("about_terms_disclaimer"))
                        .font(MonetiqTheme.Typography.caption)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                        .padding(.top, MonetiqTheme.Spacing.lg)
                }
                .padding(MonetiqTheme.Spacing.md)
            }
            .monetiqBackground()
            .navigationTitle("Terms of Service")
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

#Preview {
    TermsOfServiceView()
}
