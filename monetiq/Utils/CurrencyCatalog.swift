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
}
