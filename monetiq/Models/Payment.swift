//
//  Payment.swift
//  monetiq
//
//  Created by Florin Mihai on 07.12.2025.
//

import Foundation
import SwiftData

@Model
final class Payment {
    var id: UUID
    var dueDate: Date
    var amount: Double
    var status: PaymentStatus
    var paidDate: Date?
    
    // Relationship back to loan
    @Relationship(inverse: \Loan.payments)
    var loan: Loan?
    
    init(
        dueDate: Date,
        amount: Double,
        status: PaymentStatus = .planned,
        paidDate: Date? = nil,
        loan: Loan? = nil
    ) {
        self.id = UUID()
        self.dueDate = dueDate
        self.amount = amount
        self.status = status
        self.paidDate = paidDate
        self.loan = loan
    }
    
    var isOverdue: Bool {
        status == .planned && dueDate < Date()
    }
    
    func markAsPaid() {
        status = .paid
        paidDate = Date()
    }
}

enum PaymentStatus: String, CaseIterable, Codable {
    case planned = "planned"
    case paid = "paid"
    case overdue = "overdue"
    
    var displayName: String {
        switch self {
        case .planned:
            return "Planned"
        case .paid:
            return "Paid"
        case .overdue:
            return "Overdue"
        }
    }
}
