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
        let format = NSLocalizedString(key, comment: "")
        return String(format: format, arguments: args)
    }
    
    // Language-aware localization that respects the current override
    static func localizedString(_ key: String, languageCode: String? = nil, _ args: CVarArg...) -> String {
        guard let languageCode = languageCode, languageCode != "system" else {
            // Use default NSLocalizedString
            let format = NSLocalizedString(key, comment: "")
            return String(format: format, arguments: args)
        }
        
        // Try to get the specific language bundle
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            // Fallback to default
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
              let bundle = Bundle(path: path) else {
            let format = NSLocalizedString(key, comment: "")
            return String(format: format, arguments: args)
        }
        
        let format = bundle.localizedString(forKey: key, value: key, table: nil)
        return String(format: format, arguments: args)
    }
}

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



