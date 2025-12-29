//
//  IncomePayment.swift
//  monetiq
//
//  Created by Florin Mihai on 28.12.2025.
//

import Foundation
import SwiftData

@Model
final class IncomePayment {
    var id: UUID
    var dueDate: Date
    var amount: Double
    var currencyCode: String
    var status: IncomePaymentStatus
    var receivedDate: Date?
    var createdAt: Date
    var updatedAt: Date
    
    // Relationship back to income source
    var incomeSource: IncomeSource?
    
    init(
        dueDate: Date,
        amount: Double,
        currencyCode: String,
        status: IncomePaymentStatus = .planned,
        receivedDate: Date? = nil,
        incomeSource: IncomeSource? = nil
    ) {
        self.id = UUID()
        self.dueDate = dueDate
        self.amount = amount
        self.currencyCode = currencyCode
        self.status = status
        self.receivedDate = receivedDate
        self.incomeSource = incomeSource
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func updateTimestamp() {
        self.updatedAt = Date()
    }
    
    /// Mark this payment as received
    func markAsReceived() {
        status = .received
        receivedDate = Date()
        updateTimestamp()
    }
    
    /// Check if this payment is overdue (planned but past due date)
    /// Overdue only AFTER the due day ends (starting at 00:00 next day)
    var isOverdue: Bool {
        guard status == .planned else { return false }
        
        // Calculate the deadline: start of the day AFTER the due date
        // This ensures payments due TODAY are not overdue until tomorrow at 00:00
        let calendar = Calendar.current
        guard let startOfDueDay = calendar.startOfDay(for: dueDate) as Date?,
              let deadline = calendar.date(byAdding: .day, value: 1, to: startOfDueDay) else {
            return false // Fallback: not overdue if date calculation fails
        }
        
        // Overdue only if current time is past the deadline (start of next day)
        return Date() >= deadline
    }
}

enum IncomePaymentStatus: String, CaseIterable, Codable {
    case planned = "planned"
    case received = "received"
}

