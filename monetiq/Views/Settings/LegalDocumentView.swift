//
//  LegalDocumentView.swift
//  monetiq
//
//  Created by Assistant on 15.12.2025.
//

import SwiftUI

/// Reusable view for displaying legal documents (Privacy Policy, Terms of Service)
/// Uses NavigationStack with proper safe area handling and localized content
struct LegalDocumentView: View {
    let titleKey: String
    let bodyKey: String
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.lg) {
                    Text(L10n.string(bodyKey))
                        .font(MonetiqTheme.Typography.body)
                        .foregroundColor(MonetiqTheme.Colors.textPrimary)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                }
                .padding(MonetiqTheme.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(L10n.string(titleKey))
            .navigationBarTitleDisplayMode(.large)
            .monetiqBackground()
        }
    }
}

#Preview("Legal Document") {
    LegalDocumentView(
        titleKey: "settings_privacy",
        bodyKey: "privacy_policy_content"
    )
}
