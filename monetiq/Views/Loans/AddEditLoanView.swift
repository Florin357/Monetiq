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
    
    private let currencies = ["RON", "EUR", "USD", "GBP"]
    
    init(loan: Loan? = nil) {
        self.editingLoan = loan
    }
    
    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !counterpartyName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !principalAmount.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(principalAmount) != nil &&
        Double(principalAmount) ?? 0 > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Loan Details") {
                    TextField("Loan Title", text: $title)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker("Role", selection: $selectedRole) {
                        ForEach(LoanRole.allCases, id: \.self) { role in
                            Text(role.displayName).tag(role)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Counterparty") {
                    TextField("Name", text: $counterpartyName)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker("Type", selection: $counterpartyType) {
                        ForEach(CounterpartyType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Financial Details") {
                    HStack {
                        TextField("Amount", text: $principalAmount)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                        
                        Picker("Currency", selection: $selectedCurrency) {
                            ForEach(currencies, id: \.self) { currency in
                                Text(currency).tag(currency)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section("Dates") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    
                    Toggle("Set Next Due Date", isOn: $hasNextDueDate)
                    
                    if hasNextDueDate {
                        DatePicker("Next Due Date", selection: $nextDueDate, displayedComponents: .date)
                    }
                }
                
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .navigationTitle(editingLoan == nil ? "Add Loan" : "Edit Loan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveLoan()
                    }
                    .disabled(!isFormValid)
                    .foregroundColor(isFormValid ? MonetiqTheme.Colors.accent : MonetiqTheme.Colors.textSecondary)
                }
            }
        }
        .onAppear {
            loadLoanData()
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
        
        if let existingLoan = editingLoan {
            // Update existing loan
            existingLoan.title = title.trimmingCharacters(in: .whitespaces)
            existingLoan.role = selectedRole
            existingLoan.principalAmount = Double(principalAmount) ?? 0
            existingLoan.currencyCode = selectedCurrency
            existingLoan.startDate = startDate
            existingLoan.nextDueDate = hasNextDueDate ? nextDueDate : nil
            existingLoan.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
            existingLoan.counterparty = counterparty
            existingLoan.updateTimestamp()
        } else {
            // Create new loan
            let newLoan = Loan(
                title: title.trimmingCharacters(in: .whitespaces),
                role: selectedRole,
                principalAmount: Double(principalAmount) ?? 0,
                currencyCode: selectedCurrency,
                startDate: startDate,
                nextDueDate: hasNextDueDate ? nextDueDate : nil,
                notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces),
                counterparty: counterparty
            )
            
            modelContext.insert(newLoan)
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
        .modelContainer(for: [Counterparty.self, Loan.self], inMemory: true)
}
