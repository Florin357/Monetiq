//
//  AddEditIncomeView.swift
//  monetiq
//
//  Created by Florin Mihai on 28.12.2025.
//

import SwiftUI
import SwiftData

struct AddEditIncomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let editingIncome: IncomeSource?
    
    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var selectedCurrency: String = "RON"
    @State private var selectedFrequency: IncomeFrequency = .monthly
    @State private var startDate: Date = Date()
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Date()
    @State private var counterpartyName: String = ""
    @State private var notes: String = ""
    
    private var currencies: [Currency] {
        CurrencyCatalog.shared.supportedCurrencies
    }
    
    private var appSettings: AppSettings {
        AppSettings.getOrCreate(in: modelContext)
    }
    
    init(income: IncomeSource? = nil) {
        self.editingIncome = income
    }
    
    var isFormValid: Bool {
        let basicFieldsValid = !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !amount.trimmingCharacters(in: .whitespaces).isEmpty &&
        parseNumericInput(amount) != nil &&
        parseNumericInput(amount) ?? 0 > 0
        
        return basicFieldsValid
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.string("income_form_details_section")) {
                    TextField(L10n.string("income_form_title"), text: $title)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField(L10n.string("income_form_amount"), text: $amount)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                    
                    // Currency Picker
                    HStack {
                        Text(L10n.string("income_form_currency"))
                            .font(MonetiqTheme.Typography.body)
                            .foregroundColor(MonetiqTheme.Colors.textPrimary)
                        
                        Spacer()
                        
                        Menu {
                            ForEach(currencies, id: \.code) { currency in
                                Button(action: {
                                    selectedCurrency = currency.code
                                }) {
                                    HStack {
                                        Text("\(currency.flag)  \(currency.symbol)  \(currency.code)")
                                        if currency.code == selectedCurrency {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                if let currency = currencies.first(where: { $0.code == selectedCurrency }) {
                                    Text("\(currency.flag) \(currency.code)")
                                        .font(MonetiqTheme.Typography.body)
                                        .foregroundColor(MonetiqTheme.Colors.textPrimary)
                                }
                                
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(MonetiqTheme.Colors.textTertiary)
                            }
                        }
                    }
                    
                    Picker(L10n.string("income_form_frequency"), selection: $selectedFrequency) {
                        ForEach(IncomeFrequency.allCases, id: \.self) { frequency in
                            Text(frequencyLabel(for: frequency)).tag(frequency)
                        }
                    }
                    
                    DatePicker(L10n.string("income_form_start_date"), selection: $startDate, displayedComponents: .date)
                    
                    Toggle(L10n.string("income_form_has_end_date"), isOn: $hasEndDate)
                    
                    if hasEndDate {
                        DatePicker(L10n.string("income_form_end_date"), selection: $endDate, displayedComponents: .date)
                    }
                    
                    TextField(L10n.string("income_form_counterparty"), text: $counterpartyName)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField(L10n.string("income_form_notes"), text: $notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(editingIncome == nil ? L10n.string("income_add_title") : L10n.string("income_edit_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.string("general_cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.string("general_save")) {
                        saveIncome()
                    }
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                loadIncomeData()
                
                // Set default currency from app settings if creating new income
                if editingIncome == nil {
                    selectedCurrency = appSettings.defaultCurrencyCode
                }
            }
        }
    }
    
    private func loadIncomeData() {
        guard let income = editingIncome else { return }
        
        title = income.title
        amount = String(income.amount)
        selectedCurrency = income.currencyCode
        selectedFrequency = income.frequency
        startDate = income.startDate
        hasEndDate = income.endDate != nil
        if let end = income.endDate {
            endDate = end
        }
        counterpartyName = income.counterpartyName ?? ""
        notes = income.notes ?? ""
    }
    
    private func saveIncome() {
        guard let amountValue = parseNumericInput(amount) else { return }
        
        let income: IncomeSource
        if let existingIncome = editingIncome {
            // Update existing income
            income = existingIncome
            income.title = title.trimmingCharacters(in: .whitespaces)
            income.amount = amountValue
            income.currencyCode = selectedCurrency
            income.frequency = selectedFrequency
            income.startDate = startDate
            income.endDate = hasEndDate ? endDate : nil
            income.counterpartyName = counterpartyName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : counterpartyName.trimmingCharacters(in: .whitespaces)
            income.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
            income.updateTimestamp()
            
            // Refresh schedule (preserves received payments)
            IncomeScheduleGenerator.refreshSchedule(for: income, in: modelContext)
        } else {
            // Create new income
            income = IncomeSource(
                title: title.trimmingCharacters(in: .whitespaces),
                amount: amountValue,
                currencyCode: selectedCurrency,
                frequency: selectedFrequency,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                counterpartyName: counterpartyName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : counterpartyName.trimmingCharacters(in: .whitespaces),
                notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
            )
            modelContext.insert(income)
            
            // Generate initial schedule
            IncomeScheduleGenerator.generateInitialSchedule(for: income, in: modelContext)
        }
        
        // Save context
        do {
            try modelContext.save()
        } catch {
            print("Failed to save income: \(error)")
            return
        }
        
        dismiss()
    }
    
    private func frequencyLabel(for frequency: IncomeFrequency) -> String {
        switch frequency {
        case .weekly:
            return L10n.string("income_frequency_weekly")
        case .monthly:
            return L10n.string("income_frequency_monthly")
        case .quarterly:
            return L10n.string("income_frequency_quarterly")
        case .yearly:
            return L10n.string("income_frequency_yearly")
        case .oneTime:
            return L10n.string("income_frequency_one_time")
        }
    }
    
    /// Formats numeric input by removing non-numeric characters and normalizing decimal separators
    /// Supports both comma and dot as decimal separators
    private func formatNumericInput(_ input: String, allowDecimals: Bool = true) -> String {
        var cleaned = input.trimmingCharacters(in: .whitespaces)
        
        // Remove all characters except digits, comma, and dot
        cleaned = cleaned.filter { $0.isNumber || $0 == "," || $0 == "." }
        
        // Replace comma with dot for consistent decimal separator
        cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
        
        // If decimals not allowed, remove decimal point and everything after
        if !allowDecimals {
            if let dotIndex = cleaned.firstIndex(of: ".") {
                cleaned = String(cleaned[..<dotIndex])
            }
        }
        
        // Ensure only one decimal point
        var normalized = ""
        var hasDecimal = false
        
        for char in cleaned {
            if char == "." {
                if !hasDecimal {
                    normalized.append(char)
                    hasDecimal = true
                }
            } else {
                normalized.append(char)
            }
        }
        
        // Limit decimal places to 2
        if let dotIndex = normalized.firstIndex(of: ".") {
            let beforeDot = String(normalized[..<dotIndex])
            let afterDotIndex = normalized.index(after: dotIndex)
            let afterDot = String(normalized[afterDotIndex...].prefix(2))
            normalized = beforeDot + "." + afterDot
        }
        
        return normalized
    }
    
    /// Parses numeric input that may contain various separators
    /// Returns Double value or nil if invalid
    private func parseNumericInput(_ input: String) -> Double? {
        let cleaned = formatNumericInput(input, allowDecimals: true)
        return Double(cleaned)
    }
}

#Preview {
    AddEditIncomeView()
        .modelContainer(for: [IncomeSource.self, IncomePayment.self], inMemory: true)
}

