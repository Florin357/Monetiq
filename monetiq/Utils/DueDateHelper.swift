//
//  DueDateHelper.swift
//  monetiq
//
//  Created by Florin Mihai on 29.12.2025.
//

import Foundation

/// Helper for calendar day-based due date calculations
/// Ensures payments are only overdue after the due day has fully passed (after 23:59)
enum DueDateHelper {
    
    /// Normalize a date to the start of its calendar day (00:00:00)
    /// - Parameter date: The date to normalize
    /// - Returns: The start of the calendar day for the given date
    static func startOfDay(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    
    /// Calculate the number of calendar days between two dates
    /// Uses startOfDay to ensure day-based comparison, not timestamp-based
    /// - Parameters:
    ///   - from: The starting date (typically today)
    ///   - to: The ending date (typically the due date)
    /// - Returns: The number of calendar days between the dates (can be negative if 'to' is in the past)
    static func daysBetween(from: Date, to: Date) -> Int {
        let fromDay = startOfDay(for: from)
        let toDay = startOfDay(for: to)
        
        let components = Calendar.current.dateComponents([.day], from: fromDay, to: toDay)
        return components.day ?? 0
    }
    
    /// Determine the due date status for a payment
    /// - Parameters:
    ///   - dueDate: The payment's due date
    ///   - now: The current date/time (defaults to Date())
    /// - Returns: The status of the payment relative to the current date
    static func status(for dueDate: Date, now: Date = Date()) -> DueDateStatus {
        let days = daysBetween(from: now, to: dueDate)
        
        if days < 0 {
            return .overdue(daysOverdue: abs(days))
        } else if days == 0 {
            return .dueToday
        } else if days == 1 {
            return .dueTomorrow
        } else {
            return .dueInDays(days: days)
        }
    }
    
    /// Check if a payment is overdue based on calendar days
    /// A payment is overdue only if the due day has fully passed (after 23:59)
    /// - Parameters:
    ///   - dueDate: The payment's due date
    ///   - now: The current date/time (defaults to Date())
    /// - Returns: True if the payment is overdue, false otherwise
    static func isOverdue(dueDate: Date, now: Date = Date()) -> Bool {
        let dueDay = startOfDay(for: dueDate)
        let today = startOfDay(for: now)
        
        return dueDay < today
    }
}

/// Represents the due date status of a payment
enum DueDateStatus: Equatable {
    case overdue(daysOverdue: Int)
    case dueToday
    case dueTomorrow
    case dueInDays(days: Int)
    
    /// The number of days until due (negative if overdue)
    var daysUntilDue: Int {
        switch self {
        case .overdue(let days):
            return -days
        case .dueToday:
            return 0
        case .dueTomorrow:
            return 1
        case .dueInDays(let days):
            return days
        }
    }
}

