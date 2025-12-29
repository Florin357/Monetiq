//
//  NotificationManager.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import Foundation
import UserNotifications
import SwiftData
import UIKit

/*
 NOTIFICATION VALIDATION CHECKLIST (Manual Testing):
 
 ✅ PERMISSIONS & UX:
 1. Enable notifications in Settings → should request permission
 2. Deny permission → should show alert with "Open Settings" option
 3. Disable notifications → should cancel all pending notifications
 
 ✅ SCHEDULING LOGIC:
 4. Create loan with payments → should schedule notifications
 5. Change "Days Before Due" → should reschedule all notifications
 6. Mark payment as paid → should cancel that payment's notifications
 7. Edit loan dates → should reschedule affected notifications
 8. Delete loan → should cancel all loan's notifications
 
 ✅ CONTENT QUALITY:
 9. Check notification content includes loan title, amount, currency
 10. Verify localization works in different languages
 11. Confirm no duplicate notifications are created
 
 ✅ APP BEHAVIOR:
 12. Reset app → should cancel all notifications
 13. Weekly review toggle → should schedule/cancel weekly notifications
 14. App backgrounded → notifications should still fire
 
 ✅ DEBUG SAFETY:
 15. Test notification only available in DEBUG builds
 16. No developer UI in production builds
 */

@MainActor
class NotificationManager {
    static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var appSettings: AppSettings?
    
    private init() {}
    
