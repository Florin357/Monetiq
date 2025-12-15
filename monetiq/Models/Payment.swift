//
//  Payment.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import Foundation
import SwiftData

@Model
final class Payment {
    var id: UUID
    var dueDate: Date
    var amount: Double
    var status: PaymentStatus
    var paidDate: Date?
    
    // Snooze metadata (Option 1: snooze reminder only, not actual due date)
    var snoozeUntil: Date?
    
    // Relationship back to loan
    var loan: Loan?
    
    init(
        dueDate: Date,
        amount: Double,
        status: PaymentStatus = .planned,
        paidDate: Date? = nil,
        snoozeUntil: Date? = nil,
        loan: Loan? = nil
    ) {
        self.id = UUID()
        self.dueDate = dueDate
        self.amount = amount
        self.status = status
        self.paidDate = paidDate
        self.snoozeUntil = snoozeUntil
        self.loan = loan
    }
    
    var isOverdue: Bool {
        status == .planned && dueDate < Date()
    }
    
    func markAsPaid() {
        status = .paid
        paidDate = Date()
        snoozeUntil = nil // Clear any snooze when marking as paid
    }
    
    func postponeReminder(by days: Int = 1) {
        let calendar = Calendar.current
        let now = Date()
        snoozeUntil = calendar.date(byAdding: .day, value: days, to: now)
    }
    
    var isReminderSnoozed: Bool {
        guard let snoozeUntil = snoozeUntil else { return false }
        return snoozeUntil > Date()
    }
    
    var effectiveReminderDate: Date {
        if isReminderSnoozed, let snoozeUntil = snoozeUntil {
            return snoozeUntil
        }
        return dueDate
    }
}

enum PaymentStatus: String, CaseIterable, Codable {
    case planned = "planned"
    case paid = "paid"
    case overdue = "overdue"
}
