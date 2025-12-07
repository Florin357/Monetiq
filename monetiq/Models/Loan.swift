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
    
    // Relationships
    var counterparty: Counterparty?
    
    init(
        title: String,
        role: LoanRole,
        principalAmount: Double,
        currencyCode: String = "RON",
        startDate: Date = Date(),
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
        self.nextDueDate = nextDueDate
        self.notes = notes
        self.counterparty = counterparty
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func updateTimestamp() {
        self.updatedAt = Date()
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

