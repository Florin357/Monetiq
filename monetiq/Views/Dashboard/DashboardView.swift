//
//  DashboardView.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import SwiftUI
import SwiftData

// MARK: - Dashboard-specific types for upcoming payments interactions

struct UpcomingPaymentItem: Identifiable {
    let id: String // stable key for SwiftUI
    let loanID: UUID
    let loanTitle: String
    let counterparty: String?
    let dueDate: Date
    let amount: Double
    let currency: String
    let paymentReference: UUID // payment.id for stable reference
    let payment: Payment // reference to actual payment for actions
    
    var stableKey: String { id }
    
    init(payment: Payment) {
        self.payment = payment
        self.paymentReference = payment.id
        self.id = payment.id.uuidString // use payment UUID as stable key
        self.loanID = payment.loan?.id ?? UUID()
        self.loanTitle = payment.loan?.title ?? "Unknown Loan"
        self.counterparty = payment.loan?.counterparty?.name
        self.dueDate = payment.dueDate
        self.amount = payment.amount
        self.currency = payment.loan?.currencyCode ?? "RON"
    }
}

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var loans: [Loan]
    @Query private var payments: [Payment]
    
    private var appSettings: AppSettings {
        AppSettings.getOrCreate(in: modelContext)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MonetiqTheme.Spacing.sectionSpacing) {
                // Header
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
                    Text(L10n.string("dashboard_title"))
                        .font(MonetiqTheme.Typography.largeTitle)
                        .foregroundColor(MonetiqTheme.Colors.textPrimary)
                    
                    Text(L10n.string("dashboard_subtitle"))
                        .font(MonetiqTheme.Typography.callout)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                }
                .monetiqHeader()
                
                // Summary Cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: MonetiqTheme.Spacing.md) {
                    MultiCurrencySummaryCard(
                        title: L10n.string("dashboard_to_receive"),
                        totals: calculateToReceiveByCurrency(),
                        color: MonetiqTheme.Colors.positive
                    )
                    
                    MultiCurrencySummaryCard(
                        title: L10n.string("dashboard_to_pay"),
                        totals: calculateToPayByCurrency(),
                        color: MonetiqTheme.Colors.negative
                    )
                }
                .monetiqSection()
                
                // Upcoming Payments
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                    Text(L10n.string("dashboard_upcoming_payments"))
                        .monetiqSectionHeader()
                    
                    if upcomingPayments.isEmpty {
                        VStack(spacing: MonetiqTheme.Spacing.sm) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 32))
                                .foregroundColor(MonetiqTheme.Colors.textTertiary)
                            
                            VStack(spacing: MonetiqTheme.Spacing.xs) {
                                Text(L10n.string("dashboard_no_payments"))
                                    .font(MonetiqTheme.Typography.bodyEmphasized)
                                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
                                
                                Text(L10n.string("dashboard_no_payments_subtitle"))
                                    .font(MonetiqTheme.Typography.caption)
                                    .foregroundColor(MonetiqTheme.Colors.textTertiary)
                            }
                        }
                        .monetiqEmptyState()
                    } else {
                        LazyVStack(spacing: MonetiqTheme.Spacing.xs) {
                            ForEach(upcomingPayments.prefix(5), id: \.stableKey) { item in
                                DashboardPaymentRowView(paymentItem: item)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(L10n.string("dashboard_mark_paid")) {
                                            markPaymentAsPaid(item)
                                        }
                                        .tint(MonetiqTheme.Colors.success)
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                        Button(L10n.string("dashboard_postpone")) {
                                            postponePayment(item)
                                        }
                                        .tint(MonetiqTheme.Colors.warning)
                                    }
                            }
                        }
                        .monetiqSection()
                    }
                }
                
                // Recent Loans
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                    Text(L10n.string("dashboard_recent_loans"))
                        .monetiqSectionHeader()
                    
                    if recentLoans.isEmpty {
                        VStack(spacing: MonetiqTheme.Spacing.sm) {
                            Image(systemName: "banknote")
                                .font(.system(size: 32))
                                .foregroundColor(MonetiqTheme.Colors.textTertiary)
                            
                            Text(L10n.string("dashboard_no_loans"))
                                .font(MonetiqTheme.Typography.bodyEmphasized)
                                .foregroundColor(MonetiqTheme.Colors.textSecondary)
                        }
                        .monetiqEmptyState()
                    } else {
                        LazyVStack(spacing: MonetiqTheme.Spacing.xs) {
                            ForEach(recentLoans.prefix(3), id: \.id) { loan in
                                DashboardLoanRowView(loan: loan)
                            }
                        }
                        .monetiqSection()
                    }
                }
            }
            .padding(.vertical, MonetiqTheme.Spacing.sectionSpacing)
        }
        .monetiqBackground()
    }
    
    private var upcomingPayments: [UpcomingPaymentItem] {
        let today = Date()
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: today) ?? today
        
        return payments
            .filter { 
                $0.status == .planned && 
                $0.dueDate >= today && 
                $0.dueDate < thirtyDaysFromNow 
            }
            .sorted { $0.dueDate < $1.dueDate }
            .map { UpcomingPaymentItem(payment: $0) }
    }
    
    private var recentLoans: [Loan] {
        loans.sorted { $0.createdAt > $1.createdAt }
    }
    
    private func calculateToReceiveByCurrency() -> [String: Double] {
        let lentLoans = loans.filter { $0.role == .lent }
        var totals: [String: Double] = [:]
        
        for loan in lentLoans {
            let remaining = (loan.totalToRepay ?? loan.principalAmount) - loan.totalPaid
            if remaining > 0 {
                totals[loan.currencyCode, default: 0] += remaining
            }
        }
        
        return totals
    }
    
    private func calculateToPayByCurrency() -> [String: Double] {
        let borrowedLoans = loans.filter { $0.role == .borrowed || $0.role == .bankCredit }
        var totals: [String: Double] = [:]
        
        for loan in borrowedLoans {
            let remaining = (loan.totalToRepay ?? loan.principalAmount) - loan.totalPaid
            if remaining > 0 {
                totals[loan.currencyCode, default: 0] += remaining
            }
        }
        
        return totals
    }
    
    // MARK: - Payment Actions
    
    private func markPaymentAsPaid(_ item: UpcomingPaymentItem) {
        let payment = item.payment
        
        // Use the same domain action as in Loan Details (single source of truth)
        payment.markAsPaid()
        payment.loan?.updateTimestamp()
        
        // Cancel notifications for this payment
        Task {
            await NotificationManager.shared.cancelNotifications(for: payment)
            await NotificationManager.shared.updateBadgeCount()
        }
        
        // UI will update automatically due to @Query reactivity
        // Row will disappear if payment no longer qualifies as upcoming
    }
    
    private func postponePayment(_ item: UpcomingPaymentItem) {
        let payment = item.payment
        
        // Postpone reminder by 1 day (Option 1: snooze reminder only, not actual due date)
        payment.postponeReminder(by: 1)
        payment.loan?.updateTimestamp()
        
        // Reschedule notifications for this payment
        Task {
            await NotificationManager.shared.rescheduleNotifications(for: payment)
            await NotificationManager.shared.updateBadgeCount()
        }
        
        // UI will update automatically to show snooze status
    }
}

