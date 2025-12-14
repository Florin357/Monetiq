//
//  NotificationManager.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import Foundation
import UserNotifications
import SwiftData

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
        Task { @MainActor in
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    // MARK: - Settings Management
    
    func setAppSettings(_ settings: AppSettings) {
        self.appSettings = settings
    }
    
    // MARK: - Payment Notifications
    
    func schedulePaymentNotifications(for loan: Loan) async {
        guard let settings = appSettings, settings.notificationsEnabled else { return }
        
        let authorized = await requestAuthorizationIfNeeded()
        guard authorized else { return }
        
        // Cancel existing notifications for this loan first
        await cancelNotifications(for: loan)
        
        let plannedPayments = loan.payments.filter { $0.status == .planned }
        
        for payment in plannedPayments {
            await scheduleNotifications(for: payment, loan: loan, settings: settings)
        }
    }
    
    private func scheduleNotifications(for payment: Payment, loan: Loan, settings: AppSettings) async {
        let now = Date()
        let dueDate = payment.dueDate
        
        // Schedule notification X days before due date
        let daysBeforeInterval = TimeInterval(settings.daysBeforeDueNotification * 24 * 60 * 60)
        let beforeDueDate = dueDate.addingTimeInterval(-daysBeforeInterval)
        
        if beforeDueDate > now {
            let beforeDueIdentifier = "payment_before_\(payment.id.uuidString)"
            let beforeDueContent = createPaymentNotificationContent(
                for: payment,
                loan: loan,
                isReminder: true,
                daysUntilDue: settings.daysBeforeDueNotification
            )
            
            let beforeDueTrigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: beforeDueDate),
                repeats: false
            )
            
            let beforeDueRequest = UNNotificationRequest(
                identifier: beforeDueIdentifier,
                content: beforeDueContent,
                trigger: beforeDueTrigger
            )
            
            do {
                try await notificationCenter.add(beforeDueRequest)
                print("Scheduled before-due notification for payment \(payment.id) at \(beforeDueDate)")
            } catch {
                print("Failed to schedule before-due notification: \(error)")
            }
        }
        
        // Schedule notification on due date
        if dueDate > now {
            let dueDateIdentifier = "payment_due_\(payment.id.uuidString)"
            let dueDateContent = createPaymentNotificationContent(
                for: payment,
                loan: loan,
                isReminder: false,
                daysUntilDue: 0
            )
            
            let dueDateTrigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate),
                repeats: false
            )
            
            let dueDateRequest = UNNotificationRequest(
                identifier: dueDateIdentifier,
                content: dueDateContent,
                trigger: dueDateTrigger
            )
            
            do {
                try await notificationCenter.add(dueDateRequest)
                print("Scheduled due-date notification for payment \(payment.id) at \(dueDate)")
            } catch {
                print("Failed to schedule due-date notification: \(error)")
            }
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
        content.badge = 1
        
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
        let identifiers = loan.payments.flatMap { payment in
            [
                "payment_before_\(payment.id.uuidString)",
                "payment_due_\(payment.id.uuidString)"
            ]
        }
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("Canceled notifications for loan \(loan.id)")
    }
    
    func cancelNotifications(for payment: Payment) async {
        let identifiers = [
            "payment_before_\(payment.id.uuidString)",
            "payment_due_\(payment.id.uuidString)"
        ]
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("Canceled notifications for payment \(payment.id)")
    }
    
    func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        print("Canceled all notifications")
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
        content.badge = 1
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
