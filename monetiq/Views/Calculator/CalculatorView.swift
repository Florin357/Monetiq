//
//  CalculatorView.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import SwiftUI

struct CalculatorView: View {
    @State private var principalAmount: String = ""
    @State private var interestRate: String = ""
    @State private var loanTerm: String = ""
    @State private var selectedFrequency: String = "Monthly"
    
    private let frequencies = ["Weekly", "Monthly", "Quarterly", "Yearly"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: MonetiqTheme.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
                    Text("Loan Calculator")
                        .font(MonetiqTheme.Typography.largeTitle)
                        .foregroundColor(MonetiqTheme.Colors.onBackground)
                    
                    Text("Calculate loan payments and interest")
                        .font(MonetiqTheme.Typography.callout)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, MonetiqTheme.Spacing.md)
                
                // Input Form
                VStack(spacing: MonetiqTheme.Spacing.md) {
                    CalculatorInputField(
                        title: "Principal Amount",
                        placeholder: "Enter amount",
                        text: $principalAmount,
                        suffix: "RON"
                    )
                    
                    CalculatorInputField(
                        title: "Annual Interest Rate",
                        placeholder: "Enter rate",
                        text: $interestRate,
                        suffix: "%"
                    )
                    
                    CalculatorInputField(
                        title: "Loan Term",
                        placeholder: "Enter duration",
                        text: $loanTerm,
                        suffix: "periods"
                    )
                    
                    // Frequency Picker
                    VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
                        Text("Payment Frequency")
                            .font(MonetiqTheme.Typography.headline)
                            .foregroundColor(MonetiqTheme.Colors.onSurface)
                        
                        Picker("Frequency", selection: $selectedFrequency) {
                            ForEach(frequencies, id: \.self) { frequency in
                                Text(frequency).tag(frequency)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .monetiqCard()
                }
                .padding(.horizontal, MonetiqTheme.Spacing.md)
                
                // Calculate Button
                Button(action: calculatePayment) {
                    Text("Calculate Payment")
                        .font(MonetiqTheme.Typography.headline)
                        .foregroundColor(MonetiqTheme.Colors.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(MonetiqTheme.Spacing.md)
                        .background(MonetiqTheme.Colors.accent)
                        .cornerRadius(MonetiqTheme.CornerRadius.md)
                }
                .padding(.horizontal, MonetiqTheme.Spacing.md)
                
                // Results Placeholder
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                    Text("Results")
                        .font(MonetiqTheme.Typography.headline)
                        .foregroundColor(MonetiqTheme.Colors.onSurface)
                    
                    VStack(spacing: MonetiqTheme.Spacing.sm) {
                        ResultRow(title: "Monthly Payment", value: "0.00 RON")
                        ResultRow(title: "Total Interest", value: "0.00 RON")
                        ResultRow(title: "Total Amount", value: "0.00 RON")
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
        // Placeholder for calculation logic
        // In a real app, this would perform loan calculations
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
