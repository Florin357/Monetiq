//
//  AddEditExpenseView.swift
//  monetiq
//
//  Created by AI Assistant on 26.01.2026.
//

import SwiftUI
import SwiftData

struct AddEditExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let editingExpense: Expense?
    
    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var selectedCurrency: String = "RON"
    @State private var selectedFrequency: ExpenseFrequency = .monthly
    @State private var startDate: Date = Date()
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Date()
    @State private var category: String = ""
    @State private var notes: String = ""
    
    private var currencies: [Currency] {
        CurrencyCatalog.shared.supportedCurrencies
    }
    
    private var appSettings: AppSettings {
        AppSettings.getOrCreate(in: modelContext)
    }
    
    init(expense: Expense? = nil) {
        self.editingExpense = expense
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
                Section(L10n.string("expenses_form_details_section")) {
                    TextField(L10n.string("expenses_field_title"), text: $title)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField(L10n.string("expenses_field_amount"), text: $amount)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                    
                    // Currency Picker
                    HStack {
                        Text(L10n.string("expenses_field_currency"))
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
                    
                    Picker(L10n.string("expenses_field_frequency"), selection: $selectedFrequency) {
                        ForEach(ExpenseFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.localizedLabel).tag(frequency)
                        }
                    }
                    
                    DatePicker(L10n.string("expenses_field_start_date"), selection: $startDate, displayedComponents: .date)
                    
                    // Only show end date option for recurring expenses
                    if selectedFrequency != .oneTime {
                        Toggle(L10n.string("expenses_form_has_end_date"), isOn: $hasEndDate)
                        
                        if hasEndDate {
                            DatePicker(L10n.string("expenses_field_end_date"), selection: $endDate, displayedComponents: .date)
                        }
                    }
                    
                    TextField(L10n.string("expenses_field_category"), text: $category)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField(L10n.string("expenses_field_notes"), text: $notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(editingExpense == nil ? L10n.string("expenses_add_title") : L10n.string("expenses_edit_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.string("general_cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.string("general_save")) {
                        saveExpense()
                    }
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                loadExpenseData()
                
                // Set default currency from app settings if creating new expense
                if editingExpense == nil {
                    selectedCurrency = appSettings.defaultCurrencyCode
                }
            }
        }
    }
    
    private func loadExpenseData() {
        guard let expense = editingExpense else { return }
        
        title = expense.title
        amount = String(expense.amount)
        selectedCurrency = expense.currencyCode
        selectedFrequency = expense.frequency
        startDate = expense.startDate
        hasEndDate = expense.endDate != nil
        if let end = expense.endDate {
            endDate = end
        }
        category = expense.category ?? ""
        notes = expense.notes ?? ""
    }
    
    private func saveExpense() {
        guard let amountValue = parseNumericInput(amount) else { return }
        
        let expense: Expense
        if let existingExpense = editingExpense {
            // Update existing expense
            expense = existingExpense
            expense.title = title.trimmingCharacters(in: .whitespaces)
            expense.amount = amountValue
            expense.currencyCode = selectedCurrency
            expense.frequency = selectedFrequency
            expense.startDate = startDate
            expense.endDate = (selectedFrequency != .oneTime && hasEndDate) ? endDate : nil
            expense.category = category.trimmingCharacters(in: .whitespaces).isEmpty ? nil : category.trimmingCharacters(in: .whitespaces)
            expense.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
            expense.updateTimestamp()
            
            // Refresh schedule (preserves paid occurrences)
            ExpenseScheduleGenerator.refreshSchedule(for: expense, in: modelContext)
        } else {
            // Create new expense
            expense = Expense(
                title: title.trimmingCharacters(in: .whitespaces),
                amount: amountValue,
                currencyCode: selectedCurrency,
                frequency: selectedFrequency,
                startDate: startDate,
                endDate: (selectedFrequency != .oneTime && hasEndDate) ? endDate : nil,
                notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces),
                category: category.trimmingCharacters(in: .whitespaces).isEmpty ? nil : category.trimmingCharacters(in: .whitespaces)
            )
            modelContext.insert(expense)
            
            // Generate initial schedule
            ExpenseScheduleGenerator.generateInitialSchedule(for: expense, in: modelContext)
        }
        
        // Save context
        do {
            try modelContext.save()
        } catch {
            print("Failed to save expense: \(error)")
            return
        }
        
        // Schedule/update notification for this expense
        Task {
            await NotificationManager.shared.scheduleExpenseNotification(for: expense)
        }
        
        dismiss()
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
    AddEditExpenseView()
        .modelContainer(for: [Expense.self, ExpenseOccurrence.self], inMemory: true)
}

