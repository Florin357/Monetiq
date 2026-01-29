//
//  DashboardView.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import SwiftUI
import SwiftData

// MARK: - Dashboard-specific types for upcoming payments interactions

enum UpcomingItemType {
    case loanPayment
    case incomePayment
}

struct UpcomingPaymentItem: Identifiable {
    let id: String // stable key for SwiftUI
    let type: UpcomingItemType
    let title: String
    let counterparty: String?
    let dueDate: Date
    let amount: Double
    let currency: String
    let paymentReference: UUID // payment.id for stable reference
    
    // Optional references (only one will be non-nil)
    let loanPayment: Payment?
    let incomePayment: IncomePayment?
    
    var stableKey: String { id }
    
    init(payment: Payment) {
        self.loanPayment = payment
        self.incomePayment = nil
        self.type = .loanPayment
        self.paymentReference = payment.id
        self.id = "loan-\(payment.id.uuidString)" // prefix for uniqueness
        self.title = payment.loan?.title ?? L10n.string("dashboard_unknown_loan")
        self.counterparty = payment.loan?.counterparty?.name
        self.dueDate = payment.dueDate
        self.amount = payment.amount
        self.currency = payment.loan?.currencyCode ?? "RON"
    }
    
    init(incomePayment: IncomePayment) {
        self.loanPayment = nil
        self.incomePayment = incomePayment
        self.type = .incomePayment
        self.paymentReference = incomePayment.id
        self.id = "income-\(incomePayment.id.uuidString)" // prefix for uniqueness
        self.title = incomePayment.incomeSource?.title ?? L10n.string("dashboard_income_unknown")
        self.counterparty = incomePayment.incomeSource?.counterpartyName
        self.dueDate = incomePayment.dueDate
        self.amount = incomePayment.amount
        self.currency = incomePayment.currencyCode
    }
}

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var loans: [Loan]
    @Query private var payments: [Payment]
    @Query private var incomeSources: [IncomeSource]
    @Query private var incomePayments: [IncomePayment]
    @Query private var expenses: [Expense]
    
    @State private var showToReceiveDetail = false
    @State private var showToPayDetail = false
    @State private var appState = AppState.shared
    
    private var appSettings: AppSettings {
        AppSettings.getOrCreate(in: modelContext)
    }
    
    var body: some View {
        // Show loading state during reset to prevent accessing deleted objects
        if appState.isResetting {
            VStack(spacing: MonetiqTheme.Spacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)
                Text(L10n.string("general_loading"))
                    .font(MonetiqTheme.Typography.body)
                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .monetiqBackground()
        } else {
            mainContent
        }
    }
    
    private var mainContent: some View {
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
                    .onTapGesture {
                        showToReceiveDetail = true
                    }
                    
                    MultiCurrencySummaryCard(
                        title: L10n.string("dashboard_to_pay"),
                        totals: calculateToPayByCurrency(),
                        color: MonetiqTheme.Colors.negative
                    )
                    .onTapGesture {
                        showToPayDetail = true
                    }
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
                            Group {
                                switch item.type {
                                case .loanPayment:
                                    if let loan = item.loanPayment?.loan {
                                        NavigationLink(destination: LoanDetailView(
                                            loan: loan,
                                            focusPaymentId: item.paymentReference
                                        )) {
                                            DashboardPaymentRowContent(paymentItem: item)
                                        }
                                    } else {
                                        DashboardPaymentRowContent(paymentItem: item)
                                    }
                                    
                                case .incomePayment:
                                    // Income payments don't have detail navigation yet
                                    DashboardPaymentRowContent(paymentItem: item)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                            #if !os(macOS)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button {
                                    markPaymentAsPaid(item)
                                } label: {
                                    Label(item.type == .loanPayment ? L10n.string("dashboard_mark_paid") : L10n.string("dashboard_mark_received"), systemImage: "checkmark.circle.fill")
                                }
                                .tint(MonetiqTheme.Colors.success)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                // Only show postpone for loan payments
                                if item.type == .loanPayment {
                                    Button {
                                        postponePayment(item)
                                    } label: {
                                        Label(L10n.string("dashboard_postpone"), systemImage: "clock.arrow.circlepath")
                                    }
                                    .tint(MonetiqTheme.Colors.warning)
                                }
                            }
                            #endif
                            .contextMenu {
                                Button {
                                    markPaymentAsPaid(item)
                                } label: {
                                    Label(item.type == .loanPayment ? L10n.string("dashboard_mark_paid") : L10n.string("dashboard_mark_received"), systemImage: "checkmark.circle.fill")
                                }
                                
                                // Only show postpone for loan payments
                                if item.type == .loanPayment {
                                    Button {
                                        postponePayment(item)
                                    } label: {
                                        Label(L10n.string("dashboard_postpone"), systemImage: "clock.arrow.circlepath")
                                    }
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
                
                // Cashflow Chart - 30 days preview
                // Guard: Pass empty arrays during reset to prevent accessing deleted objects
                CashflowCardView(
                    loans: appState.isResetting ? [] : loans,
                    incomePayments: appState.isResetting ? [] : incomePayments,
                    expenses: appState.isResetting ? [] : expenses,
                    windowDays: 30
                )
                .padding(.horizontal, MonetiqTheme.Spacing.screenPadding)
                
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
        .sheet(isPresented: $showToReceiveDetail) {
            DashboardTotalsDetailView(
                kind: .toReceive,
                loans: loans,
                incomePayments: incomePayments,
                calculateTotals: calculateToReceiveByCurrency
            )
        }
        .sheet(isPresented: $showToPayDetail) {
            DashboardTotalsDetailView(
                kind: .toPay,
                loans: loans,
                incomePayments: incomePayments,
                calculateTotals: calculateToPayByCurrency
            )
        }
    }
    
    /// SOURCE OF TRUTH: Upcoming Payments Logic
    /// Uses filters for consistent filtering across:
    /// 1. Dashboard "Upcoming Payments" section
    /// 2. App icon badge count
    ///
    /// Business Rule: An item is "upcoming" if it's due within the next 15 days.
    /// This is INDEPENDENT of notification settings.
    private var upcomingPayments: [UpcomingPaymentItem] {
        // Don't access payment properties during reset
        guard !appState.isResetting else { return [] }
        
        var items: [UpcomingPaymentItem] = []
        
        // 1. Loan payments
        let upcomingLoanPayments = UpcomingPaymentsFilter.filterUpcomingPayments(from: payments)
        items.append(contentsOf: upcomingLoanPayments.map { UpcomingPaymentItem(payment: $0) })
        
        // 2. Income payments
        let upcomingIncomePayments = IncomeUpcomingFilter.getUpcoming(from: incomePayments)
        items.append(contentsOf: upcomingIncomePayments.map { UpcomingPaymentItem(incomePayment: $0) })
        
        // Sort by due date (ascending)
        return items.sorted { $0.dueDate < $1.dueDate }
    }
    
    private var recentLoans: [Loan] {
        // Don't access loan properties during reset
        guard !appState.isResetting else { return [] }
        return loans.sorted { $0.createdAt > $1.createdAt }
    }
    
    private func calculateToReceiveByCurrency() -> [String: Double] {
        // Don't access loan properties during reset
        guard !appState.isResetting else { return [:] }
        
        var totals: [String: Double] = [:]
        
        // 1. From Loans (lent money)
        let lentLoans = loans.filter { $0.role == .lent }
        for loan in lentLoans {
            let remaining = (loan.totalToRepay ?? loan.principalAmount) - loan.totalPaid
            if remaining > 0 {
                totals[loan.currencyCode, default: 0] += remaining
            }
        }
        
        // 2. From Income (planned income payments)
        // Use the same filtering approach as UpcomingPaymentsFilter for consistency
        let upcomingIncomePayments = IncomeUpcomingFilter.getUpcoming(from: incomePayments)
        for payment in upcomingIncomePayments {
            totals[payment.currencyCode, default: 0] += payment.amount
        }
        
        return totals
    }
    
    private func calculateToPayByCurrency() -> [String: Double] {
        // Don't access loan properties during reset
        guard !appState.isResetting else { return [:] }
        
        var totals: [String: Double] = [:]
        
        // 1. Loans (borrowed + bank credits)
        let borrowedLoans = loans.filter { $0.role == .borrowed || $0.role == .bankCredit }
        for loan in borrowedLoans {
            let remaining = (loan.totalToRepay ?? loan.principalAmount) - loan.totalPaid
            if remaining > 0 {
                totals[loan.currencyCode, default: 0] += remaining
            }
        }
        
        // 2. Expenses (active, next 30 days only - matches Cashflow window)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: 30, to: today)!
        
        #if DEBUG
        var expenseDebugInfo: [(name: String, frequency: String, amount: Double, nextDue: Date?, occurrenceCount: Int, inWindow: Int)] = []
        #endif
        
        for expense in expenses where !expense.isArchived {
            let upcomingInWindow = expense.occurrences
                .filter { $0.status == .planned }
                .filter { $0.dueDate >= today && $0.dueDate <= endDate }
            
            let upcomingTotal = upcomingInWindow.reduce(0) { $0 + $1.amount }
            
            #if DEBUG
            let allUpcoming = expense.upcomingOccurrences.filter { $0.status == .planned }
            expenseDebugInfo.append((
                name: expense.title,
                frequency: expense.frequency.rawValue,
                amount: upcomingTotal,
                nextDue: expense.nextDueDate,
                occurrenceCount: allUpcoming.count,
                inWindow: upcomingInWindow.count
            ))
            #endif
            
            if upcomingTotal > 0 {
                totals[expense.currencyCode, default: 0] += upcomingTotal
            }
        }
        
        #if DEBUG
        print("💰 TO PAY - Expense Summary (30-day window):")
        print("   Total expenses included: \(expenseDebugInfo.count)")
        print("   Window: \(today) to \(endDate)")
        for info in expenseDebugInfo {
            print("   - \(info.name) (\(info.frequency)): \(info.amount) | Next: \(info.nextDue?.description ?? "nil") | In window: \(info.inWindow)/\(info.occurrenceCount)")
        }
        #endif
        
        return totals
    }
    
    // MARK: - Payment Actions
    
    private func markPaymentAsPaid(_ item: UpcomingPaymentItem) {
        switch item.type {
        case .loanPayment:
            guard let payment = item.loanPayment else { return }
            
            // Use the same domain action as in Loan Details (single source of truth)
            payment.markAsPaid()
            payment.loan?.updateTimestamp()
            
            // CONSISTENCY FIX: Trigger full reconciliation to ensure consistency
            Task {
                await NotificationManager.shared.reconcileAllPaymentNotifications(with: loans)
            }
            
        case .incomePayment:
            guard let payment = item.incomePayment else { return }
            
            // Mark income payment as received
            payment.markAsReceived()
            payment.incomeSource?.updateTimestamp()
            
            // TODO: Add notification reconciliation for income when notifications are implemented
        }
        
        // UI will update automatically due to @Query reactivity
        // Row will disappear if payment no longer qualifies as upcoming
    }
    
    private func postponePayment(_ item: UpcomingPaymentItem) {
        // Only loan payments support snooze for now
        // Income payments don't have snooze functionality yet
        guard item.type == .loanPayment, let payment = item.loanPayment else { return }
        
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
    
    private var roleColor: Color {
        switch paymentItem.type {
        case .loanPayment:
            guard let role = paymentItem.loanPayment?.loan?.role else { return MonetiqTheme.Colors.neutral }
            
            switch role {
            case .lent:
                return MonetiqTheme.Colors.positive  // Green - money to receive
            case .borrowed:
                return MonetiqTheme.Colors.negative  // Orange - money to pay
            case .bankCredit:
                return MonetiqTheme.Colors.error     // Red - bank credit
            }
            
        case .incomePayment:
            return MonetiqTheme.Colors.positive  // Green - money to receive (income)
        }
    }
    
    private var daysUntilDue: Int {
        DueDateHelper.daysBetween(from: Date(), to: paymentItem.dueDate)
    }
    
    private var dueDateText: String {
        // Show snooze status if payment is snoozed (loan payments only)
        if paymentItem.type == .loanPayment,
           let payment = paymentItem.loanPayment,
           payment.isReminderSnoozed,
           let snoozeUntil = payment.snoozeUntil {
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
        // Check snooze status (loan payments only)
        if paymentItem.type == .loanPayment,
           let payment = paymentItem.loanPayment,
           payment.isReminderSnoozed {
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
                // Primary title with type badge
                HStack(spacing: MonetiqTheme.Spacing.sm) {
                    Text(paymentItem.title)
                        .monetiqCardTitle()
                        .lineLimit(1)
                    
                    // Type badge (Income only)
                    if paymentItem.type == .incomePayment {
                        Text(L10n.string("dashboard_income_badge"))
                            .font(MonetiqTheme.Typography.caption2)
                            .foregroundColor(MonetiqTheme.Colors.positive)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(MonetiqTheme.Colors.positive.opacity(0.15))
                            )
                    }
                }
                
                // Secondary info - Better visual separation
                HStack(spacing: MonetiqTheme.Spacing.sm) {
                    if let counterparty = paymentItem.counterparty {
                        Text(counterparty)
                            .monetiqCardSubtitle()
                            .lineLimit(1)
                    }
                    
                    if paymentItem.counterparty != nil {
                        Text("•")
                            .font(MonetiqTheme.Typography.caption2)
                            .foregroundColor(MonetiqTheme.Colors.textTertiary)
                            .opacity(0.6)
                    }
                    
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

// MARK: - Dashboard Totals Detail View

enum DashboardTotalsKind {
    case toReceive
    case toPay
    
    var title: String {
        switch self {
        case .toReceive:
            return L10n.string("dashboard_to_receive_detail_title")
        case .toPay:
            return L10n.string("dashboard_to_pay_detail_title")
        }
    }
    
    var color: Color {
        switch self {
        case .toReceive:
            return MonetiqTheme.Colors.positive
        case .toPay:
            return MonetiqTheme.Colors.negative
        }
    }
    
    var loanRole: [LoanRole] {
        switch self {
        case .toReceive:
            return [.lent]
        case .toPay:
            return [.borrowed, .bankCredit]
        }
    }
}

struct DashboardTotalsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    let kind: DashboardTotalsKind
    let loans: [Loan]
    let incomePayments: [IncomePayment]
    let calculateTotals: () -> [String: Double]
    
    private var filteredLoans: [Loan] {
        loans.filter { kind.loanRole.contains($0.role) }
            .filter { loan in
                let remaining = (loan.totalToRepay ?? loan.principalAmount) - loan.totalPaid
                return remaining > 0
            }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    private var filteredIncomePayments: [IncomePayment] {
        // Only show income for "To Receive"
        guard kind == .toReceive else { return [] }
        return IncomeUpcomingFilter.getUpcoming(from: incomePayments)
    }
    
    private var sourcesLabel: String {
        switch kind {
        case .toReceive:
            return L10n.string("dashboard_detail_from_loans_and_income")
        case .toPay:
            return L10n.string("dashboard_detail_from_loans_and_expenses")
        }
    }
    
    private var totals: [String: Double] {
        calculateTotals()
    }
    
    private var sortedTotals: [(String, Double)] {
        totals.sorted { $0.value > $1.value }
    }
    
    private var isEmpty: Bool {
        // Empty only if BOTH loans and income are empty
        filteredLoans.isEmpty && filteredIncomePayments.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MonetiqTheme.Spacing.lg) {
                    if isEmpty {
                        // Empty state - shown only when both loans and income are empty
                        VStack(spacing: MonetiqTheme.Spacing.lg) {
                            Spacer()
                                .frame(height: 60)
                            
                            Image(systemName: "tray")
                                .font(.system(size: 48, weight: .light))
                                .foregroundColor(MonetiqTheme.Colors.textTertiary)
                            
                            VStack(spacing: MonetiqTheme.Spacing.xs) {
                                Text(L10n.string("dashboard_detail_empty_state"))
                                    .font(MonetiqTheme.Typography.body)
                                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(MonetiqTheme.Spacing.lg)
                    } else {
                        // Totals Summary Card
                        VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                            Text(L10n.string("dashboard_detail_total"))
                                .font(MonetiqTheme.Typography.caption)
                                .foregroundColor(MonetiqTheme.Colors.textSecondary)
                                .textCase(.uppercase)
                                .tracking(0.8)
                            
                            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
                                ForEach(sortedTotals, id: \.0) { currency, amount in
                                    HStack {
                                        Text(CurrencyFormatter.shared.format(amount: amount, currencyCode: currency))
                                            .font(sortedTotals.count == 1 ? MonetiqTheme.Typography.currencyLarge : MonetiqTheme.Typography.currencyMedium)
                                            .foregroundColor(kind.color)
                                            .fontWeight(.bold)
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .monetiqPremiumCard()
                        .padding(.horizontal, MonetiqTheme.Spacing.screenPadding)
                        
                        // Loans Breakdown
                        if !filteredLoans.isEmpty {
                            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                                Text(sourcesLabel)
                                    .font(MonetiqTheme.Typography.caption)
                                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
                                    .textCase(.uppercase)
                                    .tracking(0.8)
                                    .padding(.horizontal, MonetiqTheme.Spacing.screenPadding)
                                
                                VStack(spacing: MonetiqTheme.Spacing.sm) {
                                    ForEach(filteredLoans, id: \.id) { loan in
                                        LoanBreakdownRow(loan: loan, color: kind.color)
                                    }
                                }
                                .padding(.horizontal, MonetiqTheme.Spacing.screenPadding)
                            }
                        }
                        
                        // Income Breakdown (only for "To Receive")
                        if !filteredIncomePayments.isEmpty {
                            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                                Text(L10n.string("dashboard_detail_from_income"))
                                    .font(MonetiqTheme.Typography.caption)
                                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
                                    .textCase(.uppercase)
                                    .tracking(0.8)
                                    .padding(.horizontal, MonetiqTheme.Spacing.screenPadding)
                                
                                VStack(spacing: MonetiqTheme.Spacing.sm) {
                                    ForEach(filteredIncomePayments, id: \.id) { payment in
                                        IncomeBreakdownRow(payment: payment, color: kind.color)
                                    }
                                }
                                .padding(.horizontal, MonetiqTheme.Spacing.screenPadding)
                            }
                        }
                    }
                }
                .padding(.vertical, MonetiqTheme.Spacing.md)
            }
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.medium))
                            .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    }
                }
            }
            .monetiqBackground()
        }
    }
}

