//
//  LoansListView.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import SwiftUI
import SwiftData

struct LoansListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var loans: [Loan]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
                Text("Loans")
                    .font(MonetiqTheme.Typography.largeTitle)
                    .foregroundColor(MonetiqTheme.Colors.onBackground)
                
                Text("Manage your loans and debts")
                    .font(MonetiqTheme.Typography.callout)
                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, MonetiqTheme.Spacing.md)
            .padding(.top, MonetiqTheme.Spacing.lg)
            
            if loans.isEmpty {
                Spacer()
                VStack(spacing: MonetiqTheme.Spacing.md) {
                    Image(systemName: "banknote")
                        .font(.system(size: 60))
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    
                    Text("No loans yet")
                        .font(MonetiqTheme.Typography.headline)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    
                    Text("Add your first loan to get started")
                        .font(MonetiqTheme.Typography.body)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: MonetiqTheme.Spacing.md) {
                        ForEach(loans, id: \.id) { loan in
                            LoanRowView(loan: loan)
                        }
                    }
                    .padding(.horizontal, MonetiqTheme.Spacing.md)
                    .padding(.vertical, MonetiqTheme.Spacing.lg)
                }
            }
        }
        .monetiqBackground()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: addSampleLoan) {
                    Image(systemName: "plus")
                        .foregroundColor(MonetiqTheme.Colors.accent)
                }
            }
        }
    }
    
    private func addSampleLoan() {
        // Placeholder for adding new loan
        // In a real app, this would open a form
    }
}

struct LoanRowView: View {
    let loan: Loan
    
    var body: some View {
        VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                    Text(loan.title)
                        .font(MonetiqTheme.Typography.headline)
                        .foregroundColor(MonetiqTheme.Colors.onSurface)
                    
                    Text(loan.role.displayName)
                        .font(MonetiqTheme.Typography.caption)
                        .foregroundColor(roleColor(for: loan.role))
                        .padding(.horizontal, MonetiqTheme.Spacing.sm)
                        .padding(.vertical, MonetiqTheme.Spacing.xs)
                        .background(roleColor(for: loan.role).opacity(0.2))
                        .cornerRadius(MonetiqTheme.CornerRadius.sm)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: MonetiqTheme.Spacing.xs) {
                    Text("\(loan.principalAmount, specifier: "%.2f") \(loan.currencyCode)")
                        .font(MonetiqTheme.Typography.callout)
                        .foregroundColor(MonetiqTheme.Colors.accent)
                        .fontWeight(.semibold)
                    
                    if let nextPayment = nextPaymentDate(for: loan) {
                        Text("Next: \(nextPayment, style: .date)")
                            .font(MonetiqTheme.Typography.caption2)
                            .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    }
                }
            }
            
            if let counterparty = loan.counterparty {
                HStack {
                    Image(systemName: counterparty.type == .person ? "person.fill" : "building.fill")
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                        .font(.caption)
                    
                    Text(counterparty.name)
                        .font(MonetiqTheme.Typography.caption)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                }
            }
        }
        .monetiqCard()
    }
    
    private func roleColor(for role: LoanRole) -> Color {
        switch role {
        case .creditor:
            return MonetiqTheme.Colors.success
        case .debtor:
            return MonetiqTheme.Colors.warning
        case .creditInstitution:
            return MonetiqTheme.Colors.error
        }
    }
    
    private func nextPaymentDate(for loan: Loan) -> Date? {
        loan.payments
            .filter { $0.status == .planned }
            .sorted { $0.dueDate < $1.dueDate }
            .first?.dueDate
    }
}

#Preview {
    NavigationStack {
        LoansListView()
    }
    .modelContainer(SampleData.previewContainer())
}
