//
//  IncomeSource.swift
//  monetiq
//
//  Created by Florin Mihai on 28.12.2025.
//

import Foundation
import SwiftData

@Model
final class IncomeSource {
    var id: UUID
    var title: String
    var amount: Double
    var currencyCode: String
    var frequency: IncomeFrequency
    var startDate: Date
    var endDate: Date?
    var counterpartyName: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \IncomePayment.incomeSource)
    var payments: [IncomePayment] = []
    
    init(
        title: String,
        amount: Double,
        currencyCode: String = "RON",
        frequency: IncomeFrequency = .monthly,
        startDate: Date = Date(),
        endDate: Date? = nil,
        counterpartyName: String? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.amount = amount
        self.currencyCode = currencyCode
        self.frequency = frequency
        self.startDate = startDate
        self.endDate = endDate
        self.counterpartyName = counterpartyName
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func updateTimestamp() {
        self.updatedAt = Date()
    }
    
    /// Derived status: active if no endDate or endDate is in the future
    var status: IncomeStatus {
        guard let endDate = endDate else { return .active }
        return endDate >= Date() ? .active : .ended
    }
    
    /// Check if income is completed (ended)
    /// Uses timezone-safe date comparison
    var isCompleted: Bool {
        guard let endDate = endDate else { return false }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endDay = calendar.startOfDay(for: endDate)
        
        return endDay < today
    }
    
    /// Total amount received from this income source
    var totalReceived: Double {
        payments.filter { $0.status == .received }.reduce(0) { $0 + $1.amount }
    }
    
    /// Upcoming (planned) income payments
    var upcomingPayments: [IncomePayment] {
        payments
            .filter { $0.status == .planned }
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    /// Next expected payment date
    var nextPaymentDate: Date? {
        upcomingPayments.first?.dueDate
    }
}

enum IncomeFrequency: String, CaseIterable, Codable {
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    case oneTime = "oneTime"
}

enum IncomeStatus: String, CaseIterable, Codable {
    case active = "active"
    case ended = "ended"
}

