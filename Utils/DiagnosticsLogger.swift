//
//  DiagnosticsLogger.swift
//  monetiq
//
//  Created for debugging finance logic and notifications consistency.
//  DEBUG ONLY - Not included in production builds.
//

#if DEBUG
import Foundation
import SwiftData
import UserNotifications

/// Lightweight diagnostics tool for developers to inspect app state
/// Usage: Call DiagnosticsLogger.shared.logFinanceState() or logNotificationState()
@MainActor
class DiagnosticsLogger {
    static let shared = DiagnosticsLogger()
    
    private init() {}
    
    // MARK: - Log Categories
    
    private enum LogCategory: String {
        case finance = "💰 FINANCE"
        case notifications = "🔔 NOTIFICATIONS"
        case dataIntegrity = "🗂️  DATA"
        case calculations = "📐 CALC"
    }
    
    private func log(_ category: LogCategory, _ message: String) {
        print("[\(category.rawValue)] \(message)")
    }
    
    // MARK: - Finance State Diagnostics
    
    /// Log comprehensive finance state for debugging
    /// Call this to inspect upcoming payments, badge count, and data consistency
    func logFinanceState(loans: [Loan], payments: [Payment]) {
        log(.finance, "=== FINANCE STATE SNAPSHOT ===")
        
        // Upcoming payments calculation (matches Dashboard logic)
        let today = Date()
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: today) ?? today
        
        let allPlannedPayments = payments.filter { $0.status == .planned }
        let upcomingPayments = allPlannedPayments.filter { 
            $0.dueDate >= today && 
            $0.dueDate < thirtyDaysFromNow 
        }
        
        log(.finance, "Total Loans: \(loans.count)")
        log(.finance, "Total Payments: \(payments.count)")
        log(.finance, "Planned Payments: \(allPlannedPayments.count)")
        log(.finance, "Upcoming Payments (30-day window): \(upcomingPayments.count)")
        log(.finance, "Paid Payments: \(payments.filter { $0.status == .paid }.count)")
        
        // Per-loan breakdown
        for loan in loans {
            let loanPlanned = loan.payments.filter { $0.status == .planned }.count
            let loanPaid = loan.payments.filter { $0.status == .paid }.count
            let loanUpcoming = loan.payments.filter { payment in
                payment.status == .planned &&
                payment.dueDate >= today &&
                payment.dueDate < thirtyDaysFromNow
            }.count
            
            log(.finance, "  Loan: '\(loan.title)' | Total: \(loan.payments.count) | Planned: \(loanPlanned) | Paid: \(loanPaid) | Upcoming: \(loanUpcoming)")
        }
        
