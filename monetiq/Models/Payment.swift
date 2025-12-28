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
