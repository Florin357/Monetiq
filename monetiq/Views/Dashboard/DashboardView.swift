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
                                PaymentRowView(payment: payment)
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
            .filter { $0.status == .planned }
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    private func calculateToReceive() -> Double {
        let creditorLoans = loans.filter { $0.role == .creditor }
        let allPayments = creditorLoans.flatMap { $0.payments }
        let plannedPayments = allPayments.filter { $0.status == .planned }
        return plannedPayments.reduce(0) { $0 + $1.amount }
    }
    
    private func calculateToPay() -> Double {
        let debtorLoans = loans.filter { $0.role == .debtor || $0.role == .creditInstitution }
        let allPayments = debtorLoans.flatMap { $0.payments }
        let plannedPayments = allPayments.filter { $0.status == .planned }
        return plannedPayments.reduce(0) { $0 + $1.amount }
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
            
            Text("\(amount, specifier: "%.2f") \(currency)")
                .font(MonetiqTheme.Typography.title2)
                .foregroundColor(color)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .monetiqCard()
    }
}

struct PaymentRowView: View {
    let payment: Payment
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                Text(payment.loan?.title ?? "Unknown Loan")
                    .font(MonetiqTheme.Typography.body)
                    .foregroundColor(MonetiqTheme.Colors.onSurface)
                
                Text(payment.dueDate, style: .date)
                    .font(MonetiqTheme.Typography.caption)
                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Text("\(payment.amount, specifier: "%.2f") \(payment.loan?.currencyCode ?? "RON")")
                .font(MonetiqTheme.Typography.callout)
                .foregroundColor(MonetiqTheme.Colors.accent)
                .fontWeight(.medium)
        }
        .monetiqCard()
    }
}

#Preview {
    DashboardView()
        .modelContainer(SampleData.previewContainer())
}
