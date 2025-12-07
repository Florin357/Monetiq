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
    @State private var numberOfPayments: String = ""
    @State private var selectedFrequency: PaymentFrequency = .monthly
    @State private var calculationResult: LoanCalculator.CalculatorResult?
    @State private var showValidationError = false
    
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
                        title: L10n.string("calculator_number_of_payments"),
                        placeholder: L10n.string("calculator_number_of_payments_placeholder"),
                        text: $numberOfPayments,
                        suffix: "payments",
                        helperText: L10n.string("calculator_number_of_payments_helper")
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
                VStack(spacing: MonetiqTheme.Spacing.sm) {
                    Button(action: calculatePayment) {
                        Text(L10n.string("calculator_calculate"))
                            .monetiqButton()
                    }
                    .disabled(!isInputValid)
                    .opacity(isInputValid ? 1.0 : 0.6)
                    
                    if showValidationError {
                        Text(L10n.string("calculator_validation_error"))
                            .font(MonetiqTheme.Typography.caption)
                            .foregroundColor(MonetiqTheme.Colors.error)
                            .multilineTextAlignment(.center)
                    }
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
                                title: L10n.string("calculator_payment_per_period", selectedFrequency.localizedLabel),
                                value: result.periodicPaymentAmount.formattedWithSymbol(currency: appSettings.defaultCurrencyCode),
                                isHighlighted: true
                            )
                            ResultRow(
                                title: L10n.string("calculator_total_to_repay"),
                                value: result.totalToRepay.formattedWithSymbol(currency: appSettings.defaultCurrencyCode)
                            )
                            ResultRow(
                                title: L10n.string("calculator_total_interest"),
                                value: result.totalInterest.formattedWithSymbol(currency: appSettings.defaultCurrencyCode)
                            )
                        } else {
                            Text(L10n.string("calculator_enter_values"))
                                .font(MonetiqTheme.Typography.body)
                                .foregroundColor(MonetiqTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(MonetiqTheme.Spacing.lg)
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
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private var isInputValid: Bool {
        guard let principal = Double(principalAmount),
              let rate = Double(interestRate.isEmpty ? "0" : interestRate),
              let term = Int(numberOfPayments),
              principal > 0, rate >= 0, term > 0 else {
            return false
        }
        return true
    }
    
    private func calculatePayment() {
        guard let principal = Double(principalAmount),
              let term = Int(numberOfPayments),
              principal > 0, term > 0 else {
            showValidationError = true
            calculationResult = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showValidationError = false
            }
            return
        }
        
        let rate = Double(interestRate.isEmpty ? "0" : interestRate) ?? 0.0
        showValidationError = false
        
        calculationResult = LoanCalculator.calculateForDisplay(
            principal: principal,
            annualInterestRate: rate,
            numberOfPeriods: term,
            frequency: selectedFrequency
        )
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct CalculatorInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let suffix: String?
    let helperText: String?
    @FocusState private var isFocused: Bool
    
    init(title: String, placeholder: String, text: Binding<String>, suffix: String? = nil, helperText: String? = nil) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.suffix = suffix
        self.helperText = helperText
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
                    .focused($isFocused)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button(L10n.string("general_done")) {
                                isFocused = false
                            }
                            .foregroundColor(MonetiqTheme.Colors.accent)
                        }
                    }
                
                if let suffix = suffix {
                    Text(suffix)
                        .font(MonetiqTheme.Typography.body)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                }
            }
            .padding(MonetiqTheme.Spacing.md)
            .background(MonetiqTheme.Colors.background)
            .cornerRadius(MonetiqTheme.CornerRadius.sm)
            
            if let helperText = helperText {
                Text(helperText)
                    .font(MonetiqTheme.Typography.caption)
                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .monetiqCard()
    }
}

struct ResultRow: View {
    let title: String
    let value: String
    let isHighlighted: Bool
    
    init(title: String, value: String, isHighlighted: Bool = false) {
        self.title = title
        self.value = value
        self.isHighlighted = isHighlighted
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(isHighlighted ? MonetiqTheme.Typography.headline : MonetiqTheme.Typography.body)
                .foregroundColor(MonetiqTheme.Colors.onSurface)
                .fontWeight(isHighlighted ? .semibold : .regular)
            
            Spacer()
            
            Text(value)
                .font(isHighlighted ? MonetiqTheme.Typography.title2 : MonetiqTheme.Typography.callout)
                .foregroundColor(MonetiqTheme.Colors.accent)
                .fontWeight(.semibold)
        }
        .padding(.vertical, isHighlighted ? MonetiqTheme.Spacing.sm : 0)
        .background(isHighlighted ? MonetiqTheme.Colors.accent.opacity(0.1) : Color.clear)
        .cornerRadius(MonetiqTheme.CornerRadius.sm)
    }
}

#Preview {
    NavigationStack {
        CalculatorView()
    }
}
