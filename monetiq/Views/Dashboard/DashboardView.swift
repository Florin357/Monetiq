//
//  DashboardView.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var loans: [Loan]
    @Query private var payments: [Payment]
    
    var body: some View {
        ScrollView {
            VStack(spacing: MonetiqTheme.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
                    Text("Dashboard")
                        .font(MonetiqTheme.Typography.largeTitle)
                        .foregroundColor(MonetiqTheme.Colors.onBackground)
                    
                    Text("Financial Overview")
                        .font(MonetiqTheme.Typography.callout)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, MonetiqTheme.Spacing.md)
                
                // Summary Cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: MonetiqTheme.Spacing.md) {
                    SummaryCard(
                        title: "To Receive",
                        amount: calculateToReceive(),
                        currency: "RON",
                        color: MonetiqTheme.Colors.success
                    )
                    
                    SummaryCard(
                        title: "To Pay",
                        amount: calculateToPay(),
                        currency: "RON",
                        color: MonetiqTheme.Colors.warning
                    )
                }
                .padding(.horizontal, MonetiqTheme.Spacing.md)
                
                // Upcoming Payments
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                    Text("Upcoming Payments")
                        .font(MonetiqTheme.Typography.headline)
                        .foregroundColor(MonetiqTheme.Colors.onBackground)
                        .padding(.horizontal, MonetiqTheme.Spacing.md)
                    
                    if upcomingPayments.isEmpty {
                        Text("No upcoming payments")
                            .font(MonetiqTheme.Typography.body)
                            .foregroundColor(MonetiqTheme.Colors.textSecondary)
                            .padding(.horizontal, MonetiqTheme.Spacing.md)
                    } else {
                        LazyVStack(spacing: MonetiqTheme.Spacing.sm) {
                            ForEach(upcomingPayments.prefix(5), id: \.id) { payment in
                                DashboardPaymentRowView(payment: payment)
                            }
                        }
                        .padding(.horizontal, MonetiqTheme.Spacing.md)
                    }
                }
                
                // Recent Loans
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                    Text("Recent Loans")
                        .font(MonetiqTheme.Typography.headline)
                        .foregroundColor(MonetiqTheme.Colors.onBackground)
                        .padding(.horizontal, MonetiqTheme.Spacing.md)
                    
                    if recentLoans.isEmpty {
                        Text("No loans yet")
                            .font(MonetiqTheme.Typography.body)
                            .foregroundColor(MonetiqTheme.Colors.textSecondary)
                            .padding(.horizontal, MonetiqTheme.Spacing.md)
                    } else {
                        LazyVStack(spacing: MonetiqTheme.Spacing.sm) {
                            ForEach(recentLoans.prefix(3), id: \.id) { loan in
                                DashboardLoanRowView(loan: loan)
                            }
                        }
                        .padding(.horizontal, MonetiqTheme.Spacing.md)
                    }
                }
            }
            .padding(.vertical, MonetiqTheme.Spacing.lg)
        }
        .monetiqBackground()
    }
    
    private var upcomingPayments: [Payment] {
        payments
            .filter { $0.status == .planned && $0.dueDate >= Date() }
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    private var recentLoans: [Loan] {
        loans.sorted { $0.createdAt > $1.createdAt }
    }
    
    private func calculateToReceive() -> Double {
        let lentLoans = loans.filter { $0.role == .lent }
        return lentLoans.reduce(0) { total, loan in
            total + (loan.totalToRepay ?? loan.principalAmount) - loan.totalPaid
        }
    }
    
    private func calculateToPay() -> Double {
        let borrowedLoans = loans.filter { $0.role == .borrowed || $0.role == .bankCredit }
        return borrowedLoans.reduce(0) { total, loan in
            total + (loan.totalToRepay ?? loan.principalAmount) - loan.totalPaid
        }
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
            
            Text(String(format: "%.2f %@", amount, currency))
                .font(MonetiqTheme.Typography.title2)
                .foregroundColor(color)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .monetiqCard()
    }
}

struct DashboardPaymentRowView: View {
    let payment: Payment
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                Text(payment.loan?.title ?? "Unknown Loan")
                    .font(MonetiqTheme.Typography.body)
                    .foregroundColor(MonetiqTheme.Colors.onSurface)
                
                if let counterparty = payment.loan?.counterparty {
                    Text(counterparty.name)
                        .font(MonetiqTheme.Typography.caption)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                }
                
                Text(payment.dueDate.formatted(date: .abbreviated, time: .omitted))
                    .font(MonetiqTheme.Typography.caption)
                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Text(String(format: "%.2f %@", payment.amount, payment.loan?.currencyCode ?? "RON"))
                .font(MonetiqTheme.Typography.callout)
                .foregroundColor(MonetiqTheme.Colors.accent)
                .fontWeight(.medium)
        }
        .monetiqCard()
    }
}

struct DashboardLoanRowView: View {
    let loan: Loan
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                Text(loan.title)
                    .font(MonetiqTheme.Typography.body)
                    .foregroundColor(MonetiqTheme.Colors.onSurface)
                
                Text(loan.role.displayName)
                    .font(MonetiqTheme.Typography.caption)
                    .foregroundColor(roleColor(for: loan.role))
            }
            
            Spacer()
            
            Text(String(format: "%.2f %@", loan.principalAmount, loan.currencyCode))
                .font(MonetiqTheme.Typography.callout)
                .foregroundColor(MonetiqTheme.Colors.accent)
                .fontWeight(.medium)
        }
        .monetiqCard()
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
}

#Preview {
    DashboardView()
        .modelContainer(for: [Counterparty.self, Loan.self, Payment.self], inMemory: true)
}
