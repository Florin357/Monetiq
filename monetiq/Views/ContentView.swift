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
    @State private var refreshTrigger = UUID()
    @State private var appState = AppState.shared
    @State private var lockState = AppLockState.shared
    
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
        let key = "lang-\(appSettings.languageOverride ?? "system")"
        #if DEBUG
        print("🌐 ContentView: effectiveLanguageKey = \(key)")
        #endif
        return key
    }
    
    private func updateLocalizationManager() {
        localizationManager.currentLanguageCode = appSettings.languageOverride
        refreshTrigger = UUID() // Force UI refresh
        #if DEBUG
        print("🌐 ContentView: LocalizationManager updated, new refresh trigger: \(refreshTrigger)")
        #endif
    }
    
    var body: some View {
        ZStack {
            if lockState.isLocked && appSettings.biometricLockEnabled {
                LockScreenView()
            } else {
                mainTabView
            }
        }
        .onAppear {
            initializeApp()
        }
        .onChange(of: appSettings.languageOverride) { _, _ in
            updateLocalizationManager()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            handleAppWillEnterForeground()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            handleAppDidEnterBackground()
        }
    }
    
    private var mainTabView: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label(L10n.string("tab_dashboard"), systemImage: "chart.pie.fill")
            }
            
            NavigationStack {
                ExpenseListView()
            }
            .tabItem {
                Label(L10n.string("tab_expenses"), systemImage: "cart.fill")
            }
            
            NavigationStack {
                IncomeListView()
            }
            .tabItem {
                Label(L10n.string("tab_income"), systemImage: "arrow.down.circle.fill")
            }
            
            NavigationStack {
                LoansListView()
            }
            .tabItem {
                Label(L10n.string("tab_loans"), systemImage: "creditcard.fill")
            }
            
            NavigationStack {
                MoreView()
            }
            .tabItem {
                Label(L10n.string("tab_more"), systemImage: "ellipsis.circle.fill")
            }
        }
        .environment(\.horizontalSizeClass, .compact)
        .monetiqBackground()
        .preferredColorScheme(appSettings.appearanceMode.colorScheme)
        .environment(\.locale, effectiveLocale)
        .id(effectiveLanguageKey)
        .id(refreshTrigger)
        .id(appState.resetToken)
    }
    
    private func initializeApp() {
        updateLocalizationManager()
        
        // Initialize lock state based on biometric settings
        lockState.initializeLockState(biometricEnabled: appSettings.biometricLockEnabled)
    }
    
    private func handleAppWillEnterForeground() {
        // Re-initialize lock state when app comes to foreground
        if appSettings.biometricLockEnabled {
            lockState.initializeLockState(biometricEnabled: true)
        }
    }
    
    private func handleAppDidEnterBackground() {
        // Lock the app when it goes to background (if biometrics enabled)
        if appSettings.biometricLockEnabled {
            lockState.lockApp()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Counterparty.self, Loan.self, Payment.self, AppSettings.self], inMemory: true)
}
