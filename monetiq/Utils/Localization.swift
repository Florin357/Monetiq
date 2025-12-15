//
//  Localization.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import Foundation
import SwiftUI

// MARK: - Localization Helper
struct L10n {
    static func string(_ key: String, _ args: CVarArg...) -> String {
        // Use LocalizationManager for language-aware localization
        return LocalizationManager.shared.localizedString(key, args)
    }
    
    // Language-aware localization that respects the current override
    static func localizedString(_ key: String, languageCode: String? = nil, _ args: CVarArg...) -> String {
        guard let languageCode = languageCode, languageCode != "system" else {
            // Use default NSLocalizedString
            let format = NSLocalizedString(key, comment: "")
            return String(format: format, arguments: args)
        }
        
        // Try to get the specific language bundle with proper validation
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              !path.isEmpty,
              let bundle = Bundle(path: path) else {
            // Fallback to default localization
            let format = NSLocalizedString(key, comment: "")
            return String(format: format, arguments: args)
        }
        
        let format = bundle.localizedString(forKey: key, value: key, table: nil)
        return String(format: format, arguments: args)
    }
}

// MARK: - Localization Manager
@Observable
class LocalizationManager {
    static let shared = LocalizationManager()
    
    private init() {}
    
    var currentLanguageCode: String? = nil {
        didSet {
            #if DEBUG
            print("🌐 LocalizationManager: Language changed to \(currentLanguageCode ?? "system")")
            #endif
        }
    }
    
    func localizedString(_ key: String, _ args: CVarArg...) -> String {
        guard let languageCode = currentLanguageCode, languageCode != "system" else {
            let format = NSLocalizedString(key, comment: "")
            return String(format: format, arguments: args)
        }
        
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              !path.isEmpty,
              let bundle = Bundle(path: path) else {
            let format = NSLocalizedString(key, comment: "")
            return String(format: format, arguments: args)
        }
        
        let format = bundle.localizedString(forKey: key, value: key, table: nil)
        
        #if DEBUG
        // Log when a key falls back to itself (missing translation)
        if format == key {
            print("🌐 Missing localization key '\(key)' in language '\(languageCode)'")
        }
        #endif
        
        return String(format: format, arguments: args)
    }
    
    #if DEBUG
    /// Development tool to audit localization completeness
    func auditLocalizations() -> LocalizationAuditResult {
        let supportedLanguages = LanguageCatalog.shared.supportedLanguages
        var result = LocalizationAuditResult()
        
        // Get all keys from base English
        guard let baseStringsPath = Bundle.main.path(forResource: "Localizable", ofType: "strings"),
              let baseStrings = NSDictionary(contentsOfFile: baseStringsPath) as? [String: String] else {
            result.errors.append("Could not load base Localizable.strings")
            return result
        }
        
        let baseKeys = Set(baseStrings.keys)
        result.totalKeys = baseKeys.count
        
        // Check each language
        for language in supportedLanguages {
            if language.code == "system" { continue }
            
            var languageResult = LanguageAuditResult()
            languageResult.languageCode = language.code
            languageResult.languageName = language.name
            
            guard let langPath = Bundle.main.path(forResource: language.code, ofType: "lproj"),
                  !langPath.isEmpty,
                  let langBundle = Bundle(path: langPath),
                  let stringsPath = langBundle.path(forResource: "Localizable", ofType: "strings"),
                  let langStrings = NSDictionary(contentsOfFile: stringsPath) as? [String: String] else {
                languageResult.missingKeys = Array(baseKeys)
                result.languageResults.append(languageResult)
                continue
            }
            
            let langKeys = Set(langStrings.keys)
            languageResult.missingKeys = Array(baseKeys.subtracting(langKeys)).sorted()
            languageResult.extraKeys = Array(langKeys.subtracting(baseKeys)).sorted()
            
            result.languageResults.append(languageResult)
        }
        
        return result
    }
    #endif
}

#if DEBUG
struct LocalizationAuditResult {
    var totalKeys: Int = 0
    var languageResults: [LanguageAuditResult] = []
    var errors: [String] = []
    
    var summary: String {
        var lines: [String] = []
        lines.append("🌐 LOCALIZATION AUDIT SUMMARY")
        lines.append("Total keys in base: \(totalKeys)")
        lines.append("")
        
        if !errors.isEmpty {
            lines.append("❌ ERRORS:")
            for error in errors {
                lines.append("  - \(error)")
            }
            lines.append("")
        }
        
        for langResult in languageResults {
            let completeness = totalKeys > 0 ? Double(totalKeys - langResult.missingKeys.count) / Double(totalKeys) * 100 : 0
            let status = langResult.missingKeys.isEmpty ? "✅" : "⚠️"
            lines.append("\(status) \(langResult.languageName) (\(langResult.languageCode)): \(String(format: "%.1f", completeness))% complete")
            
            if !langResult.missingKeys.isEmpty {
                lines.append("  Missing keys (\(langResult.missingKeys.count)):")
                for key in langResult.missingKeys.prefix(5) {
                    lines.append("    - \(key)")
                }
                if langResult.missingKeys.count > 5 {
                    lines.append("    ... and \(langResult.missingKeys.count - 5) more")
                }
            }
            
            if !langResult.extraKeys.isEmpty {
                lines.append("  Extra keys (\(langResult.extraKeys.count)):")
                for key in langResult.extraKeys.prefix(3) {
                    lines.append("    + \(key)")
                }
                if langResult.extraKeys.count > 3 {
                    lines.append("    ... and \(langResult.extraKeys.count - 3) more")
                }
            }
            lines.append("")
        }
        
        return lines.joined(separator: "\n")
    }
}

struct LanguageAuditResult {
    var languageCode: String = ""
    var languageName: String = ""
    var missingKeys: [String] = []
    var extraKeys: [String] = []
}
#endif

// MARK: - Enum Localization Extensions
extension LoanRole {
    var localizedLabel: String {
        switch self {
        case .lent:
            return L10n.string("role_lent")
        case .borrowed:
            return L10n.string("role_borrowed")
        case .bankCredit:
            return L10n.string("role_bank_credit")
        }
    }
}

extension PaymentStatus {
    var localizedLabel: String {
        switch self {
        case .planned:
            return L10n.string("status_planned")
        case .paid:
            return L10n.string("status_paid")
        case .overdue:
            return L10n.string("status_overdue")
        }
    }
}

extension PaymentFrequency {
    var localizedLabel: String {
        switch self {
        case .weekly:
            return L10n.string("frequency_weekly")
        case .monthly:
            return L10n.string("frequency_monthly")
        case .quarterly:
            return L10n.string("frequency_quarterly")
        case .yearly:
            return L10n.string("frequency_yearly")
        }
    }
}

extension InterestMode {
    var localizedLabel: String {
        switch self {
        case .none:
            return L10n.string("interest_none")
        case .percentageAnnual:
            return L10n.string("interest_percentage")
        case .fixedTotal:
            return L10n.string("interest_fixed")
        }
    }
}

extension CounterpartyType {
    var localizedLabel: String {
        switch self {
        case .person:
            return L10n.string("counterparty_person")
        case .institution:
            return L10n.string("counterparty_institution")
        }
    }
}



