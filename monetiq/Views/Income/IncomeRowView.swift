//
//  IncomeRowView.swift
//  monetiq
//
//  Created by Florin Mihai on 28.12.2025.
//

import SwiftUI
import SwiftData

struct IncomeRowView: View {
    let income: IncomeSource
    
    private var frequencyLabel: String {
        switch income.frequency {
        case .weekly:
            return L10n.string("income_frequency_weekly")
        case .monthly:
            return L10n.string("income_frequency_monthly")
        case .quarterly:
            return L10n.string("income_frequency_quarterly")
        case .yearly:
            return L10n.string("income_frequency_yearly")
        case .oneTime:
            return L10n.string("income_frequency_one_time")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.lg) {
            HStack(alignment: .top, spacing: MonetiqTheme.Spacing.md) {
                // Leading accent indicator (green for income)
                RoundedRectangle(cornerRadius: 3)
                    .fill(MonetiqTheme.Colors.success)
                    .frame(width: 5, height: 50)
                
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
                    // Primary title - Enhanced hierarchy
                    Text(income.title)
                        .monetiqCardTitle()
                        .foregroundColor(MonetiqTheme.Colors.textPrimary)
                        .lineLimit(2)
                    
                    // Frequency badge - Premium styling
                    Text(frequencyLabel)
                        .font(MonetiqTheme.Typography.caption)
                        .foregroundColor(MonetiqTheme.Colors.success)
                        .fontWeight(.medium)
                        .padding(.horizontal, MonetiqTheme.Spacing.md)
                        .padding(.vertical, MonetiqTheme.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(MonetiqTheme.Colors.success.opacity(0.15))
                        )
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: MonetiqTheme.Spacing.xs) {
                    // Amount - Premium currency display
                    Text(CurrencyFormatter.shared.format(amount: income.amount, currencyCode: income.currencyCode))
                        .font(MonetiqTheme.Typography.currencySmall)
                        .foregroundColor(MonetiqTheme.Colors.textPrimary)
                        .fontWeight(.bold)
                    
                    if let nextPayday = income.nextPaymentDate {
                        Text(L10n.string("income_next_payday", nextPayday.formatted(date: .abbreviated, time: .omitted)))
                            .font(MonetiqTheme.Typography.caption2)
                            .foregroundColor(MonetiqTheme.Colors.textSecondary)
                            .opacity(0.8)
                    }
                }
            }
            
            if let counterpartyName = income.counterpartyName {
                HStack(spacing: MonetiqTheme.Spacing.sm) {
                    Image(systemName: "building.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MonetiqTheme.Colors.textTertiary)
                    
                    Text(counterpartyName)
                        .font(MonetiqTheme.Typography.caption)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
                .padding(.top, MonetiqTheme.Spacing.xs)
            }
        }
        .monetiqCard()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: IncomeSource.self, IncomePayment.self, configurations: config)
    
    let sampleIncome = IncomeSource(
        title: "Monthly Salary",
        amount: 5000,
        currencyCode: "RON",
        frequency: .monthly,
        startDate: Date(),
        counterpartyName: "Tech Corp"
    )
    container.mainContext.insert(sampleIncome)
    
    return IncomeRowView(income: sampleIncome)
        .modelContainer(container)
        .padding()
}

