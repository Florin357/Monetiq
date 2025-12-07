//
//  Localization.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import Foundation

// MARK: - Localization Helper
struct L10n {
    static func string(_ key: String, _ args: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: "")
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
