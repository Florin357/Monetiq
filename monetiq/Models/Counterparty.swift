//
//  Counterparty.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import Foundation
import SwiftData

@Model
final class Counterparty {
    var id: UUID
    var name: String
    var type: CounterpartyType
    var notes: String?
    
    // Relationship to loans
    @Relationship(deleteRule: .cascade, inverse: \Loan.counterparty)
    var loans: [Loan] = []
    
    init(name: String, type: CounterpartyType, notes: String? = nil) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.notes = notes
    }
}

enum CounterpartyType: String, CaseIterable, Codable {
    case person = "person"
    case institution = "institution"
    
    var displayName: String {
        switch self {
        case .person:
            return "Person"
        case .institution:
            return "Institution"
        }
    }
}
