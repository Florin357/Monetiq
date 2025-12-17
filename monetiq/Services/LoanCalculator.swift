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
        // INPUT VALIDATION (F06 from audit)
        guard input.numberOfPeriods > 0 else {
            #if DEBUG
            print("⚠️ VALIDATION: numberOfPeriods must be > 0")
            #endif
            return LoanCalculationOutput(
                totalToRepay: input.principal,
                periodicPaymentAmount: input.principal,
                schedule: []
            )
        }
        
        guard input.principal > 0 else {
            #if DEBUG
            print("⚠️ VALIDATION: principal must be > 0")
            #endif
            return LoanCalculationOutput(
                totalToRepay: 0,
                periodicPaymentAmount: 0,
                schedule: []
            )
        }
        
        if let rate = input.annualInterestRate, rate < 0 {
            #if DEBUG
            print("⚠️ VALIDATION: annualInterestRate must be >= 0")
            #endif
            return LoanCalculationOutput(
                totalToRepay: input.principal,
                periodicPaymentAmount: input.principal / Double(input.numberOfPeriods),
                schedule: []
            )
        }
        
        // Calculate using appropriate formula based on interest mode
        let result: (totalToRepay: Double, periodicPayment: Double)
        
        switch input.interestMode {
        case .none:
            // No interest - simple division
            let total = input.principal
            let payment = total / Double(input.numberOfPeriods)
            result = (total, payment)
            
        case .percentageAnnual:
            // AMORTIZATION (PMT formula) - compound interest
            result = calculateAmortizedLoan(input: input)
            
        case .fixedTotal:
            // Fixed total - user specifies exact amount to repay
            let total = input.fixedTotalToRepay ?? input.principal
            let payment = total / Double(input.numberOfPeriods)
            result = (total, payment)
        }
        
        let totalToRepay = result.totalToRepay
        let periodicPaymentAmount = result.periodicPayment
        
        // Validate calculated values to prevent NaN or infinite values
        guard totalToRepay.isFinite && periodicPaymentAmount.isFinite else {
            #if DEBUG
            print("⚠️ CALCULATION ERROR: Non-finite values detected")
            #endif
            return LoanCalculationOutput(
                totalToRepay: input.principal,
                periodicPaymentAmount: input.principal,
                schedule: []
            )
        }
        
        // Generate payment schedule with proper rounding
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
    
    /// Calculate amortized loan using PMT formula (compound interest)
    /// Formula: PMT = P × [r(1+r)^n] / [(1+r)^n - 1]
    /// Where: P = principal, r = periodic rate, n = number of periods
    private static func calculateAmortizedLoan(input: LoanCalculationInput) -> (totalToRepay: Double, periodicPayment: Double) {
        guard let annualRate = input.annualInterestRate else {
            // No rate specified, treat as 0% interest
            let payment = input.principal / Double(input.numberOfPeriods)
            return (input.principal, payment)
        }
        
        // Convert APR to periodic rate
        let periodsPerYear = periodsPerYear(for: input.frequency)
        let periodicRate = (annualRate / 100.0) / periodsPerYear
        
        // Handle 0% interest as special case
        guard periodicRate > 0 else {
            let payment = input.principal / Double(input.numberOfPeriods)
            return (input.principal, payment)
        }
        
        let n = Double(input.numberOfPeriods)
        let P = input.principal
        let r = periodicRate
        
        // PMT formula: P × [r(1+r)^n] / [(1+r)^n - 1]
        let onePlusR = 1.0 + r
        let onePlusRPowerN = pow(onePlusR, n)
        
        let numerator = P * r * onePlusRPowerN
        let denominator = onePlusRPowerN - 1.0
        
        // Safety check for division by zero
        guard denominator > 0.000001 else {
            #if DEBUG
            print("⚠️ CALCULATION: Denominator too small, falling back to simple division")
            #endif
            let payment = input.principal / Double(input.numberOfPeriods)
            return (input.principal, payment)
        }
        
        let periodicPayment = numerator / denominator
        
        // Round to 2 decimals for currency precision
        let roundedPayment = round(periodicPayment * 100) / 100
        
        // Total is payment × periods (will be adjusted in schedule for exact sum)
        let totalToRepay = roundedPayment * n
        
        #if DEBUG
        print("📐 AMORTIZATION CALCULATION:")
        print("   Principal: \(P)")
        print("   APR: \(annualRate)%")
        print("   Periods: \(Int(n)) × \(input.frequency.rawValue)")
        print("   Periodic Rate: \(periodicRate * 100)%")
        print("   Payment: \(roundedPayment)")
        print("   Estimated Total: \(totalToRepay)")
        #endif
        
        return (totalToRepay, roundedPayment)
    }
    
    /// Get number of compounding periods per year for a given frequency
    private static func periodsPerYear(for frequency: PaymentFrequency) -> Double {
        switch frequency {
        case .weekly: return 52.0
        case .monthly: return 12.0
        case .quarterly: return 4.0
        case .yearly: return 1.0
        }
    }
    
    /// Generate payment schedule with proper rounding and last payment adjustment
    /// Ensures sum(payments) == totalToRepay exactly (within 0.01 tolerance)
    private static func generatePaymentSchedule(
        startDate: Date,
        frequency: PaymentFrequency,
        numberOfPeriods: Int,
        periodicAmount: Double,
        totalToRepay: Double
    ) -> [PaymentScheduleItem] {
        var schedule: [PaymentScheduleItem] = []
        let calendar = Calendar.current
        
        // Round periodic amount to 2 decimals (currency precision)
        let roundedPeriodicAmount = round(periodicAmount * 100) / 100
        
        for i in 0..<numberOfPeriods {
            let dueDate = calculateDueDate(
                startDate: startDate,
                frequency: frequency,
                periodIndex: i,
                calendar: calendar
            )
            
            // Calculate amount with proper rounding
            let amount: Double
            if i == numberOfPeriods - 1 {
                // LAST PAYMENT ADJUSTMENT: Ensure exact sum
                // This corrects for cumulative rounding errors
                let totalScheduled = schedule.reduce(0) { $0 + $1.amount }
                let remaining = totalToRepay - totalScheduled
                amount = round(remaining * 100) / 100
            } else {
                // Regular payment, rounded to 2 decimals
                amount = roundedPeriodicAmount
            }
            
            // Validate amount is finite and positive
            guard amount.isFinite && amount >= 0 else {
                #if DEBUG
                print("⚠️ Invalid payment amount at period \(i): \(amount)")
                #endif
                continue
            }
            
            schedule.append(PaymentScheduleItem(dueDate: dueDate, amount: amount))
        }
        
        // Verification: Ensure sum matches total (within 0.01 tolerance)
        #if DEBUG
        let scheduleSum = schedule.reduce(0) { $0 + $1.amount }
        let difference = abs(scheduleSum - totalToRepay)
        if difference > 0.01 {
            print("⚠️ ROUNDING WARNING: Schedule sum (\(scheduleSum)) differs from total (\(totalToRepay)) by \(difference)")
        } else {
            print("✅ ROUNDING OK: Schedule sum matches total (±0.01)")
        }
        #endif
        
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