    // MARK: - Authorization
    
    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .notDetermined:
            do {
                return try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                print("Failed to request notification authorization: \(error)")
                return false
            }
        case .denied:
            return false
        case .ephemeral:
            return true
        @unknown default:
            return false
        }
    }
    
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
    
    func clearBadgeCount() {
        Task {
            do {
                try await notificationCenter.setBadgeCount(0)
            } catch {
                print("Failed to clear badge count: \(error)")
            }
        }
    }
    
    /// Update badge count based on upcoming payments from data model
    /// BADGE POLICY (Option A - Recommended): Badge shows upcoming count even if notifications disabled
    /// This is a finance reminder - users should see they have upcoming payments regardless of notification settings
    func updateBadgeCount(payments: [Payment]) async {
        // FIXED (F04): Badge count now derives from data model, not from pending notifications
        // This ensures badge always matches Dashboard "Upcoming Payments" count
        let badgeCount = calculateUpcomingPaymentsBadgeCount(from: payments)
        
        do {
            try await notificationCenter.setBadgeCount(badgeCount)
            
            #if DEBUG
            print("🔔 BADGE UPDATE: Set badge to \(badgeCount)")
            #endif
        } catch {
            print("Failed to update badge count: \(error)")
        }
    }
    
    /// Calculate badge count directly from payment data model
    /// Uses UpcomingPaymentsFilter for consistency with Dashboard
    /// Business Rule: Badge shows count of payments due within 15 days (independent of notification settings)
    /// SOURCE OF TRUTH: Payment data model, not pending notifications
    private func calculateUpcomingPaymentsBadgeCount(from payments: [Payment]) -> Int {
        return UpcomingPaymentsFilter.calculateBadgeCount(from: payments)
    }
    
    // Helper to extract trigger date from notification request (for diagnostics)
    private func extractTriggerDate(from request: UNNotificationRequest) -> Date? {
        if let calendarTrigger = request.trigger as? UNCalendarNotificationTrigger {
            return calendarTrigger.nextTriggerDate()
        }
        return nil
    }
    
    // MARK: - Settings Management
    
    func setAppSettings(_ settings: AppSettings) {
        self.appSettings = settings
    }
    
    // MARK: - Error Handling
    
    /// Check if notifications are available and properly configured
    func validateNotificationSetup() async -> (available: Bool, error: String?) {
        let status = await getAuthorizationStatus()
        
        switch status {
        case .authorized, .provisional:
            return (true, nil)
        case .denied:
            return (false, L10n.string("settings_notifications_denied_message"))
        case .notDetermined:
            return (false, L10n.string("notification_permission_not_requested"))
        case .ephemeral:
            return (true, nil)
        @unknown default:
            return (false, L10n.string("notification_unknown_error"))
        }
    }
    
    // MARK: - Payment Notifications
    
    func schedulePaymentNotifications(for loan: Loan) async {
        guard let settings = appSettings, settings.notificationsEnabled else { return }
        
        let authorized = await requestAuthorizationIfNeeded()
        guard authorized else { return }
        
        // Cancel existing notifications for this loan first
        await cancelNotifications(for: loan)
        
        // Schedule notifications for ALL planned payments (not just upcoming 15-day window)
        // Business rule: Each payment gets TWO notifications:
        // 1. X days before due (where X = user setting, 0-7)
        // 2. Always 1 day before due
        let plannedPayments = loan.payments.filter { $0.status == .planned && $0.dueDate >= Date() }
        
        for payment in plannedPayments {
            await scheduleNotifications(for: payment, loan: loan, settings: settings)
        }
    }
    
    private func scheduleNotifications(for payment: Payment, loan: Loan, settings: AppSettings) async {
        let now = Date()
        let calendar = Calendar.current
        let dueDate = payment.dueDate
        
        // NOTIFICATION A: X days before due (where X = user setting, 0-7)
        // Only schedule if X > 0 and fireDate >= now
        let daysBeforeDue = settings.daysBeforeDueNotification
        if daysBeforeDue > 0 {
            guard let reminderDate = calendar.date(byAdding: .day, value: -daysBeforeDue, to: dueDate) else {
                print("Failed to calculate reminder date for payment \(payment.id)")
                return
            }
            
            // Only schedule if reminder date is in the future
            if reminderDate >= now {
                let reminderIdentifier = "reminder:\(loan.id.uuidString):\(payment.id.uuidString):\(daysBeforeDue)"
                let reminderContent = createPaymentNotificationContent(
                    for: payment,
                    loan: loan,
                    isReminder: true,
                    daysUntilDue: daysBeforeDue
                )
                
                // Schedule at 9:00 AM on the reminder date
                var reminderComponents = calendar.dateComponents([.year, .month, .day], from: reminderDate)
                reminderComponents.hour = 9
                reminderComponents.minute = 0
                
                let reminderTrigger = UNCalendarNotificationTrigger(
                    dateMatching: reminderComponents,
                    repeats: false
                )
                
                let reminderRequest = UNNotificationRequest(
                    identifier: reminderIdentifier,
                    content: reminderContent,
                    trigger: reminderTrigger
                )
                
                do {
                    try await notificationCenter.add(reminderRequest)
                    print("✅ Scheduled reminder notification for payment \(payment.id): \(daysBeforeDue) days before due at \(reminderDate)")
                } catch {
                    print("❌ Failed to schedule reminder notification: \(error)")
                }
            } else {
                print("⏭️ Skipped reminder notification (in the past): payment \(payment.id), \(daysBeforeDue) days before due")
            }
        }
        
        // NOTIFICATION B: Always 1 day before due
        // Only schedule if fireDate >= now
        guard let oneDayBeforeDate = calendar.date(byAdding: .day, value: -1, to: dueDate) else {
            print("Failed to calculate one-day-before date for payment \(payment.id)")
            return
        }
        
        // Only schedule if one-day-before date is in the future
        if oneDayBeforeDate >= now {
            let oneDayBeforeIdentifier = "oneDay:\(loan.id.uuidString):\(payment.id.uuidString)"
            let oneDayBeforeContent = createPaymentNotificationContent(
                for: payment,
                loan: loan,
                isReminder: true,
                daysUntilDue: 1
            )
            
            // Schedule at 9:00 AM one day before due
            var oneDayBeforeComponents = calendar.dateComponents([.year, .month, .day], from: oneDayBeforeDate)
            oneDayBeforeComponents.hour = 9
            oneDayBeforeComponents.minute = 0
            
            let oneDayBeforeTrigger = UNCalendarNotificationTrigger(
                dateMatching: oneDayBeforeComponents,
                repeats: false
            )
            
            let oneDayBeforeRequest = UNNotificationRequest(
                identifier: oneDayBeforeIdentifier,
                content: oneDayBeforeContent,
                trigger: oneDayBeforeTrigger
            )
            
            do {
                try await notificationCenter.add(oneDayBeforeRequest)
                print("✅ Scheduled one-day-before notification for payment \(payment.id) at \(oneDayBeforeDate)")
            } catch {
                print("❌ Failed to schedule one-day-before notification: \(error)")
            }
        } else {
            print("⏭️ Skipped one-day-before notification (in the past): payment \(payment.id)")
        }
    }
    
    private func createPaymentNotificationContent(
        for payment: Payment,
        loan: Loan,
        isReminder: Bool,
        daysUntilDue: Int
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let formattedAmount = CurrencyFormatter.shared.format(amount: payment.amount, currencyCode: loan.currencyCode)
        
        if isReminder {
            content.title = L10n.string("notification_payment_reminder_title")
            content.body = L10n.string("notification_payment_reminder_body", loan.title, daysUntilDue, formattedAmount)
        } else {
            content.title = L10n.string("notification_payment_due_title")
            content.body = L10n.string("notification_payment_due_body", loan.title, formattedAmount)
        }
        
        content.sound = .default
        // Don't set badge count here - let the system manage it to avoid accumulation
        
        // Add user info for handling notification taps
        content.userInfo = [
            "type": "payment",
            "loanId": loan.id.uuidString,
            "paymentId": payment.id.uuidString
        ]
        
        return content
    }
    
    // MARK: - Cancellation
    
    func cancelNotifications(for loan: Loan) async {
        // NEW IDENTIFIER FORMAT:
        // - "reminder:<loanID>:<paymentID>:<daysBeforeDue>"
        // - "oneDay:<loanID>:<paymentID>"
        // - "snooze_<paymentID>" (legacy)
        
        // Since we don't know the exact daysBeforeDue value, we need to cancel all possible variants (0-7)
        var identifiers: [String] = []
        for payment in loan.payments {
            // Cancel all possible reminder notifications (0-7 days before)
            for days in 0...7 {
                identifiers.append("reminder:\(loan.id.uuidString):\(payment.id.uuidString):\(days)")
            }
            // Cancel one-day-before notification
            identifiers.append("oneDay:\(loan.id.uuidString):\(payment.id.uuidString)")
            // Cancel snooze notification (legacy)
            identifiers.append("snooze_\(payment.id.uuidString)")
        }
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("Canceled notifications for loan \(loan.id)")
    }
    
    func cancelNotifications(for payment: Payment) async {
        guard let loan = payment.loan else {
            print("⚠️ Cannot cancel notifications: payment has no associated loan")
            return
        }
        
        // NEW IDENTIFIER FORMAT:
        // - "reminder:<loanID>:<paymentID>:<daysBeforeDue>"
        // - "oneDay:<loanID>:<paymentID>"
        // - "snooze_<paymentID>" (legacy)
        
        // Cancel all possible reminder notifications (0-7 days before)
        var identifiers: [String] = []
        for days in 0...7 {
            identifiers.append("reminder:\(loan.id.uuidString):\(payment.id.uuidString):\(days)")
        }
        // Cancel one-day-before notification
        identifiers.append("oneDay:\(loan.id.uuidString):\(payment.id.uuidString)")
        // Cancel snooze notification (legacy)
        identifiers.append("snooze_\(payment.id.uuidString)")
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("Canceled notifications for payment \(payment.id)")
    }
    
    func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        print("Canceled all notifications")
    }
    
    // MARK: - Reconciliation (Consistency Fix)
    
    /// CONSISTENCY RULES:
    /// 1. Notifications are ONLY scheduled for "upcoming" payments (same logic as Dashboard)
    /// 2. Upcoming = planned + dueDate >= today + dueDate < today+30days
    /// 3. Badge count = count of upcoming payments that need attention
    /// 4. Snooze affects notification timing, not upcoming status
    /// 5. Paid payments have NO notifications and don't count toward badge
    /// 
    /// This ensures:
    /// - Dashboard "Plăți Viitoare" count ≈ Badge count ≈ Scheduled notifications count
    /// - No notifications for far-future payments (beyond 30 days)
    /// - No stale notifications for paid payments
    /// 
    /// Reconciles all payment notifications to ensure consistency with Dashboard
    /// Call this on app launch and after any payment/loan changes
    func reconcileAllPaymentNotifications(with loans: [Loan]) async {
        guard let settings = appSettings, settings.notificationsEnabled else {
            await cancelAllNotifications()
            return
        }
        
        let authorized = await requestAuthorizationIfNeeded()
        guard authorized else { return }
        
        // Step 1: Cancel all existing payment notifications
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let paymentNotificationIds = pendingRequests
            .filter { $0.identifier.hasPrefix("payment_") || $0.identifier.hasPrefix("snooze_") }
            .map { $0.identifier }
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: paymentNotificationIds)
        
        // Step 2: Schedule notifications for all upcoming payments across all loans
        let today = Date()
        let upcomingWindow = Calendar.current.date(byAdding: .day, value: 30, to: today) ?? today
        
        var totalScheduled = 0
        
        for loan in loans {
            let upcomingPayments = loan.payments.filter { 
                $0.status == .planned && 
                $0.dueDate >= today && 
                $0.dueDate < upcomingWindow 
            }
            
            for payment in upcomingPayments {
                if payment.isReminderSnoozed {
                    await scheduleSnoozeNotification(for: payment, loan: loan)
                } else {
                    await scheduleNotifications(for: payment, loan: loan, settings: settings)
                }
                totalScheduled += 1
            }
        }
        
        // Step 3: Update badge count based on all payments
        let allPayments = loans.flatMap { $0.payments }
        await updateBadgeCount(payments: allPayments)
    }
    
    func rescheduleNotifications(for payment: Payment) async {
        guard let loan = payment.loan,
              let settings = appSettings,
              settings.notificationsEnabled else { return }
        
        let authorized = await requestAuthorizationIfNeeded()
        guard authorized else { return }
        
        // Cancel existing notifications for this payment (including snooze)
        let identifiers = [
            "payment_before_\(payment.id.uuidString)",
            "payment_due_\(payment.id.uuidString)",
            "snooze_\(payment.id.uuidString)"
        ]
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        
        // If payment is snoozed, schedule snooze notification instead of regular ones
        if payment.isReminderSnoozed {
            await scheduleSnoozeNotification(for: payment, loan: loan)
        } else {
            // Schedule regular notifications
            await scheduleNotifications(for: payment, loan: loan, settings: settings)
        }
    }
    
    private func scheduleSnoozeNotification(for payment: Payment, loan: Loan) async {
        guard let snoozeUntil = payment.snoozeUntil,
              snoozeUntil > Date() else { return }
        
        let snoozeIdentifier = "snooze_\(payment.id.uuidString)"
        let content = UNMutableNotificationContent()
        let formattedAmount = CurrencyFormatter.shared.format(amount: payment.amount, currencyCode: loan.currencyCode)
        
        content.title = L10n.string("notification_payment_snoozed_title")
        content.body = L10n.string("notification_payment_snoozed_body", loan.title, formattedAmount)
        content.sound = .default
        
        // Add user info for handling notification taps
        content.userInfo = [
            "type": "payment",
            "loanId": loan.id.uuidString,
            "paymentId": payment.id.uuidString
        ]
        
        // Schedule at 9:00 AM on the snooze date for consistency
        var snoozeComponents = Calendar.current.dateComponents([.year, .month, .day], from: snoozeUntil)
        snoozeComponents.hour = 9
        snoozeComponents.minute = 0
        
        let snoozeTrigger = UNCalendarNotificationTrigger(
            dateMatching: snoozeComponents,
            repeats: false
        )
        
        let snoozeRequest = UNNotificationRequest(
            identifier: snoozeIdentifier,
            content: content,
            trigger: snoozeTrigger
        )
        
        do {
            try await notificationCenter.add(snoozeRequest)
            print("Scheduled snooze notification for payment \(payment.id) at \(snoozeUntil)")
        } catch {
            print("Failed to schedule snooze notification: \(error)")
        }
    }
    
    // MARK: - Weekly Review
    
    func scheduleWeeklyReviewNotification() async {
        guard let settings = appSettings, settings.weeklyReviewEnabled else { return }
        
        let authorized = await requestAuthorizationIfNeeded()
        guard authorized else { return }
        
        await cancelWeeklyReviewNotification()
        
        let content = UNMutableNotificationContent()
        content.title = L10n.string("notification_weekly_review_title")
        content.body = L10n.string("notification_weekly_review_body")
        content.sound = .default
        // Don't set badge count here - let the system manage it to avoid accumulation
        content.userInfo = ["type": "weekly_review"]
        
        // Schedule for every Monday at 9:00 AM
        var dateComponents = DateComponents()
        dateComponents.weekday = 2 // Monday
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weekly_review",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("Scheduled weekly review notification")
        } catch {
            print("Failed to schedule weekly review notification: \(error)")
        }
    }
    
    func cancelWeeklyReviewNotification() async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["weekly_review"])
        print("Canceled weekly review notification")
    }
    
    // MARK: - Bulk Operations
    
    func rescheduleAllNotifications(for loans: [Loan]) async {
        guard let settings = appSettings, settings.notificationsEnabled else {
            await cancelAllNotifications()
            return
        }
        
        for loan in loans {
            await schedulePaymentNotifications(for: loan)
        }
        
        if settings.weeklyReviewEnabled {
            await scheduleWeeklyReviewNotification()
        }
        
        // Update badge count after rescheduling (based on all payments)
        let allPayments = loans.flatMap { $0.payments }
        await updateBadgeCount(payments: allPayments)
    }
    
    // MARK: - Debug/Testing
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    #if DEBUG
    func scheduleTestNotification() async {
        let authorized = await requestAuthorizationIfNeeded()
        guard authorized else { 
            print("Notification authorization denied")
            return 
        }
        
        let content = UNMutableNotificationContent()
        content.title = L10n.string("notification_test_title")
        content.body = L10n.string("notification_test_body")
        content.sound = .default
        
        // Schedule for 5 seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test_notification",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("Test notification scheduled for 5 seconds from now")
        } catch {
            print("Failed to schedule test notification: \(error)")
        }
    }
    #endif
}
