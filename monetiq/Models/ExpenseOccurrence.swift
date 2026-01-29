//
//  ExpenseOccurrence.swift
//  monetiq
//
//  Created by AI Assistant on 26.01.2026.
//

import Foundation
import SwiftData

@Model
final class ExpenseOccurrence {
    var id: UUID
    var dueDate: Date
    var amount: Double
    var status: ExpenseStatus
    var paidDate: Date?
    var createdAt: Date
    
    var expense: Expense?
    
    init(
        dueDate: Date,
        amount: Double,
        status: ExpenseStatus = .planned,
        paidDate: Date? = nil,
        expense: Expense? = nil
    ) {
        self.id = UUID()
        self.dueDate = dueDate
        self.amount = amount
        self.status = status
        self.paidDate = paidDate
        self.expense = expense
        self.createdAt = Date()
    }
    
    /// Check if this occurrence is overdue
    var isOverdue: Bool {
        guard status == .planned else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let due = calendar.startOfDay(for: dueDate)
        return due < today
    }
    
    /// Check if due today
    var isDueToday: Bool {
        guard status == .planned else { return false }
        let calendar = Calendar.current
        return calendar.isDateInToday(dueDate)
    }
    
    /// Check if due tomorrow
    var isDueTomorrow: Bool {
        guard status == .planned else { return false }
        let calendar = Calendar.current
        return calendar.isDateInTomorrow(dueDate)
    }
}

enum ExpenseStatus: String, CaseIterable, Codable {
    case planned = "planned"
    case paid = "paid"
    
    var localizedLabel: String {
        switch self {
        case .planned:
            return L10n.string("status_planned")
        case .paid:
            return L10n.string("status_paid")
        }
    }
}

