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
    @State private var selectedCurrency: String = "RON"
    @State private var calculationResult: LoanCalculator.CalculatorResult?
    @State private var showValidationError = false
    @State private var generatedAt: Date?
    
    // Unified focus state for all fields
    enum Field {
        case principal, interest, term
    }
    @FocusState private var focusedField: Field?
    
    private var appSettings: AppSettings {
        AppSettings.getOrCreate(in: modelContext)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MonetiqTheme.Spacing.sectionSpacing) {
                // Header - Premium styling
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                    Text(L10n.string("calculator_title"))
                        .font(MonetiqTheme.Typography.largeTitle)
                        .foregroundColor(MonetiqTheme.Colors.textPrimary)
                    
                    Text(L10n.string("calculator_subtitle"))
                        .font(MonetiqTheme.Typography.subheadline)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                        .opacity(0.8)
                }
                .monetiqHeader()
                .padding(.bottom, MonetiqTheme.Spacing.sm)
                
                // Input Form
                VStack(spacing: MonetiqTheme.Spacing.lg) {
                    // Principal Amount with Integrated Currency Selector
                    AmountCurrencyField(
                        title: L10n.string("calculator_principal"),
                        placeholder: L10n.string("calculator_principal_placeholder"),
                        text: $principalAmount,
                        selectedCurrency: $selectedCurrency,
                        focusedField: $focusedField,
                        fieldType: .principal
                    )
                    
                    CalculatorInputField(
                        title: L10n.string("calculator_interest_rate"),
                        placeholder: L10n.string("calculator_interest_rate_placeholder"),
                        text: $interestRate,
                        suffix: "%",
                        focusedField: $focusedField,
                        fieldType: .interest
                    )
                    
                    CalculatorInputField(
                        title: L10n.string("calculator_number_of_payments"),
                        placeholder: L10n.string("calculator_number_of_payments_placeholder"),
                        text: $numberOfPayments,
                        suffix: "payments",
                        helperText: L10n.string("calculator_number_of_payments_helper"),
                        focusedField: $focusedField,
                        fieldType: .term
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
                            .monetiqButton(style: isInputValid ? .primary : .subtle)
                    }
                    .disabled(!isInputValid)
                    
                    if showValidationError {
                        Text(L10n.string("calculator_validation_error"))
                            .font(MonetiqTheme.Typography.caption)
                            .foregroundColor(MonetiqTheme.Colors.error)
                            .multilineTextAlignment(.center)
                    }
                }
                .monetiqSection()
                
                // Results Card
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.lg) {
                    HStack {
                        Text(L10n.string("calculator_results"))
                            .font(MonetiqTheme.Typography.headline)
                            .foregroundColor(MonetiqTheme.Colors.textPrimary)
                        
                        Spacer()
                        
                        if calculationResult != nil {
                            ShareLink(item: shareText) {
                                HStack(spacing: MonetiqTheme.Spacing.xs) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(MonetiqTheme.Typography.caption)
                                    Text(L10n.string("calculator_share"))
                                        .font(MonetiqTheme.Typography.caption)
                                }
                                .foregroundColor(MonetiqTheme.Colors.accent)
                                .padding(.horizontal, MonetiqTheme.Spacing.sm)
                                .padding(.vertical, MonetiqTheme.Spacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: MonetiqTheme.CornerRadius.sm)
                                        .fill(MonetiqTheme.Colors.accent.opacity(0.1))
                                )
                            }
                        }
                    }
                    
                    VStack(spacing: MonetiqTheme.Spacing.sm) {
                        if let result = calculationResult {
                            ResultRow(
                                title: L10n.string("calculator_payment_per_period", selectedFrequency.localizedLabel),
                                value: result.periodicPaymentAmount.formattedWithSymbol(currency: selectedCurrency),
                                isHighlighted: true
                            )
                            ResultRow(
                                title: L10n.string("calculator_total_to_repay"),
                                value: result.totalToRepay.formattedWithSymbol(currency: selectedCurrency)
                            )
                            ResultRow(
                                title: L10n.string("calculator_total_interest"),
                                value: result.totalInterest.formattedWithSymbol(currency: selectedCurrency)
                            )
                            
                            // Generated timestamp
                            if let generatedAt = generatedAt {
                                Divider()
                                    .padding(.vertical, MonetiqTheme.Spacing.xs)
                                
                                HStack {
                                    Text(L10n.string("calculator_generated"))
                                        .font(MonetiqTheme.Typography.caption)
                                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                                    
                                    Spacer()
                                    
                                    Text(generatedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(MonetiqTheme.Typography.caption)
                                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                                }
                            }
                        } else {
                            Text(L10n.string("calculator_enter_values"))
                                .font(MonetiqTheme.Typography.body)
                                .foregroundColor(MonetiqTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(MonetiqTheme.Spacing.lg)
                        }
                    }
                }
                .monetiqCard(elevated: calculationResult != nil)
                .monetiqSection()
                
                Spacer(minLength: MonetiqTheme.Spacing.xl)
            }
            .padding(.vertical, MonetiqTheme.Spacing.sectionSpacing)
        }
        .monetiqBackground()
        .onTapGesture {
            focusedField = nil
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(L10n.string("general_done")) {
                    focusedField = nil
                }
                .font(MonetiqTheme.Typography.callout)
                .foregroundColor(MonetiqTheme.Colors.accent)
            }
        }
        .onAppear {
            // Set default currency from app settings
            selectedCurrency = appSettings.defaultCurrencyCode
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
    
    private var shareText: String {
        guard let result = calculationResult,
              let principal = Double(principalAmount),
              let rate = Double(interestRate.isEmpty ? "0" : interestRate),
              let term = Int(numberOfPayments),
              let generatedAt = generatedAt else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        return """
        \(L10n.string("calculator_share_title"))
        
        \(L10n.string("calculator_principal")): \(principal.formattedWithSymbol(currency: selectedCurrency))
        \(L10n.string("calculator_interest_rate")): \(String(format: "%.2f", rate))%
        \(L10n.string("calculator_number_of_payments")): \(term)
        \(L10n.string("calculator_frequency")): \(selectedFrequency.localizedLabel)
        
        \(L10n.string("calculator_results")):
        \(L10n.string("calculator_payment_per_period", selectedFrequency.localizedLabel)): \(result.periodicPaymentAmount.formattedWithSymbol(currency: selectedCurrency))
        \(L10n.string("calculator_total_to_repay")): \(result.totalToRepay.formattedWithSymbol(currency: selectedCurrency))
        \(L10n.string("calculator_total_interest")): \(result.totalInterest.formattedWithSymbol(currency: selectedCurrency))
        
        \(L10n.string("calculator_generated")): \(formatter.string(from: generatedAt))
        
        \(L10n.string("calculator_share_footer"))
        """
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
        generatedAt = Date()
    }
}

