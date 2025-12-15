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
        // Brand colors - Revolut-inspired premium palette
        static let primary = Color(red: 0.012, green: 0.031, blue: 0.361)   // #03085C - Deep premium blue
        static let primaryDark = Color(red: 0.098, green: 0.110, blue: 0.122) // #191C1F - Dark mode primary
        static let accent = Color(red: 0.0, green: 0.48, blue: 1.0)        // Modern blue accent
        
        // Premium dark variants
        static let darkBlue = Color(red: 0.0, green: 0.0, blue: 0.098)     // #000019 - Deep dark
        static let darkPurple = Color(red: 0.098, green: 0.098, blue: 0.188) // #191930 - Dark purple
        
        // Dynamic backgrounds that adapt to light/dark mode
        static let background = Color(.systemBackground)
        static let surface = Color(.secondarySystemBackground)
        static let surfaceElevated = Color(.tertiarySystemBackground)
        
        // Dynamic text colors that adapt to light/dark mode
        static let onPrimary = Color.white
        static let onBackground = Color(.label)
        static let onSurface = Color(.label)
        static let textPrimary = Color(.label)
        static let textSecondary = Color(.secondaryLabel)
        static let textTertiary = Color(.tertiaryLabel)
        
        // Semantic finance colors
        static let positive = Color(.systemGreen)      // Money to receive / lent
        static let negative = Color(.systemOrange)     // Money to pay / borrowed
        static let neutral = Color(.systemBlue)        // Neutral actions
        static let error = Color(.systemRed)           // Errors and destructive actions
        
        // Status colors (legacy support)
        static let success = positive
        static let warning = negative
        
        // Card and surface colors
        static let cardBackground = Color(.secondarySystemBackground)
        static let cardBorder = Color(.separator)
    }
    
    // MARK: - Typography
    struct Typography {
        // Premium fintech hierarchy - Revolut-inspired
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.semibold)     // Stronger hierarchy
        static let title3 = Font.title3.weight(.medium)
        static let headline = Font.headline.weight(.semibold) // More emphasis
        static let subheadline = Font.subheadline.weight(.medium)
        static let body = Font.body.weight(.regular)
        static let bodyEmphasized = Font.body.weight(.semibold) // Stronger emphasis
        static let callout = Font.callout.weight(.medium)
        static let footnote = Font.footnote.weight(.regular)
        static let caption = Font.caption.weight(.medium)     // Slightly stronger
        static let caption2 = Font.caption2.weight(.regular)
        
        // Premium finance typography - enhanced hierarchy
        static let currencyLarge = Font.system(size: 32, weight: .bold, design: .rounded).monospacedDigit()
        static let currencyMedium = Font.system(size: 24, weight: .semibold, design: .rounded).monospacedDigit()
        static let currencySmall = Font.system(size: 18, weight: .semibold, design: .rounded).monospacedDigit()
        static let currencyCaption = Font.system(size: 14, weight: .medium, design: .rounded).monospacedDigit()
        
        // Section headers - premium style
        static let sectionHeader = Font.system(size: 20, weight: .semibold, design: .default)
        static let cardTitle = Font.system(size: 16, weight: .semibold, design: .default)
        static let cardSubtitle = Font.system(size: 14, weight: .medium, design: .default)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
        static let xxl: CGFloat = 36
        
        // Specialized spacing for better visual rhythm
        static let cardPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 24
        static let screenPadding: CGFloat = 16
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        
        // Specialized corner radius for modern design
        static let card: CGFloat = 16
        static let button: CGFloat = 12
        static let input: CGFloat = 10
    }
    
    // MARK: - Shadows and Effects
    struct Shadow {
        // Revolut-style subtle depth
        static let card = Color.black.opacity(0.04)
        static let cardElevated = Color.black.opacity(0.08)
        static let cardPremium = Color.black.opacity(0.12)
        static let subtle = Color.black.opacity(0.02)
        
        // Interactive shadows
        static let pressed = Color.black.opacity(0.15)
        static let hover = Color.black.opacity(0.06)
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
            .cornerRadius(MonetiqTheme.CornerRadius.card)
    }
    
    func monetiqCard(elevated: Bool = false, premium: Bool = false) -> some View {
        self
            .padding(MonetiqTheme.Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: MonetiqTheme.CornerRadius.card)
                    .fill(MonetiqTheme.Colors.cardBackground)
                    .shadow(
                        color: premium ? MonetiqTheme.Shadow.cardPremium : 
                               elevated ? MonetiqTheme.Shadow.cardElevated : MonetiqTheme.Shadow.card,
                        radius: premium ? 12 : elevated ? 8 : 6,
                        x: 0,
                        y: premium ? 6 : elevated ? 4 : 3
                    )
            )
    }
    
    func monetiqButton(style: MonetiqButtonStyle = .primary) -> some View {
        self
            .font(MonetiqTheme.Typography.headline)
            .foregroundColor(style.foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, MonetiqTheme.Spacing.md)
            .padding(.horizontal, MonetiqTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: MonetiqTheme.CornerRadius.button)
                    .fill(style.backgroundColor)
            )
    }
    
    func monetiqHeader() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, MonetiqTheme.Spacing.screenPadding)
            .padding(.top, MonetiqTheme.Spacing.lg)
    }
    
    func monetiqEmptyState() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .multilineTextAlignment(.center)
            .padding(MonetiqTheme.Spacing.xl)
    }
    
    func monetiqInput() -> some View {
        self
            .padding(MonetiqTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: MonetiqTheme.CornerRadius.input)
                    .fill(MonetiqTheme.Colors.surface)
                    .stroke(MonetiqTheme.Colors.cardBorder, lineWidth: 0.5)
            )
    }
    
    func monetiqSection() -> some View {
        self
            .padding(.horizontal, MonetiqTheme.Spacing.screenPadding)
    }
    
    // MARK: - Premium UI Modifiers
    
    func monetiqCardTitle() -> some View {
        self
            .font(MonetiqTheme.Typography.cardTitle)
            .foregroundColor(MonetiqTheme.Colors.textPrimary)
    }
    
    func monetiqCardSubtitle() -> some View {
        self
            .font(MonetiqTheme.Typography.cardSubtitle)
            .foregroundColor(MonetiqTheme.Colors.textSecondary)
    }
    
    func monetiqPremiumCard() -> some View {
        self
            .monetiqCard(elevated: true, premium: true)
    }
    
    func monetiqInteractiveCard() -> some View {
        self
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.1), value: false)
    }
}

