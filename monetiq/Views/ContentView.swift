//
//  ContentView.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [AppSettings]
    
    private var appSettings: AppSettings {
        AppSettings.getOrCreate(in: modelContext)
    }
    
    private var effectiveLocale: Locale {
        let languageCode = appSettings.languageOverride
        
        #if DEBUG
        print("🌐 Language Override: \(languageCode ?? "nil (system)")")
        #endif
        
        if let languageCode = languageCode, languageCode != "system" {
            let locale = Locale(identifier: languageCode)
            #if DEBUG
            print("🌐 Applying locale: \(locale.identifier)")
            #endif
            return locale
        } else {
            #if DEBUG
            print("🌐 Using system locale: \(Locale.current.identifier)")
            #endif
            return Locale.current
        }
    }
    
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
                Image(systemName: "function")
                Text(L10n.string("tab_calculator"))
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text(L10n.string("tab_settings"))
            }
        }
        .monetiqBackground()
        .preferredColorScheme(.dark)
        .environment(\.locale, effectiveLocale)
        .id(appSettings.languageOverride ?? "system")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Counterparty.self, Loan.self, Payment.self, AppSettings.self], inMemory: true)
}
