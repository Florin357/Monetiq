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
    @State private var localizationManager = LocalizationManager.shared
    
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
            print("🌐 Test localization: \(L10n.string("tab_dashboard"))")
            #endif
            return locale
        } else {
            #if DEBUG
            print("🌐 Using system locale: \(Locale.current.identifier)")
            print("🌐 Test localization: \(L10n.string("tab_dashboard"))")
            #endif
            return Locale.current
        }
    }
    
    private var effectiveLanguageKey: String {
        return appSettings.languageOverride ?? "system"
    }
    
    private func updateLocalizationManager() {
        localizationManager.currentLanguageCode = appSettings.languageOverride
    }
    
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Image(systemName: "chart.pie.fill")
                Text("tab_dashboard", bundle: .main)
            }
            
            NavigationStack {
                LoansListView()
            }
            .tabItem {
                Image(systemName: "banknote.fill")
                Text("tab_loans", bundle: .main)
            }
            
            NavigationStack {
                CalculatorView()
            }
            .tabItem {
                Image(systemName: "function")
                Text("tab_calculator", bundle: .main)
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text("tab_settings", bundle: .main)
            }
        }
        .monetiqBackground()
        .preferredColorScheme(.dark)
        .environment(\.locale, effectiveLocale)
        .id(effectiveLanguageKey)
        .onAppear {
            updateLocalizationManager()
        }
        .onChange(of: appSettings.languageOverride) { _, _ in
            updateLocalizationManager()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Counterparty.self, Loan.self, Payment.self, AppSettings.self], inMemory: true)
}
