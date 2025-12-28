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
    @Query(sort: \IncomeSource.createdAt, order: .reverse) private var allIncomeSources: [IncomeSource]
    
    @State private var showingAddIncome = false
    @State private var editingIncome: IncomeSource?
    @State private var incomeToDelete: IncomeSource?
    @State private var showingDeleteConfirmation = false
    
    // Computed properties for Active and Completed sections
    private var activeIncomeSources: [IncomeSource] {
        allIncomeSources
            .filter { !$0.isCompleted }
            .sorted { income1, income2 in
                // Sort by next payment date (soonest first)
                guard let date1 = income1.nextPaymentDate else { return false }
                guard let date2 = income2.nextPaymentDate else { return true }
                return date1 < date2
            }
    }
    
    private var completedIncomeSources: [IncomeSource] {
        allIncomeSources
            .filter { $0.isCompleted }
            .sorted { income1, income2 in
                // Sort by end date descending (most recently completed first)
                guard let date1 = income1.endDate else { return false }
                guard let date2 = income2.endDate else { return true }
                return date1 > date2
            }
    }
    
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
            
            if allIncomeSources.isEmpty {
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
                List {
                    // Active Section
                    if !activeIncomeSources.isEmpty {
                        Section {
                            ForEach(activeIncomeSources, id: \.id) { income in
                                IncomeRowView(income: income)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingIncome = income
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            incomeToDelete = income
                                            showingDeleteConfirmation = true
                                        } label: {
                                            Label(L10n.string("general_delete"), systemImage: "trash")
                                        }
                                        
                                        Button {
                                            editingIncome = income
                                        } label: {
                                            Label(L10n.string("general_edit"), systemImage: "pencil")
                                        }
                                        .tint(MonetiqTheme.Colors.accent)
                                    }
                            }
                        } header: {
                            Text(L10n.string("income_section_active"))
                                .font(MonetiqTheme.Typography.caption)
                                .foregroundColor(MonetiqTheme.Colors.textSecondary)
                                .textCase(.uppercase)
                                .tracking(0.8)
                                .fontWeight(.medium)
                        }
                    }
                    
                    // Completed Section
                    if !completedIncomeSources.isEmpty {
                        Section {
                            ForEach(completedIncomeSources, id: \.id) { income in
                                IncomeRowView(income: income)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingIncome = income
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            incomeToDelete = income
                                            showingDeleteConfirmation = true
                                        } label: {
                                            Label(L10n.string("general_delete"), systemImage: "trash")
                                        }
                                        
                                        Button {
                                            editingIncome = income
                                        } label: {
                                            Label(L10n.string("general_edit"), systemImage: "pencil")
                                        }
                                        .tint(MonetiqTheme.Colors.accent)
                                    }
                            }
                        } header: {
                            Text(L10n.string("income_section_completed"))
                                .font(MonetiqTheme.Typography.caption)
                                .foregroundColor(Color.purple.opacity(0.8))
                                .textCase(.uppercase)
                                .tracking(0.8)
                                .fontWeight(.medium)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
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
        .sheet(item: $editingIncome) { income in
            AddEditIncomeView(income: income)
        }
        .alert(L10n.string("income_delete_title"), isPresented: $showingDeleteConfirmation, presenting: incomeToDelete) { income in
            Button(L10n.string("general_cancel"), role: .cancel) {
                incomeToDelete = nil
            }
            Button(L10n.string("general_delete"), role: .destructive) {
                deleteIncome(income)
            }
        } message: { income in
            Text(L10n.string("income_delete_message"))
        }
    }
    
    private func deleteIncome(_ income: IncomeSource) {
        withAnimation {
            modelContext.delete(income)
            incomeToDelete = nil
        }
    }
}

#Preview {
    IncomeListView()
        .modelContainer(for: [IncomeSource.self, IncomePayment.self], inMemory: true)
}
