//
//  SampleData.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import Foundation
import SwiftData

struct SampleData {
    
    static func createSampleData(in context: ModelContext) {
        // Create sample counterparties
        let ionPopescu = Counterparty(name: "Ion Popescu", type: .person, notes: "Friend from university")
        let bankAlpha = Counterparty(name: "Bank Alpha", type: .institution, notes: "Main bank for personal loans")
        let mariaPopa = Counterparty(name: "Maria Popa", type: .person, notes: "Business partner")
        
        context.insert(ionPopescu)
        context.insert(bankAlpha)
        context.insert(mariaPopa)
        
        // Create sample loans
        let loanToIon = Loan(
            title: "Personal Loan to Ion",
            role: .creditor,
            principalAmount: 5000.0,
            currencyCode: "RON",
            startDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
            frequency: .monthly,
            durationInPeriods: 12,
            interestMode: .percentageAnnual,
            interestRateAnnual: 5.0,
            notes: "Emergency loan for medical expenses",
            counterparty: ionPopescu
        )
        
        let bankLoan = Loan(
            title: "Home Mortgage",
            role: .creditInstitution,
            principalAmount: 150000.0,
            currencyCode: "RON",
            startDate: Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date(),
            frequency: .monthly,
            durationInPeriods: 240,
            interestMode: .percentageAnnual,
            interestRateAnnual: 4.5,
            notes: "30-year mortgage for apartment purchase",
            counterparty: bankAlpha
        )
        
        let loanFromMaria = Loan(
            title: "Business Investment",
            role: .debtor,
            principalAmount: 25000.0,
            currencyCode: "EUR",
            startDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
            frequency: .quarterly,
            durationInPeriods: 8,
            interestMode: .fixedTotal,
            totalToRepay: 27000.0,
            notes: "Investment for business expansion",
            counterparty: mariaPopa
        )
        
        context.insert(loanToIon)
        context.insert(bankLoan)
        context.insert(loanFromMaria)
        
        // Create sample payments for each loan
        createSamplePayments(for: loanToIon, in: context)
        createSamplePayments(for: bankLoan, in: context)
        createSamplePayments(for: loanFromMaria, in: context)
        
        try? context.save()
    }
    
    private static func createSamplePayments(for loan: Loan, in context: ModelContext) {
        let calendar = Calendar.current
        let startDate = loan.startDate
        
        for i in 0..<min(loan.durationInPeriods, 6) { // Create first 6 payments as sample
            let dueDate: Date
            
            switch loan.frequency {
            case .weekly:
                dueDate = calendar.date(byAdding: .weekOfYear, value: i, to: startDate) ?? startDate
            case .monthly:
                dueDate = calendar.date(byAdding: .month, value: i, to: startDate) ?? startDate
            case .quarterly:
                dueDate = calendar.date(byAdding: .month, value: i * 3, to: startDate) ?? startDate
            case .yearly:
                dueDate = calendar.date(byAdding: .year, value: i, to: startDate) ?? startDate
            }
            
            let amount = calculatePaymentAmount(for: loan)
            let status = determinePaymentStatus(dueDate: dueDate)
            let paidDate = status == .paid ? dueDate : nil
            
            let payment = Payment(
                dueDate: dueDate,
                amount: amount,
                status: status,
                paidDate: paidDate,
                loan: loan
            )
            
            context.insert(payment)
        }
    }
    
    private static func calculatePaymentAmount(for loan: Loan) -> Double {
        // Simplified payment calculation
        switch loan.interestMode {
        case .none:
            return loan.principalAmount / Double(loan.durationInPeriods)
        case .percentageAnnual:
            // Simple interest calculation for demo
            let totalInterest = loan.principalAmount * (loan.interestRateAnnual ?? 0.0) / 100.0
            return (loan.principalAmount + totalInterest) / Double(loan.durationInPeriods)
        case .fixedTotal:
            return (loan.totalToRepay ?? loan.principalAmount) / Double(loan.durationInPeriods)
        }
    }
    
    private static func determinePaymentStatus(dueDate: Date) -> PaymentStatus {
        let now = Date()
        let daysDifference = Calendar.current.dateComponents([.day], from: dueDate, to: now).day ?? 0
        
        if daysDifference > 0 {
            return .paid // Past dates are marked as paid
        } else if daysDifference < -7 {
            return .planned // Future dates more than a week away
        } else {
            return .planned // Upcoming payments
        }
    }
    
    // Helper for previews
    static func previewContainer() -> ModelContainer {
        do {
            let container = try ModelContainer(
                for: Counterparty.self, Loan.self, Payment.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            
            createSampleData(in: container.mainContext)
            
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}
