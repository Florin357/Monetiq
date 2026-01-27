//
//  ExpenseScheduleGenerator.swift
//  monetiq
//
//  Created by AI Assistant on 26.01.2026.
//

import Foundation
import SwiftData

/// Service responsible for generating and managing expense occurrence schedules
/// Mirrors the pattern used in IncomeScheduleGenerator for consistency
class ExpenseScheduleGenerator {
    
    /// Rolling window for generating future expense occurrences (in months)
    private static let rollingWindowMonths = 12
    
    // MARK: - Public API
    
    /// Generate initial schedule for a new expense
    /// - Parameters:
    ///   - expense: The expense to generate schedule for
    ///   - modelContext: SwiftData context for persistence
    /// - Returns: Array of generated ExpenseOccurrence objects
    @discardableResult
    static func generateInitialSchedule(
        for expense: Expense,
        in modelContext: ModelContext
    ) -> [ExpenseOccurrence] {
        #if DEBUG
        print("📅 ExpenseScheduleGenerator: Generating initial schedule for '\(expense.title)'")
        #endif
        
        // Clear any existing occurrences (should be empty for new expense, but defensive)
        expense.occurrences.removeAll()
        
        // Generate schedule items
        let scheduleItems = generateScheduleItems(for: expense)
        
        // Create ExpenseOccurrence objects and link to expense
        var occurrences: [ExpenseOccurrence] = []
        for item in scheduleItems {
            let occurrence = ExpenseOccurrence(
                dueDate: item.dueDate,
                amount: item.amount,
                status: .planned,
                expense: expense
            )
            modelContext.insert(occurrence)
            occurrences.append(occurrence)
        }
        
        expense.occurrences = occurrences
        expense.updateTimestamp()
        
        #if DEBUG
        print("✅ Generated \(occurrences.count) expense occurrences")
        #endif
        
        return occurrences
    }
    
    /// Refresh schedule for an existing expense
    /// Preserves paid occurrences, regenerates planned occurrences
    /// - Parameters:
    ///   - expense: The expense to refresh schedule for
    ///   - modelContext: SwiftData context for persistence
    /// - Returns: Array of newly generated ExpenseOccurrence objects
    @discardableResult
    static func refreshSchedule(
        for expense: Expense,
        in modelContext: ModelContext
    ) -> [ExpenseOccurrence] {
        #if DEBUG
        print("🔄 ExpenseScheduleGenerator: Refreshing schedule for '\(expense.title)'")
        #endif
        
        // CRITICAL: Preserve paid occurrences (do NOT delete history)
        let paidOccurrences = expense.occurrences.filter { $0.status == .paid }
        
        #if DEBUG
        print("   Preserving \(paidOccurrences.count) paid occurrences")
        #endif
        
        // Remove only planned occurrences
        let plannedOccurrences = expense.occurrences.filter { $0.status == .planned }
        for occurrence in plannedOccurrences {
            modelContext.delete(occurrence)
        }
        
        // Generate new schedule items
        let scheduleItems = generateScheduleItems(for: expense)
        
        // Create new ExpenseOccurrence objects for planned occurrences
        var newOccurrences: [ExpenseOccurrence] = []
        for item in scheduleItems {
            // Check if this date already has a paid occurrence (avoid duplicates)
            let alreadyPaid = paidOccurrences.contains { occurrence in
                Calendar.current.isDate(occurrence.dueDate, inSameDayAs: item.dueDate)
            }
            
            if !alreadyPaid {
                let occurrence = ExpenseOccurrence(
                    dueDate: item.dueDate,
                    amount: item.amount,
                    status: .planned,
                    expense: expense
                )
                modelContext.insert(occurrence)
                newOccurrences.append(occurrence)
            }
        }
        
        // Update expense's occurrences array
        expense.occurrences = paidOccurrences + newOccurrences
        expense.updateTimestamp()
        
        #if DEBUG
        print("✅ Refreshed schedule: \(paidOccurrences.count) paid + \(newOccurrences.count) new = \(expense.occurrences.count) total")
        #endif
        
        return newOccurrences
    }
    
    // MARK: - Private Helpers
    
    /// Generate schedule items (dates + amounts) for an expense
    private static func generateScheduleItems(for expense: Expense) -> [ScheduleItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // For one-time expenses, just return if not in the past
        if expense.frequency == .oneTime {
            let startDay = calendar.startOfDay(for: expense.startDate)
            // Only generate if >= today (don't generate past one-time expenses)
            if startDay >= today {
                return [ScheduleItem(dueDate: expense.startDate, amount: expense.amount)]
            } else {
                return [] // One-time in the past, don't regenerate
            }
        }
        
        // For recurring: start from max(startDate, today)
        var currentDate = max(expense.startDate, today)
        
        // If startDate is in past, advance to first future occurrence
        if expense.startDate < today {
            // Fast-forward to first occurrence >= today
            while currentDate < today {
                guard let next = nextOccurrenceDate(after: currentDate, frequency: expense.frequency, calendar: calendar, originalStartDate: expense.startDate) else {
                    break
                }
                currentDate = next
            }
        }
        
        var items: [ScheduleItem] = []
        let rollingEndDate = calendar.date(byAdding: .month, value: rollingWindowMonths, to: today)!
        let effectiveEndDate: Date
        if let expenseEndDate = expense.endDate {
            effectiveEndDate = min(expenseEndDate, rollingEndDate)
        } else {
            effectiveEndDate = rollingEndDate
        }
        
        // Generate occurrences up to the effective end date
        while currentDate <= effectiveEndDate {
            items.append(ScheduleItem(dueDate: currentDate, amount: expense.amount))
            
            // Calculate next occurrence date based on frequency
            guard let nextDate = nextOccurrenceDate(after: currentDate, frequency: expense.frequency, calendar: calendar, originalStartDate: expense.startDate) else {
                break
            }
            
            currentDate = nextDate
            
            // Safety check to prevent infinite loops
            if items.count > 1000 {
                #if DEBUG
                print("⚠️ ExpenseScheduleGenerator: Hit safety limit (1000 occurrences)")
                #endif
                break
            }
        }
        
        return items
    }
    
    /// Calculate the next occurrence date based on frequency
    /// For monthly/quarterly: preserves original day-of-month (with clamping for invalid dates)
    private static func nextOccurrenceDate(after date: Date, frequency: ExpenseFrequency, calendar: Calendar, originalStartDate: Date) -> Date? {
        switch frequency {
        case .oneTime:
            return nil // One-time expenses don't repeat
            
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
            
        case .monthly:
            // Extract intended day-of-month from original start date
            let intendedDay = calendar.component(.day, from: originalStartDate)
            
            // Add 1 month to current date
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: date) else {
                return nil
            }
            
            // Try to set to intended day (will clamp if invalid, e.g., Jan 31 → Feb 28)
            var components = calendar.dateComponents([.year, .month, .day], from: nextMonth)
            components.day = intendedDay
            
            return calendar.date(from: components)
            
        case .quarterly:
            // Same logic for quarterly - preserve original day
            let intendedDay = calendar.component(.day, from: originalStartDate)
            
            guard let nextQuarter = calendar.date(byAdding: .month, value: 3, to: date) else {
                return nil
            }
            
            var components = calendar.dateComponents([.year, .month, .day], from: nextQuarter)
            components.day = intendedDay
            
            return calendar.date(from: components)
            
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date)
        }
    }
    
    // MARK: - Helper Types
    
    private struct ScheduleItem {
        let dueDate: Date
        let amount: Double
    }
}