struct SummaryCard: View {
    let title: String
    let amount: Double
    let currency: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
            Text(title)
                .font(MonetiqTheme.Typography.caption)
                .foregroundColor(MonetiqTheme.Colors.textSecondary)
            
            Text(CurrencyFormatter.shared.format(amount: amount, currencyCode: currency))
                .font(MonetiqTheme.Typography.title2)
                .foregroundColor(color)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .monetiqCard()
    }
}

struct MultiCurrencySummaryCard: View {
    let title: String
    let totals: [String: Double]
    let color: Color
    
    private var sortedTotals: [(String, Double)] {
        totals.sorted { $0.value > $1.value }
    }
    
    private var primaryTotal: (String, Double)? {
        sortedTotals.first
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
            // Card title
            Text(title)
                .font(MonetiqTheme.Typography.footnote)
                .foregroundColor(MonetiqTheme.Colors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            if totals.isEmpty {
                // Empty state
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                    Text("0.00")
                        .currencyText(style: .medium, color: MonetiqTheme.Colors.textTertiary)
                    
                    Text(L10n.string("dashboard_zero_amount"))
                        .font(MonetiqTheme.Typography.caption)
                        .foregroundColor(MonetiqTheme.Colors.textTertiary)
                }
            } else {
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                    // Primary amount (largest)
                    if let primary = primaryTotal {
                        Text(CurrencyFormatter.shared.format(amount: primary.1, currencyCode: primary.0))
                            .currencyText(style: sortedTotals.count == 1 ? .large : .medium, color: color)
                    }
                    
                    // Additional currencies (if any)
                    if sortedTotals.count > 1 {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(sortedTotals.dropFirst().prefix(2)), id: \.0) { currency, amount in
                                Text(CurrencyFormatter.shared.format(amount: amount, currencyCode: currency))
                                    .currencyText(style: .small, color: MonetiqTheme.Colors.textSecondary)
                            }
                            
                            if sortedTotals.count > 3 {
                                Text(L10n.string("dashboard_more_currencies", sortedTotals.count - 3))
                                    .font(MonetiqTheme.Typography.caption2)
                                    .foregroundColor(MonetiqTheme.Colors.textTertiary)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .monetiqCard()
    }
}

struct DashboardPaymentRowView: View {
    let paymentItem: UpcomingPaymentItem
    
    // Convenience accessor for the underlying payment
    private var payment: Payment { paymentItem.payment }
    
    private var roleColor: Color {
        guard let role = payment.loan?.role else { return MonetiqTheme.Colors.neutral }
        
        switch role {
        case .lent:
            return MonetiqTheme.Colors.positive  // Green - money to receive
        case .borrowed:
            return MonetiqTheme.Colors.negative  // Orange - money to pay
        case .bankCredit:
            return MonetiqTheme.Colors.error     // Red - bank credit
        }
    }
    
    private var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: paymentItem.dueDate).day ?? 0
    }
    
