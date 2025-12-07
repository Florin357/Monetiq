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
    @State private var showingAddLoan = false
    
    private var notificationManager: NotificationManager {
        NotificationManager.shared
    }
    
    private var sortedLoans: [Loan] {
        loans.sorted { first, second in
            if first.role != second.role {
                return first.role.rawValue < second.role.rawValue
            }
            return first.title < second.title
        }
    }
    
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
                        ForEach(sortedLoans, id: \.id) { loan in
                            NavigationLink(destination: LoanDetailView(loan: loan)) {
                                LoanRowView(loan: loan)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .onDelete(perform: deleteLoans)
                    }
                    .padding(.horizontal, MonetiqTheme.Spacing.md)
                    .padding(.vertical, MonetiqTheme.Spacing.lg)
                }
            }
        }
        .monetiqBackground()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddLoan = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(MonetiqTheme.Colors.accent)
                }
            }
        }
        .sheet(isPresented: $showingAddLoan) {
            AddEditLoanView()
        }
    }
    
    private func deleteLoans(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let loan = sortedLoans[index]
                
                // Cancel notifications for this loan before deletion
                Task {
                    await notificationManager.cancelNotifications(for: loan)
                }
                
                modelContext.delete(loan)
            }
        }
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
                    Text(String(format: "%.2f %@", loan.principalAmount, loan.currencyCode))
                        .font(MonetiqTheme.Typography.callout)
                        .foregroundColor(MonetiqTheme.Colors.accent)
                        .fontWeight(.semibold)
                    
                    if let nextDueDate = loan.nextDueDate {
                        Text("Next: \(nextDueDate, style: .date)")
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
    NavigationStack {
        LoansListView()
    }
    .modelContainer(for: [Counterparty.self, Loan.self, Payment.self, AppSettings.self], inMemory: true)
}
