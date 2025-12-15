//
//  PrivacyPolicyView.swift
//  monetiq
//
//  Created by Florin Mihai on 14.12.2025.
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.lg) {
                Text(L10n.string("privacy_policy_content"))
                    .font(MonetiqTheme.Typography.body)
                    .foregroundColor(MonetiqTheme.Colors.textPrimary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
            }
            .padding(MonetiqTheme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(L10n.string("settings_privacy"))
        .navigationBarTitleDisplayMode(.large)
        .monetiqBackground()
    }
}


#Preview {
    PrivacyPolicyView()
}
