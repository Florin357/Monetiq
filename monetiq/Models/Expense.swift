//
//  Expense.swift
//  monetiq
//
//  Created by AI Assistant on 26.01.2026.
//

import Foundation
import SwiftData

@Model
final class Expense {
    var id: UUID
    var title: String
    var amount: Double
    var currencyCode: String
    var frequency: ExpenseFrequency
    var startDate: Date
    var endDate: Date?
    var notes: String?
    var category: String?
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \ExpenseOccurrence.expense)
    var occurrences: [ExpenseOccurrence] = []
    
    init(
        title: String,
        amount: Double,
        currencyCode: String = "RON",
        frequency: ExpenseFrequency = .monthly,
        startDate: Date = Date(),
        endDate: Date? = nil,
        notes: String? = nil,
        category: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.amount = amount
        self.currencyCode = currencyCode
        self.frequency = frequency
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.category = category
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func updateTimestamp() {
        self.updatedAt = Date()
    }
    
    /// Check if expense is completed (ended)
    /// Uses timezone-safe date comparison
    var isCompleted: Bool {
        guard let endDate = endDate else {
            // One-time expenses without occurrences or all occurrences paid
            if frequency == .oneTime {
                return occurrences.allSatisfy { $0.status == .paid }
            }
            return false
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endDay = calendar.startOfDay(for: endDate)
        
        return endDay < today
    }
    
    /// Check if expense is overdue (has a past due date)
    var isOverdue: Bool {
        guard !isArchived, let nextDue = nextDueDate else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.startOfDay(for: nextDue) < today
    }
    
    /// Check if expense should be archived (no future occurrences)
    var isArchived: Bool {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        
        // For one-time: archived if date's MONTH has passed (not just the day)
        if frequency == .oneTime {
            let expenseMonth = calendar.dateComponents([.year, .month], from: startDate)
            let currentMonth = calendar.dateComponents([.year, .month], from: startOfToday)
            
            // If expense is from a past month, it's archived
            if let expenseDate = calendar.date(from: expenseMonth),
               let currentDate = calendar.date(from: currentMonth) {
                return expenseDate < currentDate
            }
        }
        
        // For recurring: archived if no planned occurrences >= today
        let hasFutureOccurrences = occurrences.contains { occurrence in
            occurrence.status == .planned &&
            calendar.startOfDay(for: occurrence.dueDate) >= startOfToday
        }
        
        if hasFutureOccurrences {
            return false
        }
        
        // For recurring: archived if endDate exists and < today
        if let endDate = endDate {
            return calendar.startOfDay(for: endDate) < startOfToday
        }
        
        return false
    }
    
    /// Get archive month/year label for grouping
    var archiveGroupLabel: String? {
        guard isArchived else { return nil }
        
        let relevantDate = endDate ?? startDate
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy" // e.g., "January 2026"
        return formatter.string(from: relevantDate)
    }
    
    /// Total amount paid for this expense
    var totalPaid: Double {
        occurrences.filter { $0.status == .paid }.reduce(0) { $0 + $1.amount }
    }
    
    /// Upcoming (planned) expense occurrences
    var upcomingOccurrences: [ExpenseOccurrence] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        
        return occurrences
            .filter { $0.status == .planned && $0.dueDate >= startOfToday }
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    /// Next expected payment date
    var nextDueDate: Date? {
        upcomingOccurrences.first?.dueDate
    }
    
    /// Count of paid occurrences (for recurring subscriptions)
    var paidOccurrencesCount: Int {
        occurrences.filter { $0.status == .paid }.count
    }
    
    /// Time-based subscription age label (how long user has been subscribed)
    var subscriptionAgeLabel: String? {
        guard frequency != .oneTime else { return nil }
        
        let calendar = Calendar.current
        let today = Date()
        
        // If startDate is in the future, show "Starts in X days"
        if startDate > today {
            let days = calendar.dateComponents([.day], from: today, to: startDate).day ?? 0
            return L10n.string("expenses_starts_in_days", days)
        }
        
        // Calculate elapsed periods from startDate to today
        switch frequency {
        case .monthly:
            let months = calendar.dateComponents([.month], from: startDate, to: today).month ?? 0
            let adjusted = max(1, months + 1)
            if adjusted >= 24 {
                let years = adjusted / 12
                return L10n.string("expenses_subscribed_years", years)
            }
            return L10n.string("expenses_subscribed_months", adjusted)
        case .yearly:
            let years = calendar.dateComponents([.year], from: startDate, to: today).year ?? 0
            return L10n.string("expenses_subscribed_years", max(1, years + 1))
        case .weekly:
            let weeks = calendar.dateComponents([.weekOfYear], from: startDate, to: today).weekOfYear ?? 0
            return L10n.string("expenses_subscribed_weeks", max(1, weeks + 1))
        case .quarterly:
            let months = calendar.dateComponents([.month], from: startDate, to: today).month ?? 0
            let quarters = max(1, (months / 3) + 1)
            return L10n.string("expenses_subscribed_quarters", quarters)
        case .oneTime:
            return nil
        }
    }
}

enum ExpenseFrequency: String, CaseIterable, Codable {
    case oneTime = "oneTime"
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    
    var localizedLabel: String {
        switch self {
        case .oneTime:
            return L10n.string("frequency_onetime")
        case .weekly:
            return L10n.string("frequency_weekly")
        case .monthly:
            return L10n.string("frequency_monthly")
        case .quarterly:
            return L10n.string("frequency_quarterly")
        case .yearly:
            return L10n.string("frequency_yearly")
        }
    }
}

