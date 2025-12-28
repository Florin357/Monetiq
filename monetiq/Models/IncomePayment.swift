//
//  IncomePayment.swift
//  monetiq
//
//  Created by Florin Mihai on 28.12.2025.
//

import Foundation
import SwiftData

@Model
final class IncomePayment {
    var id: UUID
    var dueDate: Date
    var amount: Double
    var currencyCode: String
    var status: IncomePaymentStatus
    var receivedDate: Date?
    var createdAt: Date
    var updatedAt: Date
    
    // Relationship back to income source
    var incomeSource: IncomeSource?
    
    init(
        dueDate: Date,
        amount: Double,
        currencyCode: String,
        status: IncomePaymentStatus = .planned,
        receivedDate: Date? = nil,
        incomeSource: IncomeSource? = nil
    ) {
        self.id = UUID()
        self.dueDate = dueDate
        self.amount = amount
        self.currencyCode = currencyCode
        self.status = status
        self.receivedDate = receivedDate
        self.incomeSource = incomeSource
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func updateTimestamp() {
        self.updatedAt = Date()
    }
    
    /// Mark this payment as received
    func markAsReceived() {
        status = .received
        receivedDate = Date()
        updateTimestamp()
    }
    
    /// Check if this payment is overdue (planned but past due date)
    var isOverdue: Bool {
        status == .planned && dueDate < Date()
    }
}

enum IncomePaymentStatus: String, CaseIterable, Codable {
    case planned = "planned"
    case received = "received"
}