// MARK: - Button Styles
enum MonetiqButtonStyle {
    case primary
    case secondary
    case destructive
    case subtle
    
    var backgroundColor: Color {
        switch self {
        case .primary:
            return MonetiqTheme.Colors.accent
        case .secondary:
            return MonetiqTheme.Colors.surface
        case .destructive:
            return MonetiqTheme.Colors.error
        case .subtle:
            return MonetiqTheme.Colors.surfaceElevated
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .primary:
            return MonetiqTheme.Colors.onPrimary
        case .secondary:
            return MonetiqTheme.Colors.textPrimary
        case .destructive:
            return MonetiqTheme.Colors.onPrimary
        case .subtle:
            return MonetiqTheme.Colors.textSecondary
        }
    }
}

// MARK: - Currency Display Styles
enum CurrencyDisplayStyle {
    case large      // For main dashboard totals
    case medium     // For card amounts
    case small      // For list items
    case caption    // For secondary info
    
    var font: Font {
        switch self {
        case .large:
            return MonetiqTheme.Typography.currencyLarge
        case .medium:
            return MonetiqTheme.Typography.currencyMedium
        case .small:
            return MonetiqTheme.Typography.currencySmall
        case .caption:
            return MonetiqTheme.Typography.currencyCaption
        }
    }
}

// MARK: - Additional View Extensions for Finance UI
extension View {
    func currencyText(style: CurrencyDisplayStyle, color: Color = MonetiqTheme.Colors.textPrimary) -> some View {
        self
            .font(style.font)
            .foregroundColor(color)
    }
    
    func monetiqSectionHeader() -> some View {
        self
            .font(MonetiqTheme.Typography.sectionHeader)
            .foregroundColor(MonetiqTheme.Colors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
