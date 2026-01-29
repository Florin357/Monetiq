//
//  MoreView.swift
//  monetiq
//
//  Created on 2026-01-27.
//

import SwiftUI

struct MoreView: View {
    var body: some View {
        List {
            NavigationLink {
                CalculatorView()
            } label: {
                HStack(spacing: MonetiqTheme.Spacing.md) {
                    Image(systemName: "function")
                        .font(.title3)
                        .foregroundColor(MonetiqTheme.Colors.accent)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.string("tab_calculator"))
                            .font(MonetiqTheme.Typography.body)
                            .foregroundColor(MonetiqTheme.Colors.onSurface)
                        
                        Text(L10n.string("calculator_subtitle"))
                            .font(MonetiqTheme.Typography.caption)
                            .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Future PRO items will be added here below Calculator
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.string("tab_more"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundColor(MonetiqTheme.Colors.accent)
                }
                .accessibilityLabel(L10n.string("tab_settings"))
            }
        }
    }
}

#Preview {
    NavigationStack {
        MoreView()
    }
}

