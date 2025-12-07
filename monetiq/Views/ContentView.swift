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
                Text("Dashboard")
            }
            
            NavigationStack {
                LoansListView()
            }
            .tabItem {
                Image(systemName: "banknote.fill")
                Text("Loans")
            }
            
            NavigationStack {
                CalculatorView()
            }
            .tabItem {
                Image(systemName: "calculator.fill")
                Text("Calculator")
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gear.fill")
                Text("Settings")
            }
        }
        .monetiqBackground()
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Counterparty.self, Loan.self, Payment.self], inMemory: true)
}
