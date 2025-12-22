//
//  LoanDetailView.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import SwiftUI
import SwiftData

struct LoanDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allPayments: [Payment]  // For badge count calculation
    
    let loan: Loan
    let focusPaymentId: UUID? // Optional payment to focus on
    let focusDueDate: Date? // Alternative: focus by due date
    
    @State private var showingEditLoan = false
    @State private var showingDeleteAlert = false
    @State private var highlightedPaymentId: UUID? // For brief highlighting
    
    private var notificationManager: NotificationManager {
        NotificationManager.shared
    }
    
    private var sortedPayments: [Payment] {
        loan.payments.sorted { $0.dueDate < $1.dueDate }
    }
    
    // Check if loan has auto-marked paid payments (existing loan enrollment)
    private var hasAutoMarkedPayments: Bool {
        // If the loan was created recently (within last minute) and has paid payments
        // that were paid on their due date, it's likely an existing loan enrollment
        let recentlyCreated = Date().timeIntervalSince(loan.createdAt) < 60
        let hasPaidPayments = loan.payments.contains { $0.status == .paid }
        let hasPaidOnDueDate = loan.payments.contains { payment in
            payment.status == .paid && payment.paidDate != nil &&
            Calendar.current.isDate(payment.paidDate!, inSameDayAs: payment.dueDate)
        }
        return recentlyCreated && hasPaidPayments && hasPaidOnDueDate
    }
    
    // MARK: - Initializers
    
    init(loan: Loan, focusPaymentId: UUID? = nil, focusDueDate: Date? = nil) {
        self.loan = loan
        self.focusPaymentId = focusPaymentId
        self.focusDueDate = focusDueDate
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                mainContent
                    .onAppear {
                        scrollToFocusedPayment(proxy: proxy)
                    }
            }
        }
        .monetiqBackground()
        .navigationTitle(L10n.string("loan_details_nav_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditLoan = true }) {
                        Label(L10n.string("edit_loan_button"), systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label(L10n.string("delete_loan_button"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(MonetiqTheme.Colors.accent)
                }
            }
        }
        .sheet(isPresented: $showingEditLoan) {
            AddEditLoanView(loan: loan)
        }
        .alert("Delete Loan", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteLoan()
            }
        } message: {
            Text(L10n.string("loan_detail_delete_confirm", loan.title))
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: MonetiqTheme.Spacing.lg) {
                // Header Card
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
                            Text(loan.title)
                                .font(MonetiqTheme.Typography.title)
                                .foregroundColor(MonetiqTheme.Colors.onSurface)
                            
                            Text(loan.role.localizedLabel)
                                .font(MonetiqTheme.Typography.callout)
                                .foregroundColor(roleColor(for: loan.role))
                                .padding(.horizontal, MonetiqTheme.Spacing.md)
                                .padding(.vertical, MonetiqTheme.Spacing.sm)
                                .background(roleColor(for: loan.role).opacity(0.2))
                                .cornerRadius(MonetiqTheme.CornerRadius.md)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: MonetiqTheme.Spacing.xs) {
                            Text(CurrencyFormatter.shared.formatAmount(loan.principalAmount))
                                .font(MonetiqTheme.Typography.title2)
                                .foregroundColor(MonetiqTheme.Colors.accent)
                                .fontWeight(.semibold)
                            
                            Text(loan.currencyCode)
                                .font(MonetiqTheme.Typography.callout)
                                .foregroundColor(MonetiqTheme.Colors.textSecondary)
                        }
                    }
                }
                .monetiqCard()
                .padding(.horizontal, MonetiqTheme.Spacing.md)
                
                // Details Section
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                    Text(L10n.string("loan_detail_details"))
                        .font(MonetiqTheme.Typography.headline)
                        .foregroundColor(MonetiqTheme.Colors.onSurface)
                    
                    VStack(spacing: MonetiqTheme.Spacing.md) {
                        DetailRow(title: L10n.string("loan_detail_start_date"), value: loan.startDate.formatted(date: .abbreviated, time: .omitted))
                        DetailRow(title: L10n.string("loan_detail_payment_frequency"), value: loan.frequency.localizedLabel)
                        DetailRow(title: L10n.string("loan_detail_number_of_payments"), value: String(loan.numberOfPeriods))
                        DetailRow(title: L10n.string("loan_detail_interest_mode"), value: loan.interestMode.localizedLabel)
                        
                        if let rate = loan.annualInterestRate {
                            DetailRow(title: L10n.string("loan_detail_annual_interest_rate"), value: "\(CurrencyFormatter.shared.formatAmount(rate))%")
                        }
                        
                        if let totalToRepay = loan.totalToRepay {
                            DetailRow(title: L10n.string("loan_detail_total_to_repay"), value: CurrencyFormatter.shared.format(amount: totalToRepay, currencyCode: loan.currencyCode))
                        }
                        
                        // Payment Progress Indicator
                        PaymentProgressRow(
                            totalPaid: loan.totalPaid,
                            remaining: loan.remainingToPay,
                            currencyCode: loan.currencyCode
                        )
                        
                        DetailRow(title: L10n.string("loan_detail_total_paid"), value: CurrencyFormatter.shared.format(amount: loan.totalPaid, currencyCode: loan.currencyCode), valueColor: loan.totalPaid > 0 ? MonetiqTheme.Colors.success : MonetiqTheme.Colors.error)
                        DetailRow(title: L10n.string("loan_detail_remaining"), value: CurrencyFormatter.shared.format(amount: loan.remainingToPay, currencyCode: loan.currencyCode))
                        
                        if let nextDueDate = loan.nextDueDate {
                            DetailRow(title: L10n.string("loan_detail_next_due_date"), value: nextDueDate.formatted(date: .abbreviated, time: .omitted))
                        }
                        
                        DetailRow(title: L10n.string("loan_detail_created"), value: loan.createdAt.formatted(date: .abbreviated, time: .shortened))
                        
                        if loan.updatedAt != loan.createdAt {
                            DetailRow(title: L10n.string("loan_detail_last_updated"), value: loan.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                }
                .monetiqCard()
                .padding(.horizontal, MonetiqTheme.Spacing.md)
                
                // Payment Schedule Section - Premium styling
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.lg) {
                    HStack {
                        Text(L10n.string("loan_detail_payments"))
                            .monetiqSectionHeader()
                        
                        Spacer()
                        
                        if !loan.payments.isEmpty {
                            Text("\(loan.payments.count)")
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
                    
                    if loan.payments.isEmpty {
                        Text(L10n.string("loan_detail_no_schedule"))
                            .font(MonetiqTheme.Typography.body)
                            .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    } else {
                        // Show info message if there are auto-marked paid payments
                        if hasAutoMarkedPayments {
                            HStack(alignment: .top, spacing: MonetiqTheme.Spacing.sm) {
                                Image(systemName: "info.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(MonetiqTheme.Colors.accent)
                                
                                Text(L10n.string("loan_detail_auto_marked_info"))
                                    .font(MonetiqTheme.Typography.caption)
                                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(MonetiqTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: MonetiqTheme.CornerRadius.sm)
                                    .fill(MonetiqTheme.Colors.accent.opacity(0.1))
                            )
                        }
                        
                        LazyVStack(spacing: MonetiqTheme.Spacing.sm) {
                            ForEach(sortedPayments, id: \.id) { payment in
                                PaymentRowView(
                                    payment: payment,
                                    isHighlighted: highlightedPaymentId == payment.id
                                ) {
                                    markPaymentAsPaid(payment)
                                }
                                .id("payment-\(payment.id)")
                            }
                        }
                    }
                }
                .monetiqCard()
                .padding(.horizontal, MonetiqTheme.Spacing.md)
                
                // Counterparty Section
                if let counterparty = loan.counterparty {
                    VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                        Text(L10n.string("loan_detail_counterparty"))
                            .font(MonetiqTheme.Typography.headline)
                            .foregroundColor(MonetiqTheme.Colors.onSurface)
                        
                        HStack {
                            Image(systemName: counterparty.type == .person ? "person.fill" : "building.fill")
                                .foregroundColor(MonetiqTheme.Colors.accent)
                                .font(MonetiqTheme.Typography.title2)
                            
                            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                                Text(counterparty.name)
                                    .font(MonetiqTheme.Typography.body)
                                    .foregroundColor(MonetiqTheme.Colors.onSurface)
                                
                                Text(counterparty.type.localizedLabel)
                                    .font(MonetiqTheme.Typography.caption)
                                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
                            }
                            
                            Spacer()
                        }
                        
                        if let notes = counterparty.notes, !notes.isEmpty {
                            Text(notes)
                                .font(MonetiqTheme.Typography.caption)
                                .foregroundColor(MonetiqTheme.Colors.textSecondary)
                                .padding(.top, MonetiqTheme.Spacing.xs)
                        }
                    }
                    .monetiqCard()
                    .padding(.horizontal, MonetiqTheme.Spacing.md)
                }
                
                // Notes Section
                if let notes = loan.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                        Text(L10n.string("loan_detail_notes"))
                            .font(MonetiqTheme.Typography.headline)
                            .foregroundColor(MonetiqTheme.Colors.onSurface)
                        
                        Text(notes)
                            .font(MonetiqTheme.Typography.body)
                            .foregroundColor(MonetiqTheme.Colors.onSurface)
                    }
                    .monetiqCard()
                    .padding(.horizontal, MonetiqTheme.Spacing.md)
                }
                
                Spacer(minLength: MonetiqTheme.Spacing.xl)
        }
        .padding(.vertical, MonetiqTheme.Spacing.lg)
    }
    
    private func roleColor(for role: LoanRole) -> Color {
        switch role {
        case .lent:
            return MonetiqTheme.Colors.success
        case .borrowed:
            return MonetiqTheme.Colors.warning
        case .bankCredit:
            return MonetiqTheme.Colors.error
        }
    }
    
    private func deleteLoan() {
        // Cancel notifications for this loan before deletion
        Task {
            await notificationManager.cancelNotifications(for: loan)
            await notificationManager.updateBadgeCount(payments: allPayments)
        }
        
        modelContext.delete(loan)
        dismiss()
    }
    
    private func markPaymentAsPaid(_ payment: Payment) {
        payment.markAsPaid()
        loan.updateTimestamp()
        
        // Cancel notifications for this specific payment and update badge count
        Task {
            await notificationManager.cancelNotifications(for: payment)
            await notificationManager.updateBadgeCount(payments: allPayments)
        }
    }
    
    private func scrollToFocusedPayment(proxy: ScrollViewProxy) {
        // Determine which payment to focus on
        var targetPaymentId: UUID?
        
        if let focusPaymentId = focusPaymentId {
            targetPaymentId = focusPaymentId
        } else if let focusDueDate = focusDueDate {
            // Find payment by due date if ID is not provided
            targetPaymentId = sortedPayments.first(where: {
                Calendar.current.isDate($0.dueDate, inSameDayAs: focusDueDate)
            })?.id
        }
        
        if let targetId = targetPaymentId {
            if let payment = sortedPayments.first(where: { $0.id == targetId }) {
                withAnimation {
                    proxy.scrollTo("payment-\(payment.id)", anchor: UnitPoint.center)
                    highlightedPaymentId = payment.id // Set for highlighting
                }
                // Remove highlight after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        highlightedPaymentId = nil
                    }
                }
            } else {
                // Fallback if specific payment not found (e.g., edited loan)
                if let nearestUpcoming = sortedPayments.first(where: { $0.status == .planned }) {
                    withAnimation {
                        proxy.scrollTo("payment-\(nearestUpcoming.id)", anchor: UnitPoint.center)
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    var valueColor: Color? = nil
    
    var body: some View {
        HStack {
            Text(title)
                .font(MonetiqTheme.Typography.body)
                .foregroundColor(MonetiqTheme.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(MonetiqTheme.Typography.body)
                .foregroundColor(valueColor ?? MonetiqTheme.Colors.onSurface)
                .fontWeight(valueColor != nil ? .semibold : .regular)
        }
    }
}

struct PaymentProgressRow: View {
    let totalPaid: Double
    let remaining: Double
    let currencyCode: String
    
    private var totalAmount: Double {
        totalPaid + remaining
    }
    
    private var progressPercentage: Double {
        guard totalAmount > 0 else { return 0 }
        return (totalPaid / totalAmount) * 100
    }
    
    private var statusColor: Color {
        if totalPaid > 0 {
            return MonetiqTheme.Colors.success
        } else {
            return MonetiqTheme.Colors.error
        }
    }
    
    private var statusText: String {
        if totalPaid > 0 {
            // Pass the percentage value directly to L10n.string for proper formatting
            return L10n.string("loan_detail_progress_paid", progressPercentage)
        } else {
            return L10n.string("loan_detail_progress_no_payments")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
            HStack {
                Text(L10n.string("loan_detail_progress"))
                    .font(MonetiqTheme.Typography.body)
                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
                
                Spacer()
                
                Text(statusText)
                    .font(MonetiqTheme.Typography.caption)
                    .foregroundColor(statusColor)
                    .fontWeight(.semibold)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(MonetiqTheme.Colors.surface.opacity(0.3))
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(statusColor)
                        .frame(width: geometry.size.width * CGFloat(progressPercentage / 100), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, MonetiqTheme.Spacing.xs)
    }
}

struct PaymentRowView: View {
    let payment: Payment
    let isHighlighted: Bool
    let onMarkAsPaid: () -> Void
    
    init(payment: Payment, isHighlighted: Bool = false, onMarkAsPaid: @escaping () -> Void) {
        self.payment = payment
        self.isHighlighted = isHighlighted
        self.onMarkAsPaid = onMarkAsPaid
    }
    
    var body: some View {
        HStack(spacing: MonetiqTheme.Spacing.lg) {
            // Status indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(statusColor)
                .frame(width: 5, height: 45)
            
            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
                // Date - Enhanced hierarchy
                Text(payment.dueDate.formatted(date: .abbreviated, time: .omitted))
                    .monetiqCardTitle()
                
                // Status - Premium badge styling
                Text(statusText)
                    .font(MonetiqTheme.Typography.caption)
                    .foregroundColor(statusColor)
                    .fontWeight(.medium)
                    .padding(.horizontal, MonetiqTheme.Spacing.sm)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.15))
                    )
            }
            
            Spacer(minLength: 12)
            
            VStack(alignment: .trailing, spacing: MonetiqTheme.Spacing.xs) {
                // Amount - Premium currency display
                Text(CurrencyFormatter.shared.format(amount: payment.amount, currencyCode: payment.loan?.currencyCode ?? "RON"))
                    .font(MonetiqTheme.Typography.currencySmall)
                    .foregroundColor(MonetiqTheme.Colors.textPrimary)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .minimumScaleFactor(0.85)
                    .layoutPriority(1)
                
                if payment.status == .planned && !payment.isOverdue {
                    Button(L10n.string("mark_paid_button")) {
                        onMarkAsPaid()
                    }
                    .font(MonetiqTheme.Typography.caption)
                    .foregroundColor(MonetiqTheme.Colors.success)
                    .fontWeight(.medium)
                    .padding(.horizontal, MonetiqTheme.Spacing.sm)
                    .padding(.vertical, MonetiqTheme.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(MonetiqTheme.Colors.success.opacity(0.1))
                    )
                }
            }
        }
        .padding(.horizontal, MonetiqTheme.Spacing.lg)
        .padding(.vertical, MonetiqTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MonetiqTheme.CornerRadius.card)
                .fill(backgroundColorForPayment)
                .shadow(
                    color: isHighlighted ? MonetiqTheme.Shadow.cardElevated : MonetiqTheme.Shadow.card,
                    radius: isHighlighted ? 6 : 3,
                    x: 0,
                    y: isHighlighted ? 3 : 1
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: MonetiqTheme.CornerRadius.card)
                .stroke(
                    isHighlighted ? MonetiqTheme.Colors.accent.opacity(0.3) : Color.clear,
                    lineWidth: isHighlighted ? 2 : 0
                )
        )
    }
    
    private var statusText: String {
        switch payment.status {
        case .paid:
            if let paidDate = payment.paidDate {
                return L10n.string("status_paid_on", paidDate.formatted(date: .abbreviated, time: .omitted))
            }
            return L10n.string("status_paid")
        case .planned:
            return payment.isOverdue ? L10n.string("status_overdue") : L10n.string("status_planned")
        case .overdue:
            return L10n.string("status_overdue")
        }
    }
    
    private var statusColor: Color {
        switch payment.status {
        case .paid:
            return MonetiqTheme.Colors.success
        case .planned:
            return payment.isOverdue ? MonetiqTheme.Colors.error : MonetiqTheme.Colors.textSecondary
        case .overdue:
            return MonetiqTheme.Colors.error
        }
    }
    
    private var backgroundColorForPayment: Color {
        if isHighlighted {
            return MonetiqTheme.Colors.accent.opacity(0.08)
        } else if payment.status == .paid {
            return MonetiqTheme.Colors.success.opacity(0.05)
        } else if payment.isOverdue {
            return MonetiqTheme.Colors.error.opacity(0.05)
        } else {
            return MonetiqTheme.Colors.surface
        }
    }
}

#Preview {
    let loan = Loan(
        title: "Sample Loan",
        role: .lent,
        principalAmount: 5000.0,
        currencyCode: "RON",
        startDate: Date(),
        notes: "This is a sample loan for preview"
    )
    
    NavigationStack {
        LoanDetailView(loan: loan)
    }
    .modelContainer(for: [Counterparty.self, Loan.self, Payment.self], inMemory: true)
}
