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
                
                // Upcoming Payments - Premium section
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.lg) {
                    HStack {
                        Text(L10n.string("dashboard_upcoming_payments"))
                            .monetiqSectionHeader()
                        
                        Spacer()
                        
                        if !upcomingPayments.isEmpty {
                            Text("\(upcomingPayments.count)")
                                .font(MonetiqTheme.Typography.caption)
                                .foregroundColor(MonetiqTheme.Colors.textTertiary)
                                .padding(.horizontal, MonetiqTheme.Spacing.sm)
                                .padding(.vertical, MonetiqTheme.Spacing.xs)
                                .background(
                                    Capsule()
                                        .fill(MonetiqTheme.Colors.surface)
                                )
                        }
                    }
                    .padding(.horizontal, MonetiqTheme.Spacing.screenPadding)
                    
                    if upcomingPayments.isEmpty {
                        VStack(spacing: MonetiqTheme.Spacing.sm) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 32, weight: .light))
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
                        List(upcomingPayments.prefix(5), id: \.stableKey) { item in
                            if let loan = item.payment.loan {
                                NavigationLink(destination: LoanDetailView(
                                    loan: loan,
                                    focusPaymentId: item.paymentReference
                                )) {
                                    DashboardPaymentRowContent(paymentItem: item)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button {
                                        markPaymentAsPaid(item)
                                    } label: {
                                        Label(L10n.string("dashboard_mark_paid"), systemImage: "checkmark.circle.fill")
                                    }
                                    .tint(MonetiqTheme.Colors.success)
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button {
                                        postponePayment(item)
                                    } label: {
                                        Label(L10n.string("dashboard_postpone"), systemImage: "clock.arrow.circlepath")
                                    }
                                    .tint(MonetiqTheme.Colors.warning)
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                        .scrollDisabled(true)
                        .frame(height: CGFloat(upcomingPayments.prefix(5).count) * 90) // Increased height for better spacing
                        .background(Color.clear)
                        .environment(\.defaultMinListRowHeight, 0)
                    }
                }
                
                // Recent Loans - Premium section
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.lg) {
                    HStack {
                        Text(L10n.string("dashboard_recent_loans"))
                            .monetiqSectionHeader()
                        
                        Spacer()
                        
                        if !recentLoans.isEmpty {
                            Text("\(recentLoans.count)")
                                .font(MonetiqTheme.Typography.caption)
                                .foregroundColor(MonetiqTheme.Colors.textTertiary)
                                .padding(.horizontal, MonetiqTheme.Spacing.sm)
                                .padding(.vertical, MonetiqTheme.Spacing.xs)
                                .background(
                                    Capsule()
                                        .fill(MonetiqTheme.Colors.surface)
                                )
                        }
                    }
                    .padding(.horizontal, MonetiqTheme.Spacing.screenPadding)
                    
                    if recentLoans.isEmpty {
                        VStack(spacing: MonetiqTheme.Spacing.sm) {
                            Image(systemName: "banknote")
                                .font(.system(size: 32, weight: .light))
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
        .navigationTitle(L10n.string("dashboard_title"))
        .navigationBarTitleDisplayMode(.large)
        .monetiqBackground()
    }
    
    /// SOURCE OF TRUTH: Upcoming Payments Logic
    /// Uses UpcomingPaymentsFilter for consistent filtering across:
    /// 1. Dashboard "Upcoming Payments" section
    /// 2. App icon badge count
    ///
    /// Business Rule: A payment is "upcoming" if it's due within the next 15 days.
    /// This is INDEPENDENT of notification settings.
    private var upcomingPayments: [UpcomingPaymentItem] {
        let upcomingFiltered = UpcomingPaymentsFilter.filterUpcomingPayments(from: payments)
        return upcomingFiltered.map { UpcomingPaymentItem(payment: $0) }
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
        
        // CONSISTENCY FIX: Trigger full reconciliation to ensure consistency
        Task {
            await NotificationManager.shared.reconcileAllPaymentNotifications(with: loans)
        }
        
        // UI will update automatically due to @Query reactivity
        // Row will disappear if payment no longer qualifies as upcoming
    }
    
    private func postponePayment(_ item: UpcomingPaymentItem) {
        let payment = item.payment
        
        // Postpone reminder by 1 day (Option 1: snooze reminder only, not actual due date)
        payment.postponeReminder(by: 1)
        payment.loan?.updateTimestamp()
        
        // CONSISTENCY FIX: Trigger full reconciliation to ensure consistency
        Task {
            await NotificationManager.shared.reconcileAllPaymentNotifications(with: loans)
        }
        
        // UI will update automatically to show snooze status
    }
    
    private func navigateToPayment(_ item: UpcomingPaymentItem) {
        // This will be handled by the NavigationLink in the row
        // For now, we'll keep the NavigationLink approach but make it work with swipes
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
        VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.lg) {
            // Card title - Premium styling
            Text(title)
                .font(MonetiqTheme.Typography.caption)
                .foregroundColor(MonetiqTheme.Colors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.8)
                .fontWeight(.medium)
            
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
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
                    // Primary amount (largest) - Premium styling
                    if let primary = primaryTotal {
                        Text(CurrencyFormatter.shared.format(amount: primary.1, currencyCode: primary.0))
                            .font(sortedTotals.count == 1 ? MonetiqTheme.Typography.currencyLarge : MonetiqTheme.Typography.currencyMedium)
                            .foregroundColor(color)
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                            .minimumScaleFactor(0.7)
                    }
                    
                    // Additional currencies (if any) - Subtle secondary display
                    if sortedTotals.count > 1 {
                        VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                            ForEach(Array(sortedTotals.dropFirst().prefix(2)), id: \.0) { currency, amount in
                                Text(CurrencyFormatter.shared.format(amount: amount, currencyCode: currency))
                                    .font(MonetiqTheme.Typography.currencyCaption)
                                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
                                    .opacity(0.8)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .minimumScaleFactor(0.75)
                            }
                            
                            if sortedTotals.count > 3 {
                                Text(L10n.string("dashboard_more_currencies", sortedTotals.count - 3))
                                    .font(MonetiqTheme.Typography.caption2)
                                    .foregroundColor(MonetiqTheme.Colors.textTertiary)
                                    .opacity(0.7)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .monetiqPremiumCard()
    }
}

struct DashboardPaymentRowContent: View {
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
        HStack(spacing: MonetiqTheme.Spacing.lg) {
            // Leading indicator - Premium style
            RoundedRectangle(cornerRadius: 3)
                .fill(roleColor)
                .frame(width: 5, height: 40)
            
            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
                // Primary title - Enhanced hierarchy
                Text(paymentItem.loanTitle)
                    .monetiqCardTitle()
                    .lineLimit(1)
                
                // Secondary info - Better visual separation
                HStack(spacing: MonetiqTheme.Spacing.sm) {
                    if let counterparty = paymentItem.counterparty {
                        Text(counterparty)
                            .monetiqCardSubtitle()
                            .lineLimit(1)
                    }
                    
                    Text("•")
                        .font(MonetiqTheme.Typography.caption2)
                        .foregroundColor(MonetiqTheme.Colors.textTertiary)
                        .opacity(0.6)
                    
                    Text(dueDateText)
                        .font(MonetiqTheme.Typography.caption)
                        .foregroundColor(dueDateColor)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            // Amount - Premium currency display
            VStack(alignment: .trailing, spacing: 2) {
                Text(CurrencyFormatter.shared.format(amount: paymentItem.amount, currencyCode: paymentItem.currency))
                    .font(MonetiqTheme.Typography.currencySmall)
                    .foregroundColor(roleColor)
                    .fontWeight(.semibold)
            }
        }
        .padding(.horizontal, MonetiqTheme.Spacing.lg)
        .padding(.vertical, MonetiqTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MonetiqTheme.CornerRadius.card)
                .fill(MonetiqTheme.Colors.surface)
                .shadow(
                    color: MonetiqTheme.Shadow.card,
                    radius: 4,
                    x: 0,
                    y: 2
                )
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
        HStack(alignment: .top, spacing: MonetiqTheme.Spacing.lg) {
            // Leading indicator - Premium style
            RoundedRectangle(cornerRadius: 3)
                .fill(roleColor)
                .frame(width: 5, height: 40)
            
            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
                // Primary title - Enhanced hierarchy with truncation
                Text(loan.title)
                    .monetiqCardTitle()
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                // Status badge - Fixed size, no wrapping
                HStack {
                    Text(loan.role.localizedLabel)
                        .font(MonetiqTheme.Typography.caption)
                        .foregroundColor(roleColor)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, MonetiqTheme.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(roleColor.opacity(0.15))
                        )
                    
                    Spacer()
                }
                
                // Counterparty - Separate row with truncation
                if let counterparty = loan.counterparty {
                    Text(counterparty.name)
                        .monetiqCardSubtitle()
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            
            Spacer(minLength: 12)
            
            // Compact Amount Display - Resists wrapping
            CompactAmountView(
                amount: loan.principalAmount,
                currencyCode: loan.currencyCode
            )
        }
        .padding(.horizontal, MonetiqTheme.Spacing.lg)
        .padding(.vertical, MonetiqTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MonetiqTheme.CornerRadius.card)
                .fill(MonetiqTheme.Colors.surface)
                .shadow(
                    color: MonetiqTheme.Shadow.card,
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
    }
}

struct CompactAmountView: View {
    let amount: Double
    let currencyCode: String
    
    var body: some View {
        Text(CurrencyFormatter.shared.format(amount: amount, currencyCode: currencyCode))
            .font(MonetiqTheme.Typography.currencySmall)
            .foregroundColor(MonetiqTheme.Colors.textPrimary)
            .fontWeight(.semibold)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .minimumScaleFactor(0.85)
            .layoutPriority(1)
            .multilineTextAlignment(.trailing)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Counterparty.self, Loan.self, Payment.self], inMemory: true)
}
