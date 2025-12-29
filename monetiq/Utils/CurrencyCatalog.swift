//
//  CurrencyCatalog.swift
//  monetiq
//
//  Created by Florin Mihai on 14.12.2025.
//

import Foundation

struct Currency {
    let code: String
    let name: String
    let symbol: String
    
    var displayName: String {
        return "\(code) – \(name)"
    }
    
    /// Returns the flag emoji for this currency's primary country
    var flag: String {
        return CurrencyCatalog.shared.flag(for: code)
    }
}

struct CurrencyCatalog {
    static let shared = CurrencyCatalog()
    
    private init() {}
    
    let supportedCurrencies: [Currency] = [
        Currency(code: "RON", name: "Romanian Leu", symbol: "lei"),
        Currency(code: "EUR", name: "Euro", symbol: "€"),
        Currency(code: "USD", name: "US Dollar", symbol: "$"),
        Currency(code: "GBP", name: "British Pound", symbol: "£"),
        Currency(code: "CHF", name: "Swiss Franc", symbol: "CHF"),
        Currency(code: "CAD", name: "Canadian Dollar", symbol: "C$"),
        Currency(code: "AUD", name: "Australian Dollar", symbol: "A$"),
        Currency(code: "CNY", name: "Chinese Yuan", symbol: "¥"),
        Currency(code: "INR", name: "Indian Rupee", symbol: "₹"),
        Currency(code: "RUB", name: "Russian Ruble", symbol: "₽")
    ]
    
    func currency(for code: String) -> Currency? {
        return supportedCurrencies.first { $0.code == code }
    }
    
    func symbol(for code: String) -> String {
        return currency(for: code)?.symbol ?? code
    }
    
    func name(for code: String) -> String {
        return currency(for: code)?.name ?? code
    }
    
    func displayName(for code: String) -> String {
        return currency(for: code)?.displayName ?? code
    }
    
    var currencyCodes: [String] {
        return supportedCurrencies.map { $0.code }
    }
    
    /// Returns the flag emoji for a given currency code
    /// Maps currency to its primary country/region
    func flag(for code: String) -> String {
        switch code {
        case "RON": return "🇷🇴" // Romania
        case "EUR": return "🇪🇺" // European Union
        case "USD": return "🇺🇸" // United States
        case "GBP": return "🇬🇧" // United Kingdom
        case "CHF": return "🇨🇭" // Switzerland
        case "CAD": return "🇨🇦" // Canada
        case "AUD": return "🇦🇺" // Australia
        case "CNY": return "🇨🇳" // China
        case "INR": return "🇮🇳" // India
        case "RUB": return "🇷🇺" // Russia
        default: return "🌐" // Fallback: globe icon
        }
    }
}
