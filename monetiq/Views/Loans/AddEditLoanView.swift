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
        Double(principalAmount) != nil &&
        Double(principalAmount) ?? 0 > 0 &&
        !numberOfPeriods.trimmingCharacters(in: .whitespaces).isEmpty &&
        Int(numberOfPeriods) != nil &&
        Int(numberOfPeriods) ?? 0 > 0
        
        let interestFieldsValid: Bool
        switch selectedInterestMode {
        case .none:
            interestFieldsValid = true
        case .percentageAnnual:
            interestFieldsValid = !annualInterestRate.trimmingCharacters(in: .whitespaces).isEmpty &&
                                Double(annualInterestRate) != nil &&
                                Double(annualInterestRate) ?? 0 >= 0
        case .fixedTotal:
            interestFieldsValid = !fixedTotalToRepay.trimmingCharacters(in: .whitespaces).isEmpty &&
                                Double(fixedTotalToRepay) != nil &&
                                Double(fixedTotalToRepay) ?? 0 > 0
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
                    }
                    
                    if selectedInterestMode == .fixedTotal {
                        TextField(L10n.string("fixed_total_repay_placeholder"), text: $fixedTotalToRepay)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
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
            principal: Double(principalAmount) ?? 0,
            annualInterestRate: selectedInterestMode == .percentageAnnual ? Double(annualInterestRate) : nil,
            numberOfPeriods: Int(numberOfPeriods) ?? 12,
            frequency: selectedFrequency,
            interestMode: selectedInterestMode,
            fixedTotalToRepay: selectedInterestMode == .fixedTotal ? Double(fixedTotalToRepay) : nil,
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
}

#Preview {
    AddEditLoanView()
        .modelContainer(for: [Counterparty.self, Loan.self, Payment.self], inMemory: true)
}
