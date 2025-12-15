//
//  LoanCalculator.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import Foundation

struct LoanCalculationInput {
    let principal: Double
    let annualInterestRate: Double?
    let numberOfPeriods: Int
    let frequency: PaymentFrequency
    let interestMode: InterestMode
    let fixedTotalToRepay: Double?
    let startDate: Date
}

struct LoanCalculationOutput {
    let totalToRepay: Double
    let periodicPaymentAmount: Double
    let schedule: [PaymentScheduleItem]
}

struct PaymentScheduleItem {
    let dueDate: Date
    let amount: Double
}

class LoanCalculator {
    
    static func generateSchedule(input: LoanCalculationInput) -> LoanCalculationOutput {
        // Validate input to prevent division by zero and invalid calculations
        guard input.numberOfPeriods > 0 else {
            return LoanCalculationOutput(
                totalToRepay: input.principal,
                periodicPaymentAmount: input.principal,
                schedule: []
            )
        }
        
        let totalToRepay = calculateTotalToRepay(input: input)
        let periodicPaymentAmount = totalToRepay / Double(input.numberOfPeriods)
        
        // Validate calculated values to prevent NaN or infinite values
        guard totalToRepay.isFinite && periodicPaymentAmount.isFinite else {
            return LoanCalculationOutput(
                totalToRepay: input.principal,
                periodicPaymentAmount: input.principal,
                schedule: []
            )
        }
        
        let schedule = generatePaymentSchedule(
            startDate: input.startDate,
            frequency: input.frequency,
            numberOfPeriods: input.numberOfPeriods,
            periodicAmount: periodicPaymentAmount,
            totalToRepay: totalToRepay
        )
        
        return LoanCalculationOutput(
            totalToRepay: totalToRepay,
            periodicPaymentAmount: periodicPaymentAmount,
            schedule: schedule
        )
    }
    
    private static func calculateTotalToRepay(input: LoanCalculationInput) -> Double {
        switch input.interestMode {
        case .none:
            return input.fixedTotalToRepay ?? input.principal
            
        case .percentageAnnual:
            guard let annualRate = input.annualInterestRate else {
                return input.principal
            }
            
            let totalDurationInYears = calculateDurationInYears(
                numberOfPeriods: input.numberOfPeriods,
                frequency: input.frequency
            )
            
            let effectiveInterest = input.principal * (annualRate / 100.0) * totalDurationInYears
            return input.principal + effectiveInterest
            
        case .fixedTotal:
            return input.fixedTotalToRepay ?? input.principal
        }
    }
    
    private static func calculateDurationInYears(numberOfPeriods: Int, frequency: PaymentFrequency) -> Double {
        switch frequency {
        case .weekly:
            return Double(numberOfPeriods) / 52.0
        case .monthly:
            return Double(numberOfPeriods) / 12.0
        case .quarterly:
            return Double(numberOfPeriods) / 4.0
        case .yearly:
            return Double(numberOfPeriods)
        }
    }
    
    private static func generatePaymentSchedule(
        startDate: Date,
        frequency: PaymentFrequency,
        numberOfPeriods: Int,
        periodicAmount: Double,
        totalToRepay: Double
    ) -> [PaymentScheduleItem] {
        var schedule: [PaymentScheduleItem] = []
        let calendar = Calendar.current
        
        for i in 0..<numberOfPeriods {
            let dueDate = calculateDueDate(
                startDate: startDate,
                frequency: frequency,
                periodIndex: i,
                calendar: calendar
            )
            
            // Adjust the last payment to correct for rounding errors
            let amount: Double
            if i == numberOfPeriods - 1 {
                let totalScheduled = schedule.reduce(0) { $0 + $1.amount }
                amount = totalToRepay - totalScheduled
            } else {
                amount = periodicAmount
            }
            
            // Validate amount is finite before adding to schedule
            guard amount.isFinite && amount >= 0 else {
                continue // Skip invalid payments
            }
            
            schedule.append(PaymentScheduleItem(dueDate: dueDate, amount: amount))
        }
        
        return schedule
    }
    
    private static func calculateDueDate(
        startDate: Date,
        frequency: PaymentFrequency,
        periodIndex: Int,
        calendar: Calendar
    ) -> Date {
        switch frequency {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: periodIndex, to: startDate) ?? startDate
        case .monthly:
            return calendar.date(byAdding: .month, value: periodIndex, to: startDate) ?? startDate
        case .quarterly:
            return calendar.date(byAdding: .month, value: periodIndex * 3, to: startDate) ?? startDate
        case .yearly:
            return calendar.date(byAdding: .year, value: periodIndex, to: startDate) ?? startDate
        }
    }
}

// MARK: - Calculator Tab Helper
extension LoanCalculator {
    
    struct CalculatorResult {
        let periodicPaymentAmount: Double
        let totalToRepay: Double
        let totalInterest: Double
    }
    
    static func calculateForDisplay(
        principal: Double,
        annualInterestRate: Double,
        numberOfPeriods: Int,
        frequency: PaymentFrequency
    ) -> CalculatorResult {
        let input = LoanCalculationInput(
            principal: principal,
            annualInterestRate: annualInterestRate,
            numberOfPeriods: numberOfPeriods,
            frequency: frequency,
            interestMode: .percentageAnnual,
            fixedTotalToRepay: nil,
            startDate: Date()
        )
        
        let output = generateSchedule(input: input)
        let totalInterest = output.totalToRepay - principal
        
        return CalculatorResult(
            periodicPaymentAmount: output.periodicPaymentAmount,
            totalToRepay: output.totalToRepay,
            totalInterest: totalInterest
        )
    }
}