struct AmountCurrencyField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @Binding var selectedCurrency: String
    var focusedField: FocusState<CalculatorView.Field?>.Binding
    let fieldType: CalculatorView.Field
    
    var body: some View {
        VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
            Text(title)
                .font(MonetiqTheme.Typography.headline)
                .foregroundColor(MonetiqTheme.Colors.onSurface)
            
            HStack(spacing: 0) {
                TextField(placeholder, text: $text)
                    .font(MonetiqTheme.Typography.body)
                    .foregroundColor(MonetiqTheme.Colors.onSurface)
                    .keyboardType(.decimalPad)
                    .focused(focusedField, equals: fieldType)
                    .padding(.leading, MonetiqTheme.Spacing.md)
                    .padding(.vertical, MonetiqTheme.Spacing.md)
                    .accessibilityLabel(title)
                
                // Currency selector pill
                Menu {
                    ForEach(CurrencyCatalog.shared.supportedCurrencies, id: \.code) { currency in
                        Button(action: {
                            selectedCurrency = currency.code
                        }) {
                            HStack {
                                Text(currency.displayName)
                                if selectedCurrency == currency.code {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(MonetiqTheme.Colors.accent)
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: MonetiqTheme.Spacing.xs) {
                        Text(selectedCurrency)
                            .font(MonetiqTheme.Typography.body)
                            .foregroundColor(MonetiqTheme.Colors.accent)
                        Image(systemName: "chevron.down")
                            .font(MonetiqTheme.Typography.caption)
                            .foregroundColor(MonetiqTheme.Colors.accent)
                    }
                    .padding(.horizontal, MonetiqTheme.Spacing.sm)
                    .padding(.vertical, MonetiqTheme.Spacing.xs)
                    .background(MonetiqTheme.Colors.accent.opacity(0.1))
                    .cornerRadius(MonetiqTheme.CornerRadius.sm)
                }
                .accessibilityLabel(L10n.string("calculator_currency"))
                .padding(.trailing, MonetiqTheme.Spacing.md)
                .padding(.vertical, MonetiqTheme.Spacing.md)
            }
            .background(MonetiqTheme.Colors.background)
            .cornerRadius(MonetiqTheme.CornerRadius.sm)
        }
        .monetiqCard()
    }
}

struct CalculatorInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let suffix: String?
    let helperText: String?
    var focusedField: FocusState<CalculatorView.Field?>.Binding
    let fieldType: CalculatorView.Field
    
    init(title: String, placeholder: String, text: Binding<String>, suffix: String? = nil, helperText: String? = nil, focusedField: FocusState<CalculatorView.Field?>.Binding, fieldType: CalculatorView.Field) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.suffix = suffix
        self.helperText = helperText
        self.focusedField = focusedField
        self.fieldType = fieldType
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
                    .focused(focusedField, equals: fieldType)
                
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
        VStack(spacing: MonetiqTheme.Spacing.xs) {
            HStack {
                Text(title)
                    .font(isHighlighted ? MonetiqTheme.Typography.subheadline : MonetiqTheme.Typography.callout)
                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
                
                Spacer()
            }
            
            HStack {
                Spacer()
                
                Text(value)
                    .currencyText(
                        style: isHighlighted ? .large : .medium,
                        color: isHighlighted ? MonetiqTheme.Colors.accent : MonetiqTheme.Colors.textPrimary
                    )
            }
        }
        .padding(.vertical, isHighlighted ? MonetiqTheme.Spacing.md : MonetiqTheme.Spacing.sm)
        .padding(.horizontal, MonetiqTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MonetiqTheme.CornerRadius.md)
                .fill(isHighlighted ? MonetiqTheme.Colors.accent.opacity(0.05) : MonetiqTheme.Colors.surface)
        )
        .background(isHighlighted ? MonetiqTheme.Colors.accent.opacity(0.1) : Color.clear)
        .cornerRadius(MonetiqTheme.CornerRadius.sm)
    }
}

#Preview {
    NavigationStack {
        CalculatorView()
    }
}