    private var dueDateText: String {
        // Show snooze status if payment is snoozed
        if payment.isReminderSnoozed, let snoozeUntil = payment.snoozeUntil {
            return L10n.string("dashboard_payment_snoozed_until", snoozeUntil.formatted(date: .abbreviated, time: .omitted))
        }
        
        if daysUntilDue == 0 {
            return L10n.string("payment_due_today")
        } else if daysUntilDue == 1 {
            return L10n.string("payment_due_tomorrow")
        } else if daysUntilDue > 1 {
            return L10n.string("payment_due_in_days", daysUntilDue)
        } else {
            return paymentItem.dueDate.formatted(date: .abbreviated, time: .omitted)
        }
    }
    
    private var dueDateColor: Color {
        if payment.isReminderSnoozed {
            return MonetiqTheme.Colors.warning // Orange for snoozed
        } else if daysUntilDue <= 1 {
            return MonetiqTheme.Colors.error // Red for urgent
        } else {
            return MonetiqTheme.Colors.textSecondary // Normal
        }
    }
    
    var body: some View {
        Group {
            if let loan = payment.loan {
                NavigationLink(destination: LoanDetailView(
                    loan: loan,
                    focusPaymentId: paymentItem.paymentReference
                )) {
                    paymentRowContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Fallback for orphaned payment (should not happen in normal use)
                paymentRowContent
                    .onTapGesture {
                        // Could show an alert here if needed
                        print("⚠️ Dashboard: Loan not found for payment \(paymentItem.paymentReference)")
                    }
            }
        }
    }
    
    private var paymentRowContent: some View {
        HStack(spacing: MonetiqTheme.Spacing.md) {
            // Leading indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(roleColor)
                .frame(width: 4, height: 32)
            
            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                Text(paymentItem.loanTitle)
                    .font(MonetiqTheme.Typography.bodyEmphasized)
                    .foregroundColor(MonetiqTheme.Colors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: MonetiqTheme.Spacing.sm) {
                    if let counterparty = paymentItem.counterparty {
                        Text(counterparty)
                            .font(MonetiqTheme.Typography.caption)
                            .foregroundColor(MonetiqTheme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Text("•")
                        .font(MonetiqTheme.Typography.caption)
                        .foregroundColor(MonetiqTheme.Colors.textTertiary)
                    
                    Text(dueDateText)
                        .font(MonetiqTheme.Typography.caption)
                        .foregroundColor(dueDateColor)
                }
            }
            
            Spacer()
            
            Text(CurrencyFormatter.shared.format(amount: paymentItem.amount, currencyCode: paymentItem.currency))
                .currencyText(style: .small, color: roleColor)
        }
        .padding(MonetiqTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MonetiqTheme.CornerRadius.md)
                .fill(MonetiqTheme.Colors.surface)
        )
    }
}

struct DashboardLoanRowView: View {
    let loan: Loan
    
    private var roleColor: Color {
        switch loan.role {
        case .lent:
            return MonetiqTheme.Colors.positive
        case .borrowed:
            return MonetiqTheme.Colors.negative
        case .bankCredit:
            return MonetiqTheme.Colors.error
        }
    }
    
    var body: some View {
        HStack(spacing: MonetiqTheme.Spacing.md) {
            // Leading indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(roleColor)
                .frame(width: 4, height: 32)
            
            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                Text(loan.title)
                    .font(MonetiqTheme.Typography.bodyEmphasized)
                    .foregroundColor(MonetiqTheme.Colors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: MonetiqTheme.Spacing.sm) {
                    Text(loan.role.localizedLabel)
                        .font(MonetiqTheme.Typography.caption)
                        .foregroundColor(roleColor)
                    
                    if let counterparty = loan.counterparty {
                        Text("•")
                            .font(MonetiqTheme.Typography.caption)
                            .foregroundColor(MonetiqTheme.Colors.textTertiary)
                        
                        Text(counterparty.name)
                            .font(MonetiqTheme.Typography.caption)
                            .foregroundColor(MonetiqTheme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            Text(CurrencyFormatter.shared.format(amount: loan.principalAmount, currencyCode: loan.currencyCode))
                .currencyText(style: .small, color: MonetiqTheme.Colors.textPrimary)
        }
        .padding(MonetiqTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MonetiqTheme.CornerRadius.md)
                .fill(MonetiqTheme.Colors.surface)
        )
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Counterparty.self, Loan.self, Payment.self], inMemory: true)
}
