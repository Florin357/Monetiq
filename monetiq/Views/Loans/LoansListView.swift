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
    @Query private var allPayments: [Payment]  // For badge count calculation
    @State private var showingAddLoan = false
    
    private var notificationManager: NotificationManager {
        NotificationManager.shared
    }
    
    /// Sort loans: active loans first (by creation date), completed loans at bottom
    /// Active loans: newest first (consistent with Dashboard)
    /// Completed loans: always at the bottom
    private var sortedLoans: [Loan] {
        loans.sorted { loan1, loan2 in
            let completed1 = loan1.isCompleted
            let completed2 = loan2.isCompleted
            
            // If completion status differs, active loans come first
            if completed1 != completed2 {
                return !completed1 // Active (false) comes before completed (true)
            }
            
            // Within same completion status, sort by creation date (newest first)
            return loan1.createdAt > loan2.createdAt
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header - Premium styling
            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                Text(L10n.string("loans_title"))
                    .font(MonetiqTheme.Typography.largeTitle)
                    .foregroundColor(MonetiqTheme.Colors.textPrimary)
                
                Text(L10n.string("loans_subtitle"))
                    .font(MonetiqTheme.Typography.subheadline)
                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    .opacity(0.8)
            }
            .monetiqHeader()
            .padding(.bottom, MonetiqTheme.Spacing.sm)
            
            if loans.isEmpty {
                Spacer()
                VStack(spacing: MonetiqTheme.Spacing.md) {
                    Image(systemName: "banknote")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    
                    Text(L10n.string("loans_empty_title"))
                        .font(MonetiqTheme.Typography.headline)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    
                    Text(L10n.string("loans_empty_subtitle"))
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
                    await notificationManager.updateBadgeCount(payments: allPayments)
                }
                
                modelContext.delete(loan)
            }
        }
    }
}

struct LoanRowView: View {
    let loan: Loan
    
    // Purple color for completed loans
    private var completedColor: Color {
        Color(red: 0.6, green: 0.4, blue: 0.8) // Pleasant purple/violet
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.lg) {
            HStack(alignment: .top, spacing: MonetiqTheme.Spacing.lg) {
                // Leading accent indicator (purple if completed, role color if active)
                RoundedRectangle(cornerRadius: 3)
                    .fill(loan.isCompleted ? completedColor : roleColor(for: loan.role))
                    .frame(width: 5, height: 50)
                
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
                    // Primary title - Enhanced hierarchy (purple if completed)
                    Text(loan.title)
                        .monetiqCardTitle()
                        .foregroundColor(loan.isCompleted ? completedColor : MonetiqTheme.Colors.textPrimary)
                        .lineLimit(2)
                    
                    // Role badge - Premium styling (purple if completed)
                    Text(loan.role.localizedLabel)
                        .font(MonetiqTheme.Typography.caption)
                        .foregroundColor(loan.isCompleted ? completedColor : roleColor(for: loan.role))
                        .fontWeight(.medium)
                        .padding(.horizontal, MonetiqTheme.Spacing.md)
                        .padding(.vertical, MonetiqTheme.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(loan.isCompleted ? completedColor.opacity(0.15) : roleColor(for: loan.role).opacity(0.15))
                        )
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: MonetiqTheme.Spacing.xs) {
                    // Amount - Premium currency display (purple if completed)
                    Text(CurrencyFormatter.shared.format(amount: loan.principalAmount, currencyCode: loan.currencyCode))
                        .font(MonetiqTheme.Typography.currencySmall)
                        .foregroundColor(loan.isCompleted ? completedColor : MonetiqTheme.Colors.textPrimary)
                        .fontWeight(.bold)
                    
                    if let nextDueDate = loan.nextDueDate {
                        Text(L10n.string("loans_next_due", nextDueDate.formatted(date: .abbreviated, time: .omitted)))
                            .font(MonetiqTheme.Typography.caption2)
                            .foregroundColor(MonetiqTheme.Colors.textSecondary)
                            .opacity(0.8)
                    }
                }
            }
            
            if let counterparty = loan.counterparty {
                HStack(spacing: MonetiqTheme.Spacing.sm) {
                    Image(systemName: counterparty.type == .person ? "person.fill" : "building.fill")
                        .foregroundColor(MonetiqTheme.Colors.textTertiary)
                        .font(MonetiqTheme.Typography.caption)
                    
                    Text(counterparty.name)
                        .monetiqCardSubtitle()
                        .opacity(0.9)
                    
                    Text("•")
                        .foregroundColor(MonetiqTheme.Colors.textTertiary)
                        .opacity(0.5)
                    
                    Text(L10n.string("loans_created_short", loan.createdAt.formatted(date: .abbreviated, time: .omitted)))
                        .font(MonetiqTheme.Typography.caption)
                        .foregroundColor(MonetiqTheme.Colors.textTertiary)
                        .opacity(0.7)
                }
                .padding(.leading, MonetiqTheme.Spacing.lg + MonetiqTheme.Spacing.sm) // Align with content
            }
        }
        .monetiqPremiumCard()
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
