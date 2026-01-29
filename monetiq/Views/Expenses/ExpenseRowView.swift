//
//  ExpenseRowView.swift
//  monetiq
//
//  Created by AI Assistant on 26.01.2026.
//

import SwiftUI
import SwiftData

struct ExpenseRowView: View {
    let expense: Expense
    
    private var accentColor: Color {
        if expense.isArchived || expense.isCompleted {
            return Color.purple
        } else if expense.frequency == .oneTime {
            return Color.teal
        } else if expense.isOverdue {
            return MonetiqTheme.Colors.error
        } else {
            return Color.indigo
        }
    }
    
    private var badgeStyle: ExpenseBadgeStyle {
        if expense.isArchived || expense.isCompleted {
            return .status
        } else if expense.frequency == .oneTime {
            return .oneTime
        } else if expense.isOverdue {
            return .recurringOverdue
        } else {
            return .recurringActive
        }
    }
    
    private var frequencyLabel: String {
        switch expense.frequency {
        case .oneTime:
            return L10n.string("frequency_onetime")
        case .weekly:
            return L10n.string("frequency_weekly")
        case .monthly:
            return L10n.string("frequency_monthly")
        case .quarterly:
            return L10n.string("frequency_quarterly")
        case .yearly:
            return L10n.string("frequency_yearly")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.lg) {
            HStack(alignment: .top, spacing: MonetiqTheme.Spacing.md) {
                // Leading accent indicator (purple for completed, red for active)
                RoundedRectangle(cornerRadius: 3)
                    .fill(accentColor)
                    .frame(width: 5, height: 50)
                
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
                    // Primary title - Enhanced hierarchy
                    Text(expense.title)
                        .monetiqCardTitle()
                        .foregroundColor(MonetiqTheme.Colors.textPrimary)
                        .lineLimit(2)
                    
                    HStack(spacing: MonetiqTheme.Spacing.sm) {
                        if expense.isCompleted {
                            ExpenseBadge(
                                text: L10n.string("expenses_status_completed"),
                                style: .status
                            )
                        } else {
                            ExpenseBadge(
                                text: frequencyLabel,
                                style: badgeStyle
                            )
                        }
                        
                        if let category = expense.category, !category.isEmpty {
                            ExpenseBadge(
                                text: category,
                                style: .category
                            )
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: MonetiqTheme.Spacing.xs) {
                    // Amount - Premium currency display
                    Text(CurrencyFormatter.shared.format(amount: expense.amount, currencyCode: expense.currencyCode))
                        .font(MonetiqTheme.Typography.currencySmall)
                        .foregroundColor(MonetiqTheme.Colors.textPrimary)
                        .fontWeight(.bold)
                    
                    if expense.isCompleted {
                        if let endDate = expense.endDate {
                            Text(L10n.string("expenses_ended_date", endDate.formatted(date: .abbreviated, time: .omitted)))
                                .font(MonetiqTheme.Typography.caption2)
                                .foregroundColor(.purple.opacity(0.8))
                                .opacity(0.9)
                        }
                    } else if expense.frequency == .oneTime {
                        // For one-time expenses, show the start date
                        Text(L10n.string("expenses_one_time_on", expense.startDate.formatted(date: .abbreviated, time: .omitted)))
                            .font(MonetiqTheme.Typography.caption2)
                            .foregroundColor(MonetiqTheme.Colors.textSecondary)
                            .opacity(0.8)
                    } else if let nextDue = expense.nextDueDate {
                        // For recurring expenses, show next due date
                        Text(L10n.string("expenses_next", nextDue.formatted(date: .abbreviated, time: .omitted)))
                            .font(MonetiqTheme.Typography.caption2)
                            .foregroundColor(MonetiqTheme.Colors.textSecondary)
                            .opacity(0.8)
                    }
                    
                    // Show subscription age for recurring expenses
                    if let subscriptionLabel = expense.subscriptionAgeLabel {
                        Text(subscriptionLabel)
                            .font(MonetiqTheme.Typography.caption2)
                            .foregroundColor(MonetiqTheme.Colors.success.opacity(0.8))
                            .opacity(0.9)
                    }
                }
            }
        }
        .monetiqCard()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Expense.self, ExpenseOccurrence.self, configurations: config)
    
    let sampleExpense = Expense(
        title: "Groceries",
        amount: 150,
        currencyCode: "USD",
        frequency: .monthly,
        startDate: Date(),
        category: "Food"
    )
    container.mainContext.insert(sampleExpense)
    
    return ExpenseRowView(expense: sampleExpense)
        .modelContainer(container)
        .padding()
}

