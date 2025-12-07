//
//  LoanDetailView.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import SwiftUI
import SwiftData

struct LoanDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let loan: Loan
    @State private var showingEditLoan = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: MonetiqTheme.Spacing.lg) {
                // Header Card
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.sm) {
                            Text(loan.title)
                                .font(MonetiqTheme.Typography.title)
                                .foregroundColor(MonetiqTheme.Colors.onSurface)
                            
                            Text(loan.role.displayName)
                                .font(MonetiqTheme.Typography.callout)
                                .foregroundColor(roleColor(for: loan.role))
                                .padding(.horizontal, MonetiqTheme.Spacing.md)
                                .padding(.vertical, MonetiqTheme.Spacing.sm)
                                .background(roleColor(for: loan.role).opacity(0.2))
                                .cornerRadius(MonetiqTheme.CornerRadius.md)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: MonetiqTheme.Spacing.xs) {
                            Text("\(loan.principalAmount, specifier: "%.2f")")
                                .font(MonetiqTheme.Typography.title2)
                                .foregroundColor(MonetiqTheme.Colors.accent)
                                .fontWeight(.semibold)
                            
                            Text(loan.currencyCode)
                                .font(MonetiqTheme.Typography.callout)
                                .foregroundColor(MonetiqTheme.Colors.textSecondary)
                        }
                    }
                }
                .monetiqCard()
                .padding(.horizontal, MonetiqTheme.Spacing.md)
                
                // Details Section
                VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                    Text("Details")
                        .font(MonetiqTheme.Typography.headline)
                        .foregroundColor(MonetiqTheme.Colors.onSurface)
                    
                    VStack(spacing: MonetiqTheme.Spacing.md) {
                        DetailRow(title: "Start Date", value: loan.startDate.formatted(date: .abbreviated, time: .omitted))
                        
                        if let nextDueDate = loan.nextDueDate {
                            DetailRow(title: "Next Due Date", value: nextDueDate.formatted(date: .abbreviated, time: .omitted))
                        }
                        
                        DetailRow(title: "Created", value: loan.createdAt.formatted(date: .abbreviated, time: .shortened))
                        
                        if loan.updatedAt != loan.createdAt {
                            DetailRow(title: "Last Updated", value: loan.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                }
                .monetiqCard()
                .padding(.horizontal, MonetiqTheme.Spacing.md)
                
                // Counterparty Section
                if let counterparty = loan.counterparty {
                    VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                        Text("Counterparty")
                            .font(MonetiqTheme.Typography.headline)
                            .foregroundColor(MonetiqTheme.Colors.onSurface)
                        
                        HStack {
                            Image(systemName: counterparty.type == .person ? "person.fill" : "building.fill")
                                .foregroundColor(MonetiqTheme.Colors.accent)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.xs) {
                                Text(counterparty.name)
                                    .font(MonetiqTheme.Typography.body)
                                    .foregroundColor(MonetiqTheme.Colors.onSurface)
                                
                                Text(counterparty.type.displayName)
                                    .font(MonetiqTheme.Typography.caption)
                                    .foregroundColor(MonetiqTheme.Colors.textSecondary)
                            }
                            
                            Spacer()
                        }
                        
                        if let notes = counterparty.notes, !notes.isEmpty {
                            Text(notes)
                                .font(MonetiqTheme.Typography.caption)
                                .foregroundColor(MonetiqTheme.Colors.textSecondary)
                                .padding(.top, MonetiqTheme.Spacing.xs)
                        }
                    }
                    .monetiqCard()
                    .padding(.horizontal, MonetiqTheme.Spacing.md)
                }
                
                // Notes Section
                if let notes = loan.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: MonetiqTheme.Spacing.md) {
                        Text("Notes")
                            .font(MonetiqTheme.Typography.headline)
                            .foregroundColor(MonetiqTheme.Colors.onSurface)
                        
                        Text(notes)
                            .font(MonetiqTheme.Typography.body)
                            .foregroundColor(MonetiqTheme.Colors.onSurface)
                    }
                    .monetiqCard()
                    .padding(.horizontal, MonetiqTheme.Spacing.md)
                }
                
                Spacer(minLength: MonetiqTheme.Spacing.xl)
            }
            .padding(.vertical, MonetiqTheme.Spacing.lg)
        }
        .monetiqBackground()
        .navigationTitle("Loan Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditLoan = true }) {
                        Label("Edit Loan", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete Loan", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(MonetiqTheme.Colors.accent)
                }
            }
        }
        .sheet(isPresented: $showingEditLoan) {
            AddEditLoanView(loan: loan)
        }
        .alert("Delete Loan", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteLoan()
            }
        } message: {
            Text("Are you sure you want to delete '\(loan.title)'? This action cannot be undone.")
        }
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
    
    private func deleteLoan() {
        modelContext.delete(loan)
        dismiss()
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(MonetiqTheme.Typography.body)
                .foregroundColor(MonetiqTheme.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(MonetiqTheme.Typography.body)
                .foregroundColor(MonetiqTheme.Colors.onSurface)
        }
    }
}

#Preview {
    let loan = Loan(
        title: "Sample Loan",
        role: .lent,
        principalAmount: 5000.0,
        currencyCode: "RON",
        startDate: Date(),
        notes: "This is a sample loan for preview"
    )
    
    NavigationStack {
        LoanDetailView(loan: loan)
    }
    .modelContainer(for: [Counterparty.self, Loan.self], inMemory: true)
}
