//
//  ContentView.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Image(systemName: "chart.pie.fill")
                Text(L10n.string("tab_dashboard"))
            }
            
            NavigationStack {
                LoansListView()
            }
            .tabItem {
                Image(systemName: "banknote.fill")
                Text(L10n.string("tab_loans"))
            }
            
            NavigationStack {
                CalculatorView()
            }
            .tabItem {
                Image(systemName: "calculator.fill")
                Text(L10n.string("tab_calculator"))
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gear.fill")
                Text(L10n.string("tab_settings"))
            }
        }
        .monetiqBackground()
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Counterparty.self, Loan.self, Payment.self, AppSettings.self], inMemory: true)
}
