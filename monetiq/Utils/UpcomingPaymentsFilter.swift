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
/// 2. App icon badge count
///
/// Business Rule: A payment is "upcoming" if it's due within the next 15 days.
/// This is INDEPENDENT of notification settings.
///
/// Notifications are scheduled separately based on user preferences:
/// - Notification A: X days before due (where X = user setting, 0-7)
/// - Notification B: Always 1 day before due
struct UpcomingPaymentsFilter {
    
    /// The window for upcoming payments (days from today)
    /// This is the horizon we show in Dashboard and count for badge
    /// BUSINESS RULE: 15 days
    private static let upcomingWindowDays = 15
    
    /// Filter payments to get only "upcoming" ones
    /// 
    /// Logic (SIMPLIFIED - no notification logic):
    /// - payment.status == .planned (not paid)
    /// - payment.dueDate >= today (not overdue)
    /// - payment.dueDate <= today + 15 days (within upcoming window)
    ///
    /// Parameters:
    ///   - payments: All payments to filter
    ///
    /// Returns: Array of upcoming payments, sorted by due date (earliest first)
    static func filterUpcomingPayments(from payments: [Payment]) -> [Payment] {
        let today = Calendar.current.startOfDay(for: Date())
        let calendar = Calendar.current
        
        // Calculate the end of our upcoming window (inclusive)
        guard let upcomingWindowEnd = calendar.date(byAdding: .day, value: upcomingWindowDays, to: today) else {
            return []
        }
        
        return payments.filter { payment in
            // Must be planned (not paid)
            guard payment.status == .planned else { return false }
            
            // Must not be overdue (dueDate >= today)
            let paymentDayStart = calendar.startOfDay(for: payment.dueDate)
            guard paymentDayStart >= today else { return false }
            
            // Must be within 15-day window (dueDate <= today + 15 days)
            return paymentDayStart <= upcomingWindowEnd
        }
        .sorted { $0.dueDate < $1.dueDate }
    }
    
    /// Calculate badge count (same as filtering upcoming payments)
    ///
    /// Parameters:
    ///   - payments: All payments to count
    ///
    /// Returns: Count of upcoming payments (15-day window)
    static func calculateBadgeCount(from payments: [Payment]) -> Int {
        return filterUpcomingPayments(from: payments).count
    }
    
    /// Get the upcoming window in days (for documentation/display purposes)
    static var upcomingWindow: Int {
        return upcomingWindowDays
    }
}

