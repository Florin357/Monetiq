//
//  Loan.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import Foundation
import SwiftData

@Model
final class Loan {
    var id: UUID
    var title: String
    var role: LoanRole
    var principalAmount: Double
    var currencyCode: String
    var startDate: Date
    var nextDueDate: Date?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    // Calculation fields
    var frequency: PaymentFrequency
    var numberOfPeriods: Int
    var interestMode: InterestMode
    var annualInterestRate: Double?
    var fixedTotalToRepay: Double?
    var totalToRepay: Double?
    var periodicPaymentAmount: Double?
    
    // Relationships
    var counterparty: Counterparty?
    
    @Relationship(deleteRule: .cascade, inverse: \Payment.loan)
    var payments: [Payment] = []
    
    init(
        title: String,
        role: LoanRole,
        principalAmount: Double,
        currencyCode: String = "RON",
        startDate: Date = Date(),
        frequency: PaymentFrequency = .monthly,
        numberOfPeriods: Int = 12,
        interestMode: InterestMode = .none,
        annualInterestRate: Double? = nil,
        fixedTotalToRepay: Double? = nil,
        nextDueDate: Date? = nil,
        notes: String? = nil,
        counterparty: Counterparty? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.role = role
        self.principalAmount = principalAmount
        self.currencyCode = currencyCode
        self.startDate = startDate
        self.frequency = frequency
        self.numberOfPeriods = numberOfPeriods
        self.interestMode = interestMode
        self.annualInterestRate = annualInterestRate
        self.fixedTotalToRepay = fixedTotalToRepay
        self.nextDueDate = nextDueDate
        self.notes = notes
        self.counterparty = counterparty
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func updateTimestamp() {
        self.updatedAt = Date()
    }
    
    var totalPaid: Double {
        payments.filter { $0.status == .paid }.reduce(0) { $0 + $1.amount }
    }
    
    var remainingToPay: Double {
        (totalToRepay ?? principalAmount) - totalPaid
    }
    
    var upcomingPayments: [Payment] {
        payments
            .filter { $0.status == .planned }
            .sorted { $0.dueDate < $1.dueDate }
    }
}

enum LoanRole: String, CaseIterable, Codable {
    case lent = "lent"                   // "am dat" - I lent money
    case borrowed = "borrowed"           // "m-am împrumutat" - I borrowed money
    case bankCredit = "bankCredit"       // "credit" - bank/institution loan
    
    var displayName: String {
        switch self {
        case .lent:
            return "Lent"
        case .borrowed:
            return "Borrowed"
        case .bankCredit:
            return "Bank Credit"
        }
    }
}

enum PaymentFrequency: String, CaseIterable, Codable {
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
        case .quarterly:
            return "Quarterly"
        case .yearly:
            return "Yearly"
        }
    }
}

enum InterestMode: String, CaseIterable, Codable {
    case none = "none"
    case percentageAnnual = "percentageAnnual"
    case fixedTotal = "fixedTotal"
    
    var displayName: String {
        switch self {
        case .none:
            return "No Interest"
        case .percentageAnnual:
            return "Annual Percentage"
        case .fixedTotal:
            return "Fixed Total"
        }
    }
}