struct LoanBreakdownRow: View {
    let loan: Loan
    let color: Color
    
    private var remaining: Double {
        (loan.totalToRepay ?? loan.principalAmount) - loan.totalPaid
    }
    
    var body: some View {
        VStack(spacing: MonetiqTheme.Spacing.sm) {
            HStack(spacing: MonetiqTheme.Spacing.md) {
                // Loan info
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                    Text(loan.title)
                        .font(MonetiqTheme.Typography.bodyEmphasized)
                        .foregroundColor(MonetiqTheme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    if let counterparty = loan.counterparty {
                        HStack(spacing: MonetiqTheme.Spacing.xs) {
                            Image(systemName: counterparty.type == .person ? "person.fill" : "building.fill")
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
                
                // Remaining amount
                VStack(alignment: .trailing, spacing: MonetiqTheme.Spacing.xs) {
                    Text(CurrencyFormatter.shared.format(amount: remaining, currencyCode: loan.currencyCode))
                        .font(MonetiqTheme.Typography.currencySmall)
                        .foregroundColor(color)
                        .fontWeight(.semibold)
                    
                    // Progress indicator
                    if loan.totalToRepay ?? loan.principalAmount > 0 {
                        let progress = loan.totalPaid / (loan.totalToRepay ?? loan.principalAmount)
                        Text("\(Int(progress * 100))%")
                            .font(MonetiqTheme.Typography.caption2)
                            .foregroundColor(MonetiqTheme.Colors.textTertiary)
                    }
                }
            }
            
            // Progress bar
            if loan.totalToRepay ?? loan.principalAmount > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 2)
                            .fill(MonetiqTheme.Colors.surface)
                            .frame(height: 4)
                        
                        // Progress
                        let progress = loan.totalPaid / (loan.totalToRepay ?? loan.principalAmount)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color.opacity(0.3))
                            .frame(width: geometry.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .monetiqPremiumCard()
    }
}

struct IncomeBreakdownRow: View {
    let payment: IncomePayment
    let color: Color
    
    private var daysUntilDue: Int {
        DueDateHelper.daysBetween(from: Date(), to: payment.dueDate)
    }
    
    private var dueDateText: String {
        if daysUntilDue == 0 {
            return L10n.string("payment_due_today")
        } else if daysUntilDue == 1 {
            return L10n.string("payment_due_tomorrow")
        } else if daysUntilDue > 1 {
            return L10n.string("payment_due_in_days", daysUntilDue)
        } else {
            return payment.dueDate.formatted(date: .abbreviated, time: .omitted)
        }
    }
    
    var body: some View {
        HStack(spacing: MonetiqTheme.Spacing.md) {
            // Income info
            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                Text(payment.incomeSource?.title ?? L10n.string("dashboard_income_unknown"))
                    .font(MonetiqTheme.Typography.bodyEmphasized)
                    .foregroundColor(MonetiqTheme.Colors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: MonetiqTheme.Spacing.xs) {
                    Image(systemName: "calendar")
                        .font(MonetiqTheme.Typography.caption)
                        .foregroundColor(MonetiqTheme.Colors.textTertiary)
                    
                    Text(dueDateText)
                        .font(MonetiqTheme.Typography.caption)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                // Counterparty if available
                if let counterparty = payment.incomeSource?.counterpartyName {
                    HStack(spacing: MonetiqTheme.Spacing.xs) {
                        Image(systemName: "person.fill")
                            .font(MonetiqTheme.Typography.caption)
                            .foregroundColor(MonetiqTheme.Colors.textTertiary)
                        
                        Text(counterparty)
                            .font(MonetiqTheme.Typography.caption)
                            .foregroundColor(MonetiqTheme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Amount
            Text(CurrencyFormatter.shared.format(amount: payment.amount, currencyCode: payment.currencyCode))
                .font(MonetiqTheme.Typography.currencySmall)
                .foregroundColor(color)
                .fontWeight(.semibold)
        }
        .monetiqPremiumCard()
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Counterparty.self, Loan.self, Payment.self], inMemory: true)
}
