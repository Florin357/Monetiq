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
    /// Uses German-style separators: dot for thousands, comma for decimals
    /// Example: 10000 → "10.000,00 EUR"
    func format(amount: Double, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "."  // Dot for thousands (German style)
        formatter.decimalSeparator = ","   // Comma for decimals (German style)
        
        let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? "0,00"
        return "\(formattedAmount) \(currencyCode)"
    }
    
    /// Format amount with currency code using German-style formatting
    /// (kept for compatibility, but now uses same format as main method)
    func formatLocalized(amount: Double, currencyCode: String) -> String {
        // Use consistent German-style formatting across the app
        return format(amount: amount, currencyCode: currencyCode)
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
    
    /// Format amount only (without currency code)
    /// Uses German-style separators: dot for thousands, comma for decimals
    /// Example: 10000 → "10.000,00"
    func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "."  // Dot for thousands (German style)
        formatter.decimalSeparator = ","   // Comma for decimals (German style)
        
        return formatter.string(from: NSNumber(value: amount)) ?? "0,00"
    }
    
    /// Format a numeric string for display in input fields
    /// Converts any valid input (10000, 10000.00, 10000,00, etc.) to German-style format (10.000,00)
    /// Returns the formatted string, or the original if parsing fails
    func formatInputForDisplay(_ input: String) -> String {
        // Parse the input to a Double
        guard let value = parseNumericInput(input) else {
            return input // Return original if invalid
        }
        
        // Format using German-style separators
        return formatAmount(value)
    }
    
    /// Parse numeric input that may contain various separators
    /// Accepts: 10000, 10000.00, 10000,00, 10.000,00, 10,000.00
    /// Returns Double value or nil if invalid
    private func parseNumericInput(_ input: String) -> Double? {
        // Remove spaces
        var normalized = input.replacingOccurrences(of: " ", with: "")
        
        // Count separators to determine intent
        let commaCount = normalized.filter { $0 == "," }.count
        let dotCount = normalized.filter { $0 == "." }.count
        
        // If both exist, assume the last one is decimal separator
        if commaCount > 0 && dotCount > 0 {
            // Find last separator
            if let lastCommaIndex = normalized.lastIndex(of: ","),
               let lastDotIndex = normalized.lastIndex(of: ".") {
                if lastCommaIndex > lastDotIndex {
                    // Comma is decimal separator, remove dots (thousand separators)
                    normalized = normalized.replacingOccurrences(of: ".", with: "")
                    normalized = normalized.replacingOccurrences(of: ",", with: ".")
                } else {
                    // Dot is decimal separator, remove commas (thousand separators)
                    normalized = normalized.replacingOccurrences(of: ",", with: "")
                }
            }
        } else if commaCount > 0 {
            // Only commas: if single comma, treat as decimal; if multiple, remove all (thousand separators)
            if commaCount == 1 {
                normalized = normalized.replacingOccurrences(of: ",", with: ".")
            } else {
                normalized = normalized.replacingOccurrences(of: ",", with: "")
            }
        } else if dotCount > 1 {
            // Multiple dots: treat as thousand separators, remove all
            normalized = normalized.replacingOccurrences(of: ".", with: "")
        }
        // If single dot, keep as is (decimal separator)
        
        return Double(normalized)
    }
    
    /// Get currency symbol for common currencies
    func symbol(for currencyCode: String) -> String {
        return CurrencyCatalog.shared.symbol(for: currencyCode.uppercased())
    }
    
    /// Format with symbol instead of code
    /// Uses German-style separators: dot for thousands, comma for decimals
    func formatWithSymbol(amount: Double, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "."  // Dot for thousands (German style)
        formatter.decimalSeparator = ","   // Comma for decimals (German style)
        
        let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? "0,00"
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



