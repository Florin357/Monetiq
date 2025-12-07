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
    
    let loan: Loan
    @State private var showingEditLoan = false
    @State private var showingDeleteAlert = false
    
    private var notificationManager: NotificationManager {
        NotificationManager.shared
    }
    
    private var sortedPayments: [Payment] {
        loan.payments.sorted { $0.dueDate < $1.dueDate }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: MonetiqTheme.Spacing.lg) {
                // Header Card
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
                            Text(loan.title)
                                .font(MonetiqTheme.Typography.title)
                                .foregroundColor(MonetiqTheme.Colors.onSurface)
                            
                            Text(loan.role.displayName)
                                .font(MonetiqTheme.Typography.callout)
                                .foregroundColor(roleColor(for: loan.role))
                                .padding(.horizontal, MonetiqTheme.Spacing.md)
                                .padding(.vertical, MonetiqTheme.Spacing.sm)
                                .background(roleColor(for: loan.role).opacity(0.2))
                                .cornerRadius(MonetiqTheme.CornerRadius.md)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: MonetiqTheme.Spacing.xs) {
                            Text(String(format: "%.2f", loan.principalAmount))
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
                    Text("Details")
                        .font(MonetiqTheme.Typography.headline)
                        .foregroundColor(MonetiqTheme.Colors.onSurface)
                    
                    VStack(spacing: MonetiqTheme.Spacing.md) {
                        DetailRow(title: "Start Date", value: loan.startDate.formatted(date: .abbreviated, time: .omitted))
                        DetailRow(title: "Payment Frequency", value: loan.frequency.displayName)
                        DetailRow(title: "Number of Payments", value: String(loan.numberOfPeriods))
                        DetailRow(title: "Interest Mode", value: loan.interestMode.displayName)
                        
                        if let rate = loan.annualInterestRate {
                            DetailRow(title: "Annual Interest Rate", value: String(format: "%.2f%%", rate))
                        }
                        
                        if let totalToRepay = loan.totalToRepay {
                            DetailRow(title: "Total to Repay", value: String(format: "%.2f %@", totalToRepay, loan.currencyCode))
                        }
                        
                        DetailRow(title: "Total Paid", value: String(format: "%.2f %@", loan.totalPaid, loan.currencyCode))
                        DetailRow(title: "Remaining", value: String(format: "%.2f %@", loan.remainingToPay, loan.currencyCode))
                        
                        if let nextDueDate = loan.nextDueDate {
                            DetailRow(title: "Next Due Date", value: nextDueDate.formatted(date: .abbreviated, time: .omitted))
                        }
                        
                        DetailRow(title: "Created", value: loan.createdAt.formatted(date: .abbreviated, time: .shortened))
                        
                        if loan.updatedAt != loan.createdAt {
                            DetailRow(title: "Last Updated", value: loan.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                }
                .monetiqCard()
                .padding(.horizontal, MonetiqTheme.Spacing.md)
                
                // Payment Schedule Section
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                    Text("Payment Schedule")
                        .font(MonetiqTheme.Typography.headline)
                        .foregroundColor(MonetiqTheme.Colors.onSurface)
                    
                    if loan.payments.isEmpty {
                        Text("No payment schedule available")
                            .font(MonetiqTheme.Typography.body)
                            .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    } else {
                        LazyVStack(spacing: MonetiqTheme.Spacing.sm) {
                            ForEach(sortedPayments, id: \.id) { payment in
                                PaymentRowView(payment: payment) {
                                    markPaymentAsPaid(payment)
                                }
                            }
                        }
                    }
                }
                .monetiqCard()
                .padding(.horizontal, MonetiqTheme.Spacing.md)
                
                // Counterparty Section
                if let counterparty = loan.counterparty {
                    VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                        Text("Counterparty")
                            .font(MonetiqTheme.Typography.headline)
                            .foregroundColor(MonetiqTheme.Colors.onSurface)
                        
                        HStack {
                            Image(systemName: counterparty.type == .person ? "person.fill" : "building.fill")
                                .foregroundColor(MonetiqTheme.Colors.accent)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                                Text(counterparty.name)
                                    .font(MonetiqTheme.Typography.body)
                                    .foregroundColor(MonetiqTheme.Colors.onSurface)
                                
                                Text(counterparty.type.displayName)
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
                        Text("Notes")
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
        .monetiqBackground()
        .navigationTitle("Loan Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditLoan = true }) {
                        Label("Edit Loan", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete Loan", systemImage: "trash")
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
            Text("Are you sure you want to delete '\(loan.title)'? This action cannot be undone.")
        }
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
        }
        
        modelContext.delete(loan)
        dismiss()
    }
    
    private func markPaymentAsPaid(_ payment: Payment) {
        payment.markAsPaid()
        loan.updateTimestamp()
        
        // Cancel notifications for this specific payment
        Task {
            await notificationManager.cancelNotifications(for: payment)
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(MonetiqTheme.Typography.body)
                .foregroundColor(MonetiqTheme.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(MonetiqTheme.Typography.body)
                .foregroundColor(MonetiqTheme.Colors.onSurface)
        }
    }
}

struct PaymentRowView: View {
    let payment: Payment
    let onMarkAsPaid: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                Text(payment.dueDate.formatted(date: .abbreviated, time: .omitted))
                    .font(MonetiqTheme.Typography.body)
                    .foregroundColor(MonetiqTheme.Colors.onSurface)
                
                Text(statusText)
                    .font(MonetiqTheme.Typography.caption)
                    .foregroundColor(statusColor)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: MonetiqTheme.Spacing.xs) {
                Text(String(format: "%.2f %@", payment.amount, payment.loan?.currencyCode ?? "RON"))
                    .font(MonetiqTheme.Typography.callout)
                    .foregroundColor(MonetiqTheme.Colors.accent)
                    .fontWeight(.medium)
                
                if payment.status == .planned && !payment.isOverdue {
                    Button("Mark Paid") {
                        onMarkAsPaid()
                    }
                    .font(MonetiqTheme.Typography.caption)
                    .foregroundColor(MonetiqTheme.Colors.success)
                }
            }
        }
        .padding(MonetiqTheme.Spacing.sm)
        .background(payment.status == .paid ? MonetiqTheme.Colors.success.opacity(0.1) : 
                   payment.isOverdue ? MonetiqTheme.Colors.error.opacity(0.1) : 
                   MonetiqTheme.Colors.surface)
        .cornerRadius(MonetiqTheme.CornerRadius.sm)
    }
    
    private var statusText: String {
        switch payment.status {
        case .paid:
            if let paidDate = payment.paidDate {
                return "Paid on \(paidDate.formatted(date: .abbreviated, time: .omitted))"
            }
            return "Paid"
        case .planned:
            return payment.isOverdue ? "Overdue" : "Planned"
        case .overdue:
            return "Overdue"
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
