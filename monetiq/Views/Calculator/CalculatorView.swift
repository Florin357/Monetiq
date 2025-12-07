//
//  CalculatorView.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import SwiftUI

struct CalculatorView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var principalAmount: String = ""
    @State private var interestRate: String = ""
    @State private var loanTerm: String = ""
    @State private var selectedFrequency: PaymentFrequency = .monthly
    @State private var calculationResult: LoanCalculator.CalculatorResult?
    
    private var appSettings: AppSettings {
        AppSettings.getOrCreate(in: modelContext)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MonetiqTheme.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
                    Text(L10n.string("calculator_title"))
                        .font(MonetiqTheme.Typography.largeTitle)
                        .foregroundColor(MonetiqTheme.Colors.onBackground)
                    
                    Text(L10n.string("calculator_subtitle"))
                        .font(MonetiqTheme.Typography.callout)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                }
                .monetiqHeader()
                
                // Input Form
                VStack(spacing: MonetiqTheme.Spacing.md) {
                    CalculatorInputField(
                        title: L10n.string("calculator_principal"),
                        placeholder: L10n.string("calculator_principal_placeholder"),
                        text: $principalAmount,
                        suffix: appSettings.defaultCurrencyCode
                    )
                    
                    CalculatorInputField(
                        title: L10n.string("calculator_interest_rate"),
                        placeholder: L10n.string("calculator_interest_rate_placeholder"),
                        text: $interestRate,
                        suffix: "%"
                    )
                    
                    CalculatorInputField(
                        title: L10n.string("calculator_term"),
                        placeholder: L10n.string("calculator_term_placeholder"),
                        text: $loanTerm,
                        suffix: "periods"
                    )
                    
                    // Frequency Picker
                    VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
                        Text(L10n.string("calculator_frequency"))
                            .font(MonetiqTheme.Typography.headline)
                            .foregroundColor(MonetiqTheme.Colors.onSurface)
                        
                        Picker(L10n.string("calculator_frequency"), selection: $selectedFrequency) {
                            ForEach(PaymentFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.localizedLabel).tag(frequency)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .monetiqCard()
                }
                .padding(.horizontal, MonetiqTheme.Spacing.md)
                
                // Calculate Button
                Button(action: calculatePayment) {
                    Text(L10n.string("calculator_calculate"))
                        .monetiqButton()
                }
                .padding(.horizontal, MonetiqTheme.Spacing.md)
                
                // Results Placeholder
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                    Text(L10n.string("calculator_results"))
                        .font(MonetiqTheme.Typography.headline)
                        .foregroundColor(MonetiqTheme.Colors.onSurface)
                    
                    VStack(spacing: MonetiqTheme.Spacing.sm) {
                        if let result = calculationResult {
                            ResultRow(
                                title: L10n.string("calculator_payment", selectedFrequency.localizedLabel),
                                value: CurrencyFormatter.shared.format(amount: result.periodicPaymentAmount, currencyCode: appSettings.defaultCurrencyCode)
                            )
                            ResultRow(
                                title: L10n.string("calculator_total_interest"),
                                value: CurrencyFormatter.shared.format(amount: result.totalInterest, currencyCode: appSettings.defaultCurrencyCode)
                            )
                            ResultRow(
                                title: L10n.string("calculator_total_amount"),
                                value: CurrencyFormatter.shared.format(amount: result.totalToRepay, currencyCode: appSettings.defaultCurrencyCode)
                            )
                        } else {
                            ResultRow(
                                title: L10n.string("calculator_payment", selectedFrequency.localizedLabel),
                                value: CurrencyFormatter.shared.format(amount: 0, currencyCode: appSettings.defaultCurrencyCode)
                            )
                            ResultRow(
                                title: L10n.string("calculator_total_interest"),
                                value: CurrencyFormatter.shared.format(amount: 0, currencyCode: appSettings.defaultCurrencyCode)
                            )
                            ResultRow(
                                title: L10n.string("calculator_total_amount"),
                                value: CurrencyFormatter.shared.format(amount: 0, currencyCode: appSettings.defaultCurrencyCode)
                            )
                        }
                    }
                }
                .monetiqCard()
                .padding(.horizontal, MonetiqTheme.Spacing.md)
                
                Spacer(minLength: MonetiqTheme.Spacing.xl)
            }
            .padding(.vertical, MonetiqTheme.Spacing.lg)
        }
        .monetiqBackground()
    }
    
    private func calculatePayment() {
        guard let principal = Double(principalAmount),
              let rate = Double(interestRate),
              let term = Int(loanTerm),
              principal > 0, rate >= 0, term > 0 else {
            calculationResult = nil
            return
        }
        
        calculationResult = LoanCalculator.calculateForDisplay(
            principal: principal,
            annualInterestRate: rate,
            numberOfPeriods: term,
            frequency: selectedFrequency
        )
    }
}

struct CalculatorInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let suffix: String?
    
    init(title: String, placeholder: String, text: Binding<String>, suffix: String? = nil) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.suffix = suffix
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
            Text(title)
                .font(MonetiqTheme.Typography.headline)
                .foregroundColor(MonetiqTheme.Colors.onSurface)
            
            HStack {
                TextField(placeholder, text: $text)
                    .font(MonetiqTheme.Typography.body)
                    .foregroundColor(MonetiqTheme.Colors.onSurface)
                    .keyboardType(.decimalPad)
                
                if let suffix = suffix {
                    Text(suffix)
                        .font(MonetiqTheme.Typography.body)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                }
            }
            .padding(MonetiqTheme.Spacing.md)
            .background(MonetiqTheme.Colors.background)
            .cornerRadius(MonetiqTheme.CornerRadius.sm)
        }
        .monetiqCard()
    }
}

struct ResultRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(MonetiqTheme.Typography.body)
                .foregroundColor(MonetiqTheme.Colors.onSurface)
            
            Spacer()
            
            Text(value)
                .font(MonetiqTheme.Typography.callout)
                .foregroundColor(MonetiqTheme.Colors.accent)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    NavigationStack {
        CalculatorView()
    }
}
