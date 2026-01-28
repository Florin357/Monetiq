//
//  ExpenseListView.swift
//  monetiq
//
//  Created by AI Assistant on 26.01.2026.
//

import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.createdAt, order: .reverse) private var allExpenses: [Expense]
    
    @State private var showingAddExpense = false
    @State private var editingExpense: Expense?
    @State private var expenseToDelete: Expense?
    @State private var showingDeleteConfirmation = false
    @State private var appState = AppState.shared
    @AppStorage("expensesArchiveExpanded") private var isArchiveExpanded = false
    
    // Computed properties for Active Recurring, Active One-Time, and Archived sections
    private var activeRecurringExpenses: [Expense] {
        // Don't access expense properties during reset
        guard !appState.isResetting else { return [] }
        
        return allExpenses
            .filter { !$0.isArchived && $0.frequency != .oneTime }
            .sorted { expense1, expense2 in
                // Sort by next due date (soonest first)
                guard let date1 = expense1.nextDueDate else { return false }
                guard let date2 = expense2.nextDueDate else { return true }
                return date1 < date2
            }
    }
    
    private var activeOneTimeExpenses: [Expense] {
        // Don't access expense properties during reset
        guard !appState.isResetting else { return [] }
        
        return allExpenses
            .filter { $0.frequency == .oneTime && !$0.isArchived }
            .sorted { $0.startDate < $1.startDate }
    }
    
    private var archivedExpenses: [Expense] {
        // Don't access expense properties during reset
        guard !appState.isResetting else { return [] }
        
        return allExpenses
            .filter { $0.isArchived }
            .sorted { ($0.endDate ?? $0.startDate) > ($1.endDate ?? $1.startDate) }
    }
    
    private var archivedGrouped: [(key: String, expenses: [Expense])] {
        let grouped = Dictionary(grouping: archivedExpenses) { expense in
            expense.archiveGroupLabel ?? "Unknown"
        }
        return grouped.map { (key: $0.key, expenses: $0.value) }
            .sorted { $0.key > $1.key } // Most recent first
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header - Premium styling
            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                Text(L10n.string("expenses_title"))
                    .font(MonetiqTheme.Typography.largeTitle)
                    .foregroundColor(MonetiqTheme.Colors.textPrimary)
                
                Text(L10n.string("expenses_subtitle"))
                    .font(MonetiqTheme.Typography.subheadline)
                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    .opacity(0.8)
            }
            .monetiqHeader()
            .padding(.bottom, MonetiqTheme.Spacing.sm)
            
            if allExpenses.isEmpty {
                Spacer()
                VStack(spacing: MonetiqTheme.Spacing.md) {
                    Image(systemName: "cart")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    
                    Text(L10n.string("expenses_empty_title"))
                        .font(MonetiqTheme.Typography.headline)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                    
                    Text(L10n.string("expenses_empty_subtitle"))
                        .font(MonetiqTheme.Typography.body)
                        .foregroundColor(MonetiqTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            } else {
                List {
                    // Section 1: Active Recurring (Indigo header)
                    if !activeRecurringExpenses.isEmpty {
                        Section {
                            ForEach(activeRecurringExpenses, id: \.id) { expense in
                                ExpenseRowView(expense: expense)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingExpense = expense
                                    }
                                    #if !os(macOS)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            expenseToDelete = expense
                                            showingDeleteConfirmation = true
                                        } label: {
                                            Label(L10n.string("general_delete"), systemImage: "trash")
                                        }
                                        
                                        Button {
                                            editingExpense = expense
                                        } label: {
                                            Label(L10n.string("general_edit"), systemImage: "pencil")
                                        }
                                        .tint(MonetiqTheme.Colors.accent)
                                    }
                                    #endif
                                    .contextMenu {
                                        Button {
                                            editingExpense = expense
                                        } label: {
                                            Label(L10n.string("general_edit"), systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive) {
                                            expenseToDelete = expense
                                            showingDeleteConfirmation = true
                                        } label: {
                                            Label(L10n.string("general_delete"), systemImage: "trash")
                                        }
                                    }
                            }
                            .onDelete { offsets in
                                deleteExpenseAtOffsets(offsets, from: activeRecurringExpenses)
                            }
                        } header: {
                            Text(L10n.string("expenses_section_active_recurring"))
                                .font(MonetiqTheme.Typography.caption)
                                .foregroundColor(Color.indigo.opacity(0.8))
                                .textCase(.uppercase)
                                .tracking(0.8)
                                .fontWeight(.medium)
                        }
                    }
                    
                    // Section 2: One-Time Expenses (Teal header)
                    if !activeOneTimeExpenses.isEmpty {
                        Section {
                            ForEach(activeOneTimeExpenses, id: \.id) { expense in
                                ExpenseRowView(expense: expense)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingExpense = expense
                                    }
                                    #if !os(macOS)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            expenseToDelete = expense
                                            showingDeleteConfirmation = true
                                        } label: {
                                            Label(L10n.string("general_delete"), systemImage: "trash")
                                        }
                                        
                                        Button {
                                            editingExpense = expense
                                        } label: {
                                            Label(L10n.string("general_edit"), systemImage: "pencil")
                                        }
                                        .tint(MonetiqTheme.Colors.accent)
                                    }
                                    #endif
                                    .contextMenu {
                                        Button {
                                            editingExpense = expense
                                        } label: {
                                            Label(L10n.string("general_edit"), systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive) {
                                            expenseToDelete = expense
                                            showingDeleteConfirmation = true
                                        } label: {
                                            Label(L10n.string("general_delete"), systemImage: "trash")
                                        }
                                    }
                            }
                            .onDelete { offsets in
                                deleteExpenseAtOffsets(offsets, from: activeOneTimeExpenses)
                            }
                        } header: {
                            Text(L10n.string("expenses_section_one_time"))
                                .font(MonetiqTheme.Typography.caption)
                                .foregroundColor(Color.teal.opacity(0.8))
                                .textCase(.uppercase)
                                .tracking(0.8)
                                .fontWeight(.medium)
                        }
                    }
                    
                    // Archived Section (collapsible)
                    if !archivedExpenses.isEmpty {
                        Section {
                            Button(action: {
                                withAnimation {
                                    isArchiveExpanded.toggle()
                                }
                            }) {
                                HStack {
                                    Text(L10n.string("expenses_section_archived"))
                                        .font(MonetiqTheme.Typography.caption)
                                        .foregroundColor(Color.purple.opacity(0.8))
                                        .textCase(.uppercase)
                                        .tracking(0.8)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Image(systemName: isArchiveExpanded ? "chevron.down" : "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(Color.purple.opacity(0.6))
                                    
                                    Text("\(archivedExpenses.count)")
                                        .font(MonetiqTheme.Typography.caption2)
                                        .foregroundColor(Color.purple.opacity(0.6))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                            .listRowBackground(Color.clear)
                            
                            if isArchiveExpanded {
                                ForEach(archivedGrouped, id: \.key) { group in
                                    Section(group.key) {
                                        ForEach(group.expenses, id: \.id) { expense in
                                            ExpenseRowView(expense: expense)
                                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                                .listRowBackground(Color.clear)
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    editingExpense = expense
                                                }
                                                #if !os(macOS)
                                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                    Button(role: .destructive) {
                                                        expenseToDelete = expense
                                                        showingDeleteConfirmation = true
                                                    } label: {
                                                        Label(L10n.string("general_delete"), systemImage: "trash")
                                                    }
                                                    
                                                    Button {
                                                        editingExpense = expense
                                                    } label: {
                                                        Label(L10n.string("general_edit"), systemImage: "pencil")
                                                    }
                                                    .tint(MonetiqTheme.Colors.accent)
                                                }
                                                #endif
                                                .contextMenu {
                                                    Button {
                                                        editingExpense = expense
                                                    } label: {
                                                        Label(L10n.string("general_edit"), systemImage: "pencil")
                                                    }
                                                    
                                                    Button(role: .destructive) {
                                                        expenseToDelete = expense
                                                        showingDeleteConfirmation = true
                                                    } label: {
                                                        Label(L10n.string("general_delete"), systemImage: "trash")
                                                    }
                                                }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .monetiqBackground()
        .toolbar {
            #if os(macOS)
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
            #endif
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddExpense = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(MonetiqTheme.Colors.accent)
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddEditExpenseView()
        }
        .sheet(item: $editingExpense) { expense in
            AddEditExpenseView(expense: expense)
        }
        .alert(L10n.string("expenses_delete_title"), isPresented: $showingDeleteConfirmation, presenting: expenseToDelete) { expense in
            Button(L10n.string("general_cancel"), role: .cancel) {
                expenseToDelete = nil
            }
            Button(L10n.string("general_delete"), role: .destructive) {
                deleteExpense(expense)
            }
        } message: { expense in
            Text(L10n.string("expenses_delete_message"))
        }
    }
    
    private func deleteExpense(_ expense: Expense) {
        // Cancel notifications for this expense before deleting
        Task {
            await NotificationManager.shared.cancelExpenseNotifications(for: expense)
        }
        
        withAnimation {
            modelContext.delete(expense)
            expenseToDelete = nil
        }
    }
    
    private func deleteExpenseAtOffsets(_ offsets: IndexSet, from sources: [Expense]) {
        withAnimation {
            for index in offsets {
                let expense = sources[index]
                // Cancel notifications before deleting
                Task {
                    await NotificationManager.shared.cancelExpenseNotifications(for: expense)
                }
                modelContext.delete(expense)
            }
        }
    }
}

#Preview {
    ExpenseListView()
        .modelContainer(for: [Expense.self, ExpenseOccurrence.self], inMemory: true)
}

