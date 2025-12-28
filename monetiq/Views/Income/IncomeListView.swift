//
//  IncomeListView.swift
//  monetiq
//
//  Created by Florin Mihai on 28.12.2025.
//

import SwiftUI
import SwiftData

struct IncomeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \IncomeSource.createdAt, order: .reverse) private var incomeSources: [IncomeSource]
    @State private var showingAddIncome = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header - Premium styling
            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                Text(L10n.string("income_title"))
                    .font(MonetiqTheme.Typography.largeTitle)
                    .foregroundColor(MonetiqTheme.Colors.textPrimary)
                
                Text(L10n.string("income_subtitle"))
                    .font(MonetiqTheme.Typography.subheadline)
                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    .opacity(0.8)
            }
            .monetiqHeader()
            .padding(.bottom, MonetiqTheme.Spacing.sm)
            
            if incomeSources.isEmpty {
                Spacer()
                VStack(spacing: MonetiqTheme.Spacing.md) {
                    Image(systemName: "banknote")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    
                    Text(L10n.string("income_empty_title"))
                        .font(MonetiqTheme.Typography.headline)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    
                    Text(L10n.string("income_empty_subtitle"))
                        .font(MonetiqTheme.Typography.body)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: MonetiqTheme.Spacing.md) {
                        ForEach(incomeSources, id: \.id) { income in
                            IncomeRowView(income: income)
                        }
                        .onDelete(perform: deleteIncome)
                    }
                    .padding(.horizontal, MonetiqTheme.Spacing.md)
                    .padding(.vertical, MonetiqTheme.Spacing.lg)
                }
            }
        }
        .monetiqBackground()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddIncome = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(MonetiqTheme.Colors.accent)
                }
            }
        }
        .sheet(isPresented: $showingAddIncome) {
            AddEditIncomeView()
        }
    }
    
    private func deleteIncome(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let income = incomeSources[index]
                modelContext.delete(income)
            }
        }
    }
}

#Preview {
    IncomeListView()
        .modelContainer(for: [IncomeSource.self, IncomePayment.self], inMemory: true)
}

