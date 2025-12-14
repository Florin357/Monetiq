//
//  MonetiqTheme.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import SwiftUI

struct MonetiqTheme {
    
    // MARK: - Colors
    struct Colors {
        static let primary = Color(red: 0.1, green: 0.2, blue: 0.4)        // Dark blue
        static let accent = Color(red: 1.0, green: 0.8, blue: 0.0)         // Gold
        
        // Dynamic backgrounds that adapt to light/dark mode
        static let background = Color(.systemBackground)
        static let surface = Color(.secondarySystemBackground)
        
        // Dynamic text colors that adapt to light/dark mode
        static let onPrimary = Color.white
        static let onBackground = Color(.label)
        static let onSurface = Color(.label)
        
        // Status colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let textSecondary = Color(.secondaryLabel)
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.medium)
        static let headline = Font.headline.weight(.medium)
        static let body = Font.body
        static let callout = Font.callout
        static let caption = Font.caption
        static let caption2 = Font.caption2
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }
}

// MARK: - View Extensions for Easy Theme Application
extension View {
    func monetiqBackground() -> some View {
        self.background(MonetiqTheme.Colors.background)
    }
    
    func monetiqSurface() -> some View {
        self
            .background(MonetiqTheme.Colors.surface)
            .cornerRadius(MonetiqTheme.CornerRadius.md)
    }
    
    func monetiqCard() -> some View {
        self
            .padding(MonetiqTheme.Spacing.md)
            .background(MonetiqTheme.Colors.surface)
            .cornerRadius(MonetiqTheme.CornerRadius.md)
    }
    
    func monetiqButton(style: MonetiqButtonStyle = .primary) -> some View {
        self
            .font(MonetiqTheme.Typography.headline)
            .foregroundColor(style.foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(MonetiqTheme.Spacing.md)
            .background(style.backgroundColor)
            .cornerRadius(MonetiqTheme.CornerRadius.md)
    }
    
    func monetiqHeader() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, MonetiqTheme.Spacing.md)
            .padding(.top, MonetiqTheme.Spacing.lg)
    }
    
    func monetiqEmptyState() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .multilineTextAlignment(.center)
    }
}

// MARK: - Button Styles
enum MonetiqButtonStyle {
    case primary
    case secondary
    case destructive
    
    var backgroundColor: Color {
        switch self {
        case .primary:
            return MonetiqTheme.Colors.accent
        case .secondary:
            return MonetiqTheme.Colors.surface
        case .destructive:
            return MonetiqTheme.Colors.error
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .primary:
            return MonetiqTheme.Colors.onPrimary
        case .secondary:
            return MonetiqTheme.Colors.onSurface
        case .destructive:
            return MonetiqTheme.Colors.onPrimary
        }
    }
}
