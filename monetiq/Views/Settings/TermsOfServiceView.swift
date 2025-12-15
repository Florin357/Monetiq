//
//  TermsOfServiceView.swift
//  monetiq
//
//  Created by Florin Mihai on 14.12.2025.
//

import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.lg) {
                Text(L10n.string("terms_of_service_content"))
                    .font(MonetiqTheme.Typography.body)
                    .foregroundColor(MonetiqTheme.Colors.textPrimary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
            }
            .padding(MonetiqTheme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(L10n.string("settings_terms"))
        .navigationBarTitleDisplayMode(.large)
        .monetiqBackground()
    }
}

#Preview {
    TermsOfServiceView()
}
