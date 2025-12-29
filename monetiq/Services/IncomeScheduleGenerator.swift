//
//  IncomeScheduleGenerator.swift
//  monetiq
//
//  Created by Florin Mihai on 28.12.2025.
//

import Foundation
import SwiftData

/// Service responsible for generating and managing income payment schedules
/// Mirrors the pattern used in LoanCalculator for consistency
class IncomeScheduleGenerator {
    
    /// Rolling window for generating future income payments (in months)
    /// This ensures we always have upcoming payments visible
    private static let rollingWindowMonths = 12
    
    // MARK: - Public API
    
    /// Generate initial schedule for a new income source
    /// - Parameters:
    ///   - incomeSource: The income source to generate schedule for
    ///   - modelContext: SwiftData context for persistence
    /// - Returns: Array of generated IncomePayment objects
    @discardableResult
    static func generateInitialSchedule(
        for incomeSource: IncomeSource,
        in modelContext: ModelContext
    ) -> [IncomePayment] {
        #if DEBUG
        print("📅 IncomeScheduleGenerator: Generating initial schedule for '\(incomeSource.title)'")
        #endif
        
        // Clear any existing payments (should be empty for new income, but defensive)
        incomeSource.payments.removeAll()
        
        // Generate schedule items
        let scheduleItems = generateScheduleItems(for: incomeSource)
        
        // Create IncomePayment objects and link to income source
        var payments: [IncomePayment] = []
        for item in scheduleItems {
            let payment = IncomePayment(
                dueDate: item.dueDate,
                amount: item.amount,
                currencyCode: incomeSource.currencyCode,
                status: .planned,
                incomeSource: incomeSource
            )
            modelContext.insert(payment)
            payments.append(payment)
        }
        
        incomeSource.payments = payments
        incomeSource.updateTimestamp()
        
        #if DEBUG
        print("✅ Generated \(payments.count) income payments")
        #endif
        
        return payments
    }
    
    /// Refresh schedule for an existing income source
    /// Preserves received payments, regenerates planned payments
    /// - Parameters:
    ///   - incomeSource: The income source to refresh schedule for
    ///   - modelContext: SwiftData context for persistence
    /// - Returns: Array of newly generated IncomePayment objects
    @discardableResult
    static func refreshSchedule(
        for incomeSource: IncomeSource,
        in modelContext: ModelContext
    ) -> [IncomePayment] {
        #if DEBUG
        print("🔄 IncomeScheduleGenerator: Refreshing schedule for '\(incomeSource.title)'")
        #endif
        
        // CRITICAL: Preserve received payments (do NOT delete history)
        let receivedPayments = incomeSource.payments.filter { $0.status == .received }
        
        #if DEBUG
        print("   Preserving \(receivedPayments.count) received payments")
        #endif
        
        // Remove only planned payments
        let plannedPayments = incomeSource.payments.filter { $0.status == .planned }
        for payment in plannedPayments {
            modelContext.delete(payment)
        }
        
        // Generate new schedule items
        let scheduleItems = generateScheduleItems(for: incomeSource)
        
        // Create new IncomePayment objects for planned payments
        var newPayments: [IncomePayment] = []
        for item in scheduleItems {
            // Check if this date already has a received payment (avoid duplicates)
            let alreadyReceived = receivedPayments.contains { payment in
                Calendar.current.isDate(payment.dueDate, inSameDayAs: item.dueDate)
            }
            
            if !alreadyReceived {
                let payment = IncomePayment(
                    dueDate: item.dueDate,
                    amount: item.amount,
                    currencyCode: incomeSource.currencyCode,
                    status: .planned,
                    incomeSource: incomeSource
                )
                modelContext.insert(payment)
                newPayments.append(payment)
            }
        }
        
        // Update income source payments (received + new planned)
        incomeSource.payments = receivedPayments + newPayments
        incomeSource.updateTimestamp()
        
        #if DEBUG
        print("✅ Refreshed schedule: \(receivedPayments.count) received + \(newPayments.count) planned = \(incomeSource.payments.count) total")
        #endif
        
        return newPayments
    }
    
    // MARK: - Private Helpers
    