        log(.finance, "=== END FINANCE STATE ===\n")
    }
    
    // MARK: - Notification State Diagnostics
    
    /// Log notification state and compare with expected upcoming payments
    func logNotificationState() async {
        log(.notifications, "=== NOTIFICATION STATE SNAPSHOT ===")
        
        let center = UNUserNotificationCenter.current()
        
        // Check authorization
        let settings = await center.notificationSettings()
        log(.notifications, "Authorization Status: \(authStatusString(settings.authorizationStatus))")
        log(.notifications, "Badge Setting: \(settings.badgeSetting == .enabled ? "✅ Enabled" : "❌ Disabled")")
        log(.notifications, "Alert Setting: \(settings.alertSetting == .enabled ? "✅ Enabled" : "❌ Disabled")")
        
        // Get pending notifications
        let pendingRequests = await center.pendingNotificationRequests()
        log(.notifications, "Total Pending Notifications: \(pendingRequests.count)")
        
        // Categorize notifications
        let paymentNotifications = pendingRequests.filter { 
            $0.identifier.hasPrefix("payment_") 
        }
        let snoozeNotifications = pendingRequests.filter { 
            $0.identifier.hasPrefix("snooze_") 
        }
        let weeklyReview = pendingRequests.filter { 
            $0.identifier == "weekly_review" 
        }
        
        log(.notifications, "  Payment Notifications: \(paymentNotifications.count)")
        log(.notifications, "  Snooze Notifications: \(snoozeNotifications.count)")
        log(.notifications, "  Weekly Review: \(weeklyReview.count)")
        
        // Detailed breakdown
        let today = Date()
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: today) ?? today
        
        var upcomingCount = 0
        var futureCount = 0
        var pastCount = 0
        
        for request in paymentNotifications {
            if let triggerDate = extractTriggerDate(from: request) {
                if triggerDate < today {
                    pastCount += 1
                } else if triggerDate < thirtyDaysFromNow {
                    upcomingCount += 1
                } else {
                    futureCount += 1
                }
            }
        }
        
        log(.notifications, "  Within 30 days: \(upcomingCount)")
        log(.notifications, "  Beyond 30 days: \(futureCount)")
        log(.notifications, "  Past due: \(pastCount) ⚠️")
        
        // Badge count
        let badgeCount = await center.getBadgeCount()
        log(.notifications, "Current Badge Count: \(badgeCount)")
        
        log(.notifications, "=== END NOTIFICATION STATE ===\n")
    }
    
    // MARK: - Consistency Check
    
    /// Compare upcoming payments count vs notification count
    /// Useful for detecting badge/notification inconsistencies (F04 from audit)
    func logConsistencyCheck(loans: [Loan]) async {
        log(.dataIntegrity, "=== CONSISTENCY CHECK ===")
        
        // Calculate upcoming payments from data model
        let today = Date()
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: today) ?? today
        
        var upcomingPaymentsFromModel = 0
        for loan in loans {
            let upcoming = loan.payments.filter { payment in
                payment.status == .planned &&
                payment.dueDate >= today &&
                payment.dueDate < thirtyDaysFromNow
            }
            upcomingPaymentsFromModel += upcoming.count
        }
        
        // Get scheduled notifications count
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()
        let upcomingNotifications = pendingRequests.filter { request in
            guard request.identifier.hasPrefix("payment_") else { return false }
            if let triggerDate = extractTriggerDate(from: request) {
                return triggerDate >= today && triggerDate < thirtyDaysFromNow
            }
            return false
        }
        
        let badgeCount = await center.getBadgeCount()
        
        log(.dataIntegrity, "Data Model Upcoming Payments: \(upcomingPaymentsFromModel)")
        log(.dataIntegrity, "Scheduled Notifications (30d): \(upcomingNotifications.count)")
        log(.dataIntegrity, "Badge Count: \(badgeCount)")
        
        // Consistency validation
        let consistent = (upcomingPaymentsFromModel == upcomingNotifications.count)
        if consistent {
            log(.dataIntegrity, "✅ CONSISTENT - All counts match")
        } else {
            log(.dataIntegrity, "⚠️  INCONSISTENT - Counts do not match!")
            log(.dataIntegrity, "   Difference: \(abs(upcomingPaymentsFromModel - upcomingNotifications.count))")
        }
        
        log(.dataIntegrity, "=== END CONSISTENCY CHECK ===\n")
    }
    
    // MARK: - Calculation Diagnostics
    
    /// Log detailed calculation breakdown for a specific loan
    /// Useful for debugging formula issues (F01 from audit)
    func logCalculationDetails(loan: Loan) {
        log(.calculations, "=== CALCULATION DETAILS ===")
        log(.calculations, "Loan: '\(loan.title)'")
        log(.calculations, "Principal: \(loan.principalAmount) \(loan.currencyCode)")
        log(.calculations, "Interest Mode: \(loan.interestMode.rawValue)")
        log(.calculations, "Frequency: \(loan.frequency.rawValue)")
        log(.calculations, "Number of Periods: \(loan.numberOfPeriods)")
        
        if let rate = loan.annualInterestRate {
            log(.calculations, "Annual Interest Rate: \(rate)%")
        }
        if let fixed = loan.fixedTotalToRepay {
            log(.calculations, "Fixed Total: \(fixed) \(loan.currencyCode)")
        }
        
        log(.calculations, "Calculated Total To Repay: \(loan.totalToRepay ?? 0) \(loan.currencyCode)")
        log(.calculations, "Calculated Periodic Payment: \(loan.periodicPaymentAmount ?? 0) \(loan.currencyCode)")
        
        // Schedule validation
        let scheduleSum = loan.payments.reduce(0.0) { $0 + $1.amount }
        let paidSum = loan.totalPaid
        let remaining = loan.remainingToPay
        
        log(.calculations, "Schedule Sum: \(scheduleSum) \(loan.currencyCode)")
        log(.calculations, "Total Paid: \(paidSum) \(loan.currencyCode)")
        log(.calculations, "Remaining: \(remaining) \(loan.currencyCode)")
        
        // Validation
        let expectedTotal = loan.totalToRepay ?? loan.principalAmount
        let scheduleMatchesTotal = abs(scheduleSum - expectedTotal) < 0.02 // 2 cent tolerance
        
        if scheduleMatchesTotal {
            log(.calculations, "✅ Schedule sum matches total (±0.02 tolerance)")
        } else {
            log(.calculations, "⚠️  Schedule sum MISMATCH!")
            log(.calculations, "   Difference: \(scheduleSum - expectedTotal) \(loan.currencyCode)")
        }
        
        log(.calculations, "=== END CALCULATION DETAILS ===\n")
    }
    
    // MARK: - Helper Methods
    
    private func authStatusString(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "✅ Authorized"
        case .denied: return "❌ Denied"
        case .notDetermined: return "❓ Not Determined"
        case .provisional: return "⚠️  Provisional"
        case .ephemeral: return "⏱️  Ephemeral"
        @unknown default: return "❓ Unknown"
        }
    }
    
    private func extractTriggerDate(from request: UNNotificationRequest) -> Date? {
        if let calendarTrigger = request.trigger as? UNCalendarNotificationTrigger {
            return calendarTrigger.nextTriggerDate()
        }
        return nil
    }
}

// MARK: - UNUserNotificationCenter Extension

extension UNUserNotificationCenter {
    /// Get current badge count (iOS 16+)
    @MainActor
    func getBadgeCount() async -> Int {
        // Try to get from app icon badge
        if #available(iOS 16.0, *) {
            do {
                return try await self.badgeCount()
            } catch {
                return 0
            }
        } else {
            // Fallback for older iOS
            return UIApplication.shared.applicationIconBadgeNumber
        }
    }
}

#endif

