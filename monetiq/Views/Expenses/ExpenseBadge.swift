//
//  ExpenseBadge.swift
//  monetiq
//
//  Created by AI Assistant on 26.01.2026.
//

import SwiftUI

enum ExpenseBadgeStyle {
    case recurringActive  // Indigo for on-time recurring
    case recurringOverdue // Red for overdue recurring
    case oneTime          // Teal for one-time
    case status           // Purple for completed
    case category         // Neutral gray
}

struct ExpenseBadge: View {
    let text: String
    let style: ExpenseBadgeStyle
    
    private var colors: (text: Color, background: Color) {
        switch style {
        case .recurringActive:
            return (Color.indigo, Color.indigo.opacity(0.15))
        case .recurringOverdue:
            return (MonetiqTheme.Colors.error, MonetiqTheme.Colors.error.opacity(0.15))
        case .oneTime:
            return (Color.teal, Color.teal.opacity(0.15))
        case .status:
            return (Color.purple, Color.purple.opacity(0.15))
        case .category:
            return (MonetiqTheme.Colors.textSecondary, MonetiqTheme.Colors.surface.opacity(0.5))
        }
    }
    
    var body: some View {
        Text(text)
            .font(MonetiqTheme.Typography.caption)
            .foregroundColor(colors.text)
            .fontWeight(.medium)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .truncationMode(.tail)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(colors.background)
            )
    }
}

