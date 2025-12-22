//
//  CashflowCardView.swift
//  monetiq
//
//  Created on 2025-12-22.
//  Displays a 30-day cashflow chart showing cumulative receive/pay trends
//

import SwiftUI
import Charts

struct CashflowCardView: View {
    let loans: [Loan]
    let windowDays: Int
    
    init(loans: [Loan], windowDays: Int = 30) {
        self.loans = loans
        self.windowDays = windowDays
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.string("dashboard_cashflow"))
                        .font(MonetiqTheme.Typography.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(MonetiqTheme.Colors.textPrimary)
                    
                    Text(L10n.string("dashboard_cashflow_subtitle"))
                        .font(MonetiqTheme.Typography.caption)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    
                    // Context text placed near title for better understanding
                    Text(L10n.string("dashboard_cashflow_helper"))
                        .font(MonetiqTheme.Typography.caption2)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary.opacity(0.85))
                        .padding(.top, 2)
                }
                
                Spacer()
                
                // Net summary - with currency cap for readability
                VStack(alignment: .trailing, spacing: 2) {
                    Text(L10n.string("dashboard_cashflow_net"))
                        .font(MonetiqTheme.Typography.caption)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    
                    let netValues = calculateNetByCurrency()
                    if netValues.isEmpty {
                        Text("—")
                            .font(MonetiqTheme.Typography.body)
                            .foregroundColor(MonetiqTheme.Colors.textTertiary)
                    } else {
                        VStack(alignment: .trailing, spacing: 2) {
                            // Show top 3 currencies with smart ordering:
                            // 1. Positive values first (descending by absolute value)
                            // 2. Negative values last (descending by absolute value)
                            let sortedCurrencies = netValues.keys.sorted { currency1, currency2 in
                                let val1 = netValues[currency1] ?? 0
                                let val2 = netValues[currency2] ?? 0
                                
                                // Positives before negatives
                                if (val1 >= 0) != (val2 >= 0) {
                                    return val1 >= 0
                                }
                                // Within same sign, sort by descending absolute value
                                return abs(val1) > abs(val2)
                            }
                            let displayCurrencies = Array(sortedCurrencies.prefix(3))
                            
                            ForEach(displayCurrencies, id: \.self) { currency in
                                let amount = netValues[currency] ?? 0
                                let prefix = amount >= 0 ? "+" : ""
                                Text("\(prefix)\(CurrencyFormatter.shared.format(amount: amount, currencyCode: currency))")
                                    .font(MonetiqTheme.Typography.body)
                                    .foregroundColor(amount >= 0 ? softGreen : softOrange)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            
                            // Show "+N more" if there are more currencies
                            if netValues.count > 3 {
                                Text(L10n.string("dashboard_cashflow_more_currencies", netValues.count - 3))
                                    .font(MonetiqTheme.Typography.caption2)
                                    .foregroundColor(MonetiqTheme.Colors.textTertiary)
                            }
                        }
                    }
                }
            }
            
            // Chart or empty state
            let chartData = buildChartData()
            let totalPayments = chartData.receiveData.count + chartData.payData.count
            
            if totalPayments == 0 {
                // Empty state - calm and informative
                VStack(spacing: MonetiqTheme.Spacing.sm) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(MonetiqTheme.Colors.textTertiary)
                    
                    Text(L10n.string("dashboard_cashflow_empty"))
                        .font(MonetiqTheme.Typography.caption)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .padding(.vertical, MonetiqTheme.Spacing.sm)
            } else {
                // Chart - calm, professional, understated
                Chart {
                    // Receive line (soft green, solid, full opacity)
                    ForEach(chartData.receiveData) { dataPoint in
                        LineMark(
                            x: .value("Day", dataPoint.day),
                            y: .value("Amount", dataPoint.cumulativeAmount)
                        )
                        .foregroundStyle(softGreen)
                        .lineStyle(StrokeStyle(lineWidth: 2.0))
                        .interpolationMethod(.catmullRom) // Smoother curves to reduce spike perception
                    }
                    
                    // Pay line (soft orange, subtle distinction for readability at intersections)
                    ForEach(chartData.payData) { dataPoint in
                        LineMark(
                            x: .value("Day", dataPoint.day),
                            y: .value("Amount", dataPoint.cumulativeAmount)
                        )
                        .foregroundStyle(softOrange.opacity(0.85)) // Slightly reduced opacity for subtle distinction
                        .lineStyle(StrokeStyle(lineWidth: 2.0, dash: [5, 3])) // Light dash pattern
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: [0, 15, 30]) { value in
                        if let day = value.as(Int.self) {
                            AxisValueLabel {
                                if day == 0 {
                                    Text(L10n.string("dashboard_cashflow_today"))
                                        .font(MonetiqTheme.Typography.caption2)
                                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                                        .fontWeight(.medium)
                                } else {
                                    Text("+\(day)")
                                        .font(MonetiqTheme.Typography.caption2)
                                        .foregroundColor(MonetiqTheme.Colors.textTertiary)
                                }
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                            .foregroundStyle(MonetiqTheme.Colors.cardBorder.opacity(0.2))
                        AxisValueLabel()
                            .foregroundStyle(MonetiqTheme.Colors.textTertiary)
                            .font(MonetiqTheme.Typography.caption2)
                    }
                }
                .frame(height: 140)
                .padding(.top, MonetiqTheme.Spacing.md)
                
                // Legend - minimal and calm
                HStack(spacing: MonetiqTheme.Spacing.md) {
                    HStack(spacing: 6) {
                        Rectangle()
                            .fill(softGreen)
                            .frame(width: 16, height: 2)
                            .cornerRadius(1)
                        
                        Text(L10n.string("dashboard_cashflow_to_receive"))
                            .font(MonetiqTheme.Typography.caption2)
                            .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    }
                    
                    HStack(spacing: 6) {
                        Rectangle()
                            .fill(softOrange)
                            .frame(width: 16, height: 2)
                            .cornerRadius(1)
                        
                        Text(L10n.string("dashboard_cashflow_to_pay"))
                            .font(MonetiqTheme.Typography.caption2)
                            .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(.top, MonetiqTheme.Spacing.sm)
                
                // Low activity hint (conditional)
                if shouldShowLowActivityHint(chartData: chartData) {
                    Text(L10n.string("dashboard_cashflow_low_activity"))
                        .font(MonetiqTheme.Typography.caption2)
                        .foregroundColor(MonetiqTheme.Colors.textTertiary)
                        .padding(.top, 4)
                }
            }
        }
        .monetiqPremiumCard()
    }
    
    // MARK: - Helper Methods
    
    /// Determine if we should show the "low activity" hint
    private func shouldShowLowActivityHint(chartData: (receiveData: [CashflowDataPoint], payData: [CashflowDataPoint])) -> Bool {
        // Count actual payment events (not interpolated points)
        let today = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: windowDays, to: today)!
        
        let allPayments = loans.flatMap { $0.payments }
            .filter { $0.status == .planned }
            .filter { $0.dueDate >= today && $0.dueDate <= endDate }
        
        // Show hint if there are 1-3 payments total (very low activity)
        return allPayments.count > 0 && allPayments.count <= 3
    }
    
    // MARK: - Visual Theme
    
    /// Soft green for "to receive" - calm and reassuring
    private var softGreen: Color {
        Color(red: 0.3, green: 0.7, blue: 0.4).opacity(0.8)
    }
    
    /// Soft orange for "to pay" - neutral, not alarming
    private var softOrange: Color {
        Color(red: 0.95, green: 0.6, blue: 0.3).opacity(0.85)
    }
    
    // MARK: - Data Helpers
    
    /// Calculate net cashflow by currency (receive - pay)
    private func calculateNetByCurrency() -> [String: Double] {
        let receive = calculateTotalsForRole(.lent)
        let pay = calculateTotalsForRoles([.borrowed, .bankCredit])
        
        var net: [String: Double] = [:]
        
        // Add all receive currencies
        for (currency, amount) in receive {
            net[currency] = amount
        }
        
        // Subtract all pay currencies
        for (currency, amount) in pay {
            net[currency, default: 0] -= amount
        }
        
        // Filter out zero/near-zero values
        return net.filter { abs($0.value) > 0.01 }
    }
    
    /// Build cumulative chart data for receive and pay lines
    private func buildChartData() -> (receiveData: [CashflowDataPoint], payData: [CashflowDataPoint]) {
        let today = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: windowDays, to: today)!
        
        // Get all planned payments in the window
        let allPayments = loans.flatMap { $0.payments }
            .filter { $0.status == .planned }
            .filter { $0.dueDate >= today && $0.dueDate <= endDate }
        
        // Separate by role
        let receivePayments = allPayments.filter { payment in
            payment.loan?.role == .lent
        }
        
        let payPayments = allPayments.filter { payment in
            payment.loan?.role == .borrowed || payment.loan?.role == .bankCredit
        }
        
        // Build cumulative series
        let receiveData = buildCumulativeSeries(
            payments: receivePayments,
            startDate: today,
            windowDays: windowDays
        )
        
        let payData = buildCumulativeSeries(
            payments: payPayments,
            startDate: today,
            windowDays: windowDays
        )
        
        return (receiveData, payData)
    }
    
    /// Build a cumulative series from payments
    /// Creates calm, smooth lines that increase gradually without dramatic jumps
    /// Uses strategic point placement + smooth interpolation to reduce spike perception
    private func buildCumulativeSeries(
        payments: [Payment],
        startDate: Date,
        windowDays: Int
    ) -> [CashflowDataPoint] {
        // Group payments by day and sum amounts
        var dailyTotals: [Int: Double] = [:]
        
        for payment in payments {
            let dayOffset = Calendar.current.dateComponents([.day], from: startDate, to: payment.dueDate).day ?? 0
            if dayOffset >= 0 && dayOffset <= windowDays {
                dailyTotals[dayOffset, default: 0] += payment.amount
            }
        }
        
        // Build cumulative series with smooth transitions
        var cumulative: Double = 0
        var dataPoints: [CashflowDataPoint] = []
        
        // Always start at day 0 with 0 (anchored to "Today")
        dataPoints.append(CashflowDataPoint(day: 0, cumulativeAmount: 0))
        
        // Track previous cumulative for spike detection
        var previousCumulative: Double = 0
        
        // Add strategic points to create smooth, readable lines
        for day in 1...windowDays {
            if let dayTotal = dailyTotals[day] {
                cumulative += dayTotal
            }
            
            // Detect if this is a "spike day" (large jump)
            let jump = cumulative - previousCumulative
            let isLargeJump = jump > (cumulative * 0.2) && jump > 100 // 20% jump or >100 units
            
            // Add points strategically:
            // 1. When there's a payment (to show actual changes)
            // 2. Before a large jump (to smooth the curve visually)
            // 3. At regular intervals (every 2 days) for smooth interpolation
            // 4. At key markers (15, 30)
            let isPaymentDay = dailyTotals[day] != nil
            let isRegularInterval = day % 2 == 0
            let isKeyMarker = day == 15 || day == 30
            let needsSmoothingPoint = isLargeJump && day > 1
            
            // Add a point before large jump for smoother visual transition
            if needsSmoothingPoint && dataPoints.last?.day != day - 1 {
                dataPoints.append(CashflowDataPoint(day: day - 1, cumulativeAmount: previousCumulative))
            }
            
            if isPaymentDay || isRegularInterval || isKeyMarker {
                dataPoints.append(CashflowDataPoint(day: day, cumulativeAmount: cumulative))
            }
            
            previousCumulative = cumulative
        }
        
        // Ensure we always end at day 30
        if dataPoints.last?.day != windowDays {
            dataPoints.append(CashflowDataPoint(day: windowDays, cumulativeAmount: cumulative))
        }
        
        // Ensure we have at least 2 points for a visible line
        if dataPoints.count == 1 {
            dataPoints.append(CashflowDataPoint(day: windowDays, cumulativeAmount: cumulative))
        }
        
        return dataPoints
    }
    
    /// Calculate totals for a specific role
    private func calculateTotalsForRole(_ role: LoanRole) -> [String: Double] {
        let relevantLoans = loans.filter { $0.role == role }
        return calculateScheduledPayments(for: relevantLoans)
    }
    
    /// Calculate totals for multiple roles
    private func calculateTotalsForRoles(_ roles: [LoanRole]) -> [String: Double] {
        let relevantLoans = loans.filter { roles.contains($0.role) }
        return calculateScheduledPayments(for: relevantLoans)
    }
    
    /// Calculate scheduled payment totals by currency for the next 30 days
    private func calculateScheduledPayments(for loans: [Loan]) -> [String: Double] {
        let today = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: windowDays, to: today)!
        
        var totals: [String: Double] = [:]
        
        for loan in loans {
            let plannedPayments = loan.payments
                .filter { $0.status == .planned }
                .filter { $0.dueDate >= today && $0.dueDate <= endDate }
            
            for payment in plannedPayments {
                totals[loan.currencyCode, default: 0] += payment.amount
            }
        }
        
        return totals
    }
}

// MARK: - Supporting Types

struct CashflowDataPoint: Identifiable {
    let id = UUID()
    let day: Int
    let cumulativeAmount: Double
}

// MARK: - Preview

#Preview {
    CashflowCardView(loans: [])
        .monetiqBackground()
}

