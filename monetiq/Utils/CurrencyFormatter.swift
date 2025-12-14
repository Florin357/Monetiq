//
//  CurrencyFormatter.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import Foundation

struct CurrencyFormatter {
    
    // MARK: - Shared Instance
    static let shared = CurrencyFormatter()
    
    private init() {}
    
    // MARK: - Formatting Methods
    
    /// Format amount with currency code
    func format(amount: Double, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        
        let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? "0.00"
        return "\(formattedAmount) \(currencyCode)"
    }
    
    /// Format amount with currency code using locale-aware formatting
    func formatLocalized(amount: Double, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale.current
        
        let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? "0.00"
        return "\(formattedAmount) \(currencyCode)"
    }
    
    /// Format amount for display in lists and cards
    func formatCompact(amount: Double, currencyCode: String) -> String {
        if amount >= 1_000_000 {
            let millions = amount / 1_000_000
            return String(format: "%.1fM %@", millions, currencyCode)
        } else if amount >= 1_000 {
            let thousands = amount / 1_000
            return String(format: "%.1fK %@", thousands, currencyCode)
        } else {
            return format(amount: amount, currencyCode: currencyCode)
        }
    }
    
    /// Get currency symbol for common currencies
    func symbol(for currencyCode: String) -> String {
        return CurrencyCatalog.shared.symbol(for: currencyCode.uppercased())
    }
    
    /// Format with symbol instead of code
    func formatWithSymbol(amount: Double, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale.current
        
        let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? "0.00"
        let symbol = self.symbol(for: currencyCode)
        
        // For RON, put symbol after amount; for others, before
        if currencyCode.uppercased() == "RON" {
            return "\(formattedAmount) \(symbol)"
        } else {
            return "\(symbol)\(formattedAmount)"
        }
    }
}

// MARK: - Convenience Extensions
extension Double {
    func formatted(currency: String) -> String {
        return CurrencyFormatter.shared.format(amount: self, currencyCode: currency)
    }
    
    func formattedCompact(currency: String) -> String {
        return CurrencyFormatter.shared.formatCompact(amount: self, currencyCode: currency)
    }
    
    func formattedWithSymbol(currency: String) -> String {
        return CurrencyFormatter.shared.formatWithSymbol(amount: self, currencyCode: currency)
    }
}