    /// Generate schedule items (date + amount pairs) for an income source
    /// Does not create SwiftData objects, just calculates the schedule
    private static func generateScheduleItems(for incomeSource: IncomeSource) -> [IncomeScheduleItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Determine schedule end date
        let scheduleEndDate: Date
        if let endDate = incomeSource.endDate {
            // If income has an end date, use it
            scheduleEndDate = endDate
        } else {
            // Otherwise, generate for rolling window (e.g., 12 months ahead)
            scheduleEndDate = calendar.date(byAdding: .month, value: rollingWindowMonths, to: today) ?? today
        }
        
        // Generate based on frequency
        switch incomeSource.frequency {
        case .oneTime:
            return generateOneTimeSchedule(
                incomeSource: incomeSource,
                today: today,
                scheduleEndDate: scheduleEndDate,
                calendar: calendar
            )
            
        case .weekly, .monthly, .quarterly, .yearly:
            return generateRecurringSchedule(
                incomeSource: incomeSource,
                today: today,
                scheduleEndDate: scheduleEndDate,
                calendar: calendar
            )
        }
    }
    
    /// Generate schedule for one-time income
    private static func generateOneTimeSchedule(
        incomeSource: IncomeSource,
        today: Date,
        scheduleEndDate: Date,
        calendar: Calendar
    ) -> [IncomeScheduleItem] {
        // One-time income: single payment on start date
        // Only include if start date is today or in the future
        guard incomeSource.startDate >= today else {
            #if DEBUG
            print("   One-time income start date is in the past, no schedule generated")
            #endif
            return []
        }
        
        return [IncomeScheduleItem(
            dueDate: incomeSource.startDate,
            amount: incomeSource.amount
        )]
    }
    
    /// Generate schedule for recurring income (weekly/monthly/quarterly/yearly)
    private static func generateRecurringSchedule(
        incomeSource: IncomeSource,
        today: Date,
        scheduleEndDate: Date,
        calendar: Calendar
    ) -> [IncomeScheduleItem] {
        var scheduleItems: [IncomeScheduleItem] = []
        
        // Start from the first occurrence that is today or in the future
        var currentDate = incomeSource.startDate
        
        // If start date is in the past, advance to the next occurrence after today
        if currentDate < today {
            currentDate = findNextOccurrence(
                after: today,
                from: incomeSource.startDate,
                frequency: incomeSource.frequency,
                calendar: calendar
            )
        }
        
        // Generate payments until we reach the schedule end date
        var periodIndex = 0
        let maxPeriods = 1000 // Safety limit to prevent infinite loops
        
        while currentDate <= scheduleEndDate && periodIndex < maxPeriods {
            scheduleItems.append(IncomeScheduleItem(
                dueDate: currentDate,
                amount: incomeSource.amount
            ))
            
            // Calculate next occurrence
            currentDate = calculateNextDate(
                from: currentDate,
                frequency: incomeSource.frequency,
                calendar: calendar
            )
            
            periodIndex += 1
        }
        
        #if DEBUG
        if periodIndex >= maxPeriods {
            print("⚠️ Reached max periods limit (\(maxPeriods)) for income '\(incomeSource.title)'")
        }
        #endif
        
        return scheduleItems
    }
    
    /// Find the next occurrence of a recurring date after a given date
    private static func findNextOccurrence(
        after targetDate: Date,
        from startDate: Date,
        frequency: IncomeFrequency,
        calendar: Calendar
    ) -> Date {
        var currentDate = startDate
        
        // Advance until we're past the target date
        while currentDate < targetDate {
            currentDate = calculateNextDate(
                from: currentDate,
                frequency: frequency,
                calendar: calendar
            )
        }
        
        return currentDate
    }
    
    /// Calculate the next date based on frequency
    private static func calculateNextDate(
        from date: Date,
        frequency: IncomeFrequency,
        calendar: Calendar
    ) -> Date {
        switch frequency {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        case .oneTime:
            return date // Should not be called for one-time
        }
    }
}

// MARK: - Schedule Item

/// Represents a single scheduled income payment (date + amount)
/// Similar to PaymentScheduleItem in LoanCalculator
struct IncomeScheduleItem {
    let dueDate: Date
    let amount: Double
}

// MARK: - Upcoming Income Filter (prepared for future use)

/// Filter helper for upcoming income payments
/// Mirrors UpcomingPaymentsFilter pattern for consistency
class IncomeUpcomingFilter {
    
    /// Default window for "upcoming" income (in days)
    static let defaultWindowDays = 15
    
    /// Get upcoming income payments within the specified window
    /// - Parameters:
    ///   - payments: All income payments to filter
    ///   - windowDays: Number of days to look ahead (default: 15)
    /// - Returns: Filtered and sorted income payments
    static func getUpcoming(
        from payments: [IncomePayment],
        windowDays: Int = defaultWindowDays
    ) -> [IncomePayment] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let endDate = calendar.date(byAdding: .day, value: windowDays, to: today) else {
            return []
        }
        
        return payments
            .filter { payment in
                payment.status == .planned &&
                payment.dueDate >= today &&
                payment.dueDate <= endDate
            }
            .sorted { $0.dueDate < $1.dueDate }
    }
}

