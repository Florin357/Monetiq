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
    var frequency: PaymentFrequency
    var durationInPeriods: Int
    var interestMode: InterestMode
    var interestRateAnnual: Double?
    var totalToRepay: Double?
    var notes: String?
    
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
        durationInPeriods: Int = 12,
        interestMode: InterestMode = .none,
        interestRateAnnual: Double? = nil,
        totalToRepay: Double? = nil,
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
        self.durationInPeriods = durationInPeriods
        self.interestMode = interestMode
        self.interestRateAnnual = interestRateAnnual
        self.totalToRepay = totalToRepay
        self.notes = notes
        self.counterparty = counterparty
    }
}

enum LoanRole: String, CaseIterable, Codable {
    case creditor = "creditor"           // "am dat" - I lent money
    case debtor = "debtor"               // "m-am împrumutat" - I borrowed money
    case creditInstitution = "credit"    // "credit" - bank/institution loan
    
    var displayName: String {
        switch self {
        case .creditor:
            return "Lent Money"
        case .debtor:
            return "Borrowed Money"
        case .creditInstitution:
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
