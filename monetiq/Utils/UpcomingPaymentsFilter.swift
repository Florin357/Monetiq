//
//  UpcomingPaymentsFilter.swift
//  monetiq
//
//  Created by AI Assistant on 20.12.2025.
//

import Foundation

/// SINGLE SOURCE OF TRUTH for "Upcoming Payments" logic
/// Used consistently across:
/// 1. Dashboard "Upcoming Payments" list
/// 2. Notification scheduling
/// 3. App icon badge count
///
/// Definition: A payment is "upcoming" if its earliest notification will fire within the next 30 days.
/// This ensures Dashboard, notifications, and badge count are always synchronized.
struct UpcomingPaymentsFilter {
    
    /// The window for upcoming payments (days from today)
    /// This is the horizon we show in Dashboard and count for badge
    private static let upcomingWindowDays = 30
    
    /// Filter payments to get only "upcoming" ones
    /// 
    /// Logic:
    /// - payment.status == .planned (not paid)
    /// - payment is not overdue (dueDate >= today)
    /// - earliest notification fire date < today + 30 days
    ///
    /// The "earliest notification fire date" is:
    /// - (dueDate - daysBeforeDue) if that's in the future
    /// - dueDate if daysBeforeDue pushes it into the past
    ///
    /// Parameters:
    ///   - payments: All payments to filter
    ///   - daysBeforeDue: The "Days Before Due" setting from AppSettings
    ///
    /// Returns: Array of upcoming payments, sorted by due date (earliest first)
    static func filterUpcomingPayments(
        from payments: [Payment],
        daysBeforeDue: Int
    ) -> [Payment] {
        let today = Date()
        let calendar = Calendar.current
        
        // Calculate the end of our upcoming window
        let upcomingWindowEnd = calendar.date(byAdding: .day, value: upcomingWindowDays, to: today) ?? today
        
        return payments.filter { payment in
            // Must be planned (not paid)
            guard payment.status == .planned else { return false }
            
            // Must not be overdue
            guard payment.dueDate >= today else { return false }
            
            // Calculate when the earliest notification would fire
            // This is either (dueDate - daysBeforeDue) or dueDate, whichever is later than today
            let daysBeforeInterval = TimeInterval(daysBeforeDue * 24 * 60 * 60)
            let earliestNotificationDate = payment.dueDate.addingTimeInterval(-daysBeforeInterval)
            
            // Use the later of (earliestNotificationDate, today) to handle edge cases
            // where daysBeforeDue would push notification into the past
            let effectiveNotificationDate = max(earliestNotificationDate, today)
            
            // Include this payment if its earliest notification fires within our window
            return effectiveNotificationDate < upcomingWindowEnd
        }
        .sorted { $0.dueDate < $1.dueDate }
    }
    
    /// Calculate badge count (same as filtering upcoming payments)
    ///
    /// Parameters:
    ///   - payments: All payments to count
    ///   - daysBeforeDue: The "Days Before Due" setting from AppSettings
    ///
    /// Returns: Count of upcoming payments
    static func calculateBadgeCount(
        from payments: [Payment],
        daysBeforeDue: Int
    ) -> Int {
        return filterUpcomingPayments(from: payments, daysBeforeDue: daysBeforeDue).count
    }
    
    /// Get the upcoming window in days (for documentation/display purposes)
    static var upcomingWindow: Int {
        return upcomingWindowDays
    }
}

