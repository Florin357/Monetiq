//
//  AddEditLoanView.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import SwiftUI
import SwiftData

struct AddEditLoanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingCounterparties: [Counterparty]
    
    let editingLoan: Loan?
    
    private var notificationManager: NotificationManager {
        NotificationManager.shared
    }
    
    @State private var title: String = ""
    @State private var selectedRole: LoanRole = .lent
    @State private var counterpartyName: String = ""
    @State private var counterpartyType: CounterpartyType = .person
    @State private var principalAmount: String = ""
    @State private var selectedCurrency: String = "RON"
    @State private var startDate: Date = Date()
    @State private var nextDueDate: Date = Date()
    @State private var hasNextDueDate: Bool = false
    @State private var notes: String = ""
    
    // Calculation fields
    @State private var selectedFrequency: PaymentFrequency = .monthly
    @State private var numberOfPeriods: String = "12"
    @State private var selectedInterestMode: InterestMode = .none
    @State private var annualInterestRate: String = ""
    @State private var fixedTotalToRepay: String = ""
    
    private var currencies: [String] {
        CurrencyCatalog.shared.currencyCodes
    }
    
    private var appSettings: AppSettings {
        AppSettings.getOrCreate(in: modelContext)
    }
    
    init(loan: Loan? = nil) {
        self.editingLoan = loan
    }
    
    var isFormValid: Bool {
        let basicFieldsValid = !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !counterpartyName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !principalAmount.trimmingCharacters(in: .whitespaces).isEmpty &&
        parseNumericInput(principalAmount) != nil &&
        parseNumericInput(principalAmount) ?? 0 > 0 &&
        !numberOfPeriods.trimmingCharacters(in: .whitespaces).isEmpty &&
        Int(numberOfPeriods) != nil &&
        Int(numberOfPeriods) ?? 0 > 0
        
        let interestFieldsValid: Bool
        switch selectedInterestMode {
        case .none:
            interestFieldsValid = true
        case .percentageAnnual:
            interestFieldsValid = !annualInterestRate.trimmingCharacters(in: .whitespaces).isEmpty &&
                                parseNumericInput(annualInterestRate) != nil &&
                                parseNumericInput(annualInterestRate) ?? 0 >= 0
        case .fixedTotal:
            interestFieldsValid = !fixedTotalToRepay.trimmingCharacters(in: .whitespaces).isEmpty &&
                                parseNumericInput(fixedTotalToRepay) != nil &&
                                parseNumericInput(fixedTotalToRepay) ?? 0 > 0
        }
        
        return basicFieldsValid && interestFieldsValid
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.string("loan_details_section")) {
                    TextField(L10n.string("loan_title_placeholder"), text: $title)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker(L10n.string("role_label"), selection: $selectedRole) {
                        ForEach(LoanRole.allCases, id: \.self) { role in
                            Text(role.localizedLabel).tag(role)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedRole) { oldValue, newValue in
                        // Auto-select Institution when Bank Credit is selected
                        if newValue == .bankCredit {
                            counterpartyType = .institution
                        }
                    }
                }
                
                Section(L10n.string("counterparty_section")) {
                    TextField(L10n.string("counterparty_name_placeholder"), text: $counterpartyName)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker(L10n.string("counterparty_type_label"), selection: $counterpartyType) {
                        ForEach(CounterpartyType.allCases, id: \.self) { type in
                            Text(type.localizedLabel).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(L10n.string("financial_details_section")) {
                    HStack {
                        TextField(L10n.string("amount_placeholder"), text: $principalAmount)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: principalAmount) { oldValue, newValue in
                                principalAmount = formatNumericInput(newValue, allowDecimals: true)
                            }
                        
                        Picker(L10n.string("currency_label"), selection: $selectedCurrency) {
                            ForEach(currencies, id: \.self) { currency in
                                Text(currency).tag(currency)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section(L10n.string("repayment_schedule_section")) {
                    Picker(L10n.string("payment_frequency_label"), selection: $selectedFrequency) {
                        ForEach(PaymentFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.localizedLabel).tag(frequency)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    TextField(L10n.string("number_of_payments_placeholder"), text: $numberOfPeriods)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section(L10n.string("interest_section")) {
                    Picker(L10n.string("interest_mode_label"), selection: $selectedInterestMode) {
                        ForEach(InterestMode.allCases, id: \.self) { mode in
                            Text(mode.localizedLabel).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if selectedInterestMode == .percentageAnnual {
                        TextField(L10n.string("annual_interest_rate_placeholder"), text: $annualInterestRate)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: annualInterestRate) { oldValue, newValue in
                                annualInterestRate = formatNumericInput(newValue, allowDecimals: true)
                            }
                    }
                    
                    if selectedInterestMode == .fixedTotal {
                        TextField(L10n.string("fixed_total_repay_placeholder"), text: $fixedTotalToRepay)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: fixedTotalToRepay) { oldValue, newValue in
                                fixedTotalToRepay = formatNumericInput(newValue, allowDecimals: true)
                            }
                    }
                }
                
                Section(L10n.string("dates_section")) {
                    DatePicker(L10n.string("start_date_label"), selection: $startDate, displayedComponents: .date)
                    
                    Toggle(L10n.string("set_next_due_date"), isOn: $hasNextDueDate)
                    
                    if hasNextDueDate {
                        DatePicker(L10n.string("next_due_date_label"), selection: $nextDueDate, displayedComponents: .date)
                    }
                }
                
                Section(L10n.string("notes_section")) {
                    TextField(L10n.string("optional_notes_placeholder"), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .navigationTitle(editingLoan == nil ? L10n.string("add_loan_title") : L10n.string("edit_loan_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.string("cancel_button")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.string("save_button")) {
                        saveLoan()
                    }
                    .disabled(!isFormValid)
                    .foregroundColor(isFormValid ? MonetiqTheme.Colors.accent : MonetiqTheme.Colors.textSecondary)
                }
            }
        }
        .onAppear {
            loadLoanData()
            // Set default currency if creating new loan
            if editingLoan == nil && selectedCurrency == "RON" {
                selectedCurrency = appSettings.defaultCurrencyCode
            }
        }
    }
    
    private func loadLoanData() {
        guard let loan = editingLoan else { return }
        
        title = loan.title
        selectedRole = loan.role
        counterpartyName = loan.counterparty?.name ?? ""
        counterpartyType = loan.counterparty?.type ?? .person
        principalAmount = String(loan.principalAmount)
        selectedCurrency = loan.currencyCode
        startDate = loan.startDate
        
        // Load calculation fields
        selectedFrequency = loan.frequency
        numberOfPeriods = String(loan.numberOfPeriods)
        selectedInterestMode = loan.interestMode
        annualInterestRate = loan.annualInterestRate != nil ? String(loan.annualInterestRate!) : ""
        fixedTotalToRepay = loan.fixedTotalToRepay != nil ? String(loan.fixedTotalToRepay!) : ""
        
        if let nextDue = loan.nextDueDate {
            nextDueDate = nextDue
            hasNextDueDate = true
        }
        
        notes = loan.notes ?? ""
    }
    
    private func saveLoan() {
        guard isFormValid else { return }
        
        // Find or create counterparty
        let counterparty = findOrCreateCounterparty()
        
        // Prepare calculation input
        let calculationInput = LoanCalculationInput(
            principal: parseNumericInput(principalAmount) ?? 0,
            annualInterestRate: selectedInterestMode == .percentageAnnual ? parseNumericInput(annualInterestRate) : nil,
            numberOfPeriods: Int(numberOfPeriods) ?? 12,
            frequency: selectedFrequency,
            interestMode: selectedInterestMode,
            fixedTotalToRepay: selectedInterestMode == .fixedTotal ? parseNumericInput(fixedTotalToRepay) : nil,
            startDate: startDate
        )
        
        // Calculate schedule
        let calculationOutput = LoanCalculator.generateSchedule(input: calculationInput)
        
        let loan: Loan
        if let existingLoan = editingLoan {
            // Update existing loan
            loan = existingLoan
            loan.title = title.trimmingCharacters(in: .whitespaces)
            loan.role = selectedRole
            loan.principalAmount = Double(principalAmount) ?? 0
            loan.currencyCode = selectedCurrency
            loan.startDate = startDate
            loan.frequency = selectedFrequency
            loan.numberOfPeriods = Int(numberOfPeriods) ?? 12
            loan.interestMode = selectedInterestMode
            loan.annualInterestRate = selectedInterestMode == .percentageAnnual ? Double(annualInterestRate) : nil
            loan.fixedTotalToRepay = selectedInterestMode == .fixedTotal ? Double(fixedTotalToRepay) : nil
            loan.totalToRepay = calculationOutput.totalToRepay
            loan.periodicPaymentAmount = calculationOutput.periodicPaymentAmount
            loan.nextDueDate = hasNextDueDate ? nextDueDate : calculationOutput.schedule.first?.dueDate
            loan.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
            loan.counterparty = counterparty
            loan.updateTimestamp()
            
            // Remove existing payments
            for payment in loan.payments {
                modelContext.delete(payment)
            }
        } else {
            // Create new loan
            loan = Loan(
                title: title.trimmingCharacters(in: .whitespaces),
                role: selectedRole,
                principalAmount: Double(principalAmount) ?? 0,
                currencyCode: selectedCurrency,
                startDate: startDate,
                frequency: selectedFrequency,
                numberOfPeriods: Int(numberOfPeriods) ?? 12,
                interestMode: selectedInterestMode,
                annualInterestRate: selectedInterestMode == .percentageAnnual ? Double(annualInterestRate) : nil,
                fixedTotalToRepay: selectedInterestMode == .fixedTotal ? Double(fixedTotalToRepay) : nil,
                nextDueDate: hasNextDueDate ? nextDueDate : calculationOutput.schedule.first?.dueDate,
                notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces),
                counterparty: counterparty
            )
            
            loan.totalToRepay = calculationOutput.totalToRepay
            loan.periodicPaymentAmount = calculationOutput.periodicPaymentAmount
            
            modelContext.insert(loan)
        }
        
        // Create new payments from schedule
        for scheduleItem in calculationOutput.schedule {
            let payment = Payment(
                dueDate: scheduleItem.dueDate,
                amount: scheduleItem.amount,
                status: .planned,
                loan: loan
            )
            modelContext.insert(payment)
        }
        
        // Save context first
        do {
            try modelContext.save()
        } catch {
            print("Failed to save loan: \(error)")
            return
        }
        
        // Schedule notifications for the loan
        Task {
            // Get app settings and set them in notification manager
            let appSettings = AppSettings.getOrCreate(in: modelContext)
            notificationManager.setAppSettings(appSettings)
            
            // Schedule notifications for this loan
            await notificationManager.schedulePaymentNotifications(for: loan)
            
            // Update badge count after scheduling
            await notificationManager.updateBadgeCount()
        }
        
        dismiss()
    }
    
    private func findOrCreateCounterparty() -> Counterparty {
        let trimmedName = counterpartyName.trimmingCharacters(in: .whitespaces)
        
        // Try to find existing counterparty with the same name
        if let existing = existingCounterparties.first(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            // Update type if different
            if existing.type != counterpartyType {
                existing.type = counterpartyType
            }
            return existing
        }
        
        // Create new counterparty
        let newCounterparty = Counterparty(
            name: trimmedName,
            type: counterpartyType
        )
        
        modelContext.insert(newCounterparty)
        return newCounterparty
    }
    
    // MARK: - Numeric Input Formatting Helpers
    
    /// Formats numeric input to allow both dot and comma as decimal separators
    /// and optional thousand separators (dot, comma, space)
    /// Example: "150000" -> "150000", "150,000.50" -> "150000.50", "11,46" -> "11.46"
    private func formatNumericInput(_ input: String, allowDecimals: Bool) -> String {
        // Allow digits, dots, commas, and spaces
        let allowedCharacters = CharacterSet(charactersIn: "0123456789., ")
        let filtered = input.components(separatedBy: allowedCharacters.inverted).joined()
        
        if !allowDecimals {
            // For integers, remove all separators
            return filtered.components(separatedBy: CharacterSet(charactersIn: "., ")).joined()
        }
        
        // For decimals, normalize to use dot as decimal separator
        // Remove spaces first
        var normalized = filtered.replacingOccurrences(of: " ", with: "")
        
        // Count separators to determine intent
        let commaCount = normalized.filter { $0 == "," }.count
        let dotCount = normalized.filter { $0 == "." }.count
        
        // If both exist, assume the last one is decimal separator
        if commaCount > 0 && dotCount > 0 {
            // Find last separator
            if let lastCommaIndex = normalized.lastIndex(of: ","),
               let lastDotIndex = normalized.lastIndex(of: ".") {
                if lastCommaIndex > lastDotIndex {
                    // Comma is decimal separator, remove dots
                    normalized = normalized.replacingOccurrences(of: ".", with: "")
                    normalized = normalized.replacingOccurrences(of: ",", with: ".")
                } else {
                    // Dot is decimal separator, remove commas
                    normalized = normalized.replacingOccurrences(of: ",", with: "")
                }
            }
        } else if commaCount > 0 {
            // Only commas: if single comma, treat as decimal; if multiple, remove all
            if commaCount == 1 {
                normalized = normalized.replacingOccurrences(of: ",", with: ".")
            } else {
                normalized = normalized.replacingOccurrences(of: ",", with: "")
            }
        }
        // If only dots, keep as is (could be thousand separator or decimal)
        
        // Ensure only one decimal separator
        if let firstDotIndex = normalized.firstIndex(of: ".") {
            let beforeDot = String(normalized[..<firstDotIndex])
            let afterDot = String(normalized[normalized.index(after: firstDotIndex)...])
                .replacingOccurrences(of: ".", with: "")
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
    AddEditLoanView()
        .modelContainer(for: [Counterparty.self, Loan.self, Payment.self], inMemory: true)
}
