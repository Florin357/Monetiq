# Payment Identity Strategy

**Purpose:** Document how payments are uniquely identified throughout the app.  
**Status:** Implemented and verified  
**Date:** December 17, 2025

---

## Overview

Every payment in Monetiq has a **stable, unique UUID** (`payment.id`) that is:
- Generated once at payment creation
- Never changes during the payment's lifetime
- Used as the primary key for all references and lookups

---

## Implementation Details

### Model Layer

**File:** `monetiq/Models/Payment.swift`

```swift
@Model
final class Payment {
    var id: UUID              // ✅ Primary stable identifier
    var dueDate: Date         // Used for sorting, NOT identity
    var amount: Double
    var status: PaymentStatus
    var paidDate: Date?
    var snoozeUntil: Date?
    var loan: Loan?
    
    init(dueDate: Date, amount: Double, ...) {
        self.id = UUID()      // ✅ Generated once, never changes
        // ...
    }
}
```

**Rules:**
- `id` is set in `init()` and never modified
- `dueDate` is used for sorting and display, NOT for identity
- `paidDate` is metadata, NOT identity

---

## Usage Throughout the App

### ✅ CORRECT: Using `payment.id`

#### Dashboard (DashboardView.swift)
```swift
struct UpcomingPaymentItem: Identifiable {
    let id: String
    let paymentReference: UUID  // payment.id stored
    
    init(payment: Payment, ...) {
        self.paymentReference = payment.id
        self.id = payment.id.uuidString  // ✅ Stable key
    }
}
```

#### Loan Details (LoanDetailView.swift)
```swift
ScrollView {
    ForEach(payments) { payment in
        PaymentRowView(payment: payment)
            .id("payment-\(payment.id)")  // ✅ Stable scroll target
    }
}

// Scroll to specific payment
proxy.scrollTo("payment-\(payment.id)", anchor: .center)
```

#### Notifications (NotificationManager.swift)
```swift
// Notification identifier uses payment UUID
let identifier = "payment_\(payment.loan?.id.uuidString ?? "unknown")_\(payment.id.uuidString)"

// Cancel notification by payment ID
let notificationId = "payment_*_\(payment.id.uuidString)"
```

---

### ❌ INCORRECT: DO NOT USE

#### Bad: Using array index
```swift
// ❌ WRONG - index changes when array is sorted or filtered
let payment = loan.payments[index]
modelContext.delete(payment)
```

#### Bad: Using dueDate as primary key
```swift
// ❌ WRONG - multiple payments can have same dueDate
let payment = loan.payments.first(where: { $0.dueDate == targetDate })
```

#### Bad: Position-dependent logic
```swift
// ❌ WRONG - position changes when payments are added/removed
if loan.payments.firstIndex(of: payment) == 0 {
    // This is fragile!
}
```

---

## Data Integrity Rules

### 1. Payment Identity is IMMUTABLE
- Once a payment is created with a UUID, that UUID NEVER changes
- Even if the payment is edited (amount, status, dueDate), the UUID stays the same
- This allows stable references across the app

### 2. Paid Payments are IMMUTABLE
- When a payment is marked as paid (`status = .paid`, `paidDate` set), it becomes IMMUTABLE
- Editing the parent loan MUST NOT delete or modify paid payments
- Only **planned** payments may be regenerated when loan schedule changes

**Implementation:** See `AddEditLoanView.swift` lines 358-396

```swift
// DATA INTEGRITY: Preserve paid payments, only delete planned payments
if scheduleParametersChanged {
    let paidPayments = loan.payments.filter { $0.status == .paid }
    let plannedPayments = loan.payments.filter { $0.status == .planned }
    
    // Delete only planned payments
    for payment in plannedPayments {
        modelContext.delete(payment)
    }
    
    // Paid payments remain untouched - their IDs and data are preserved
}
```

### 3. Cosmetic Edits Don't Touch Payments
- If only cosmetic fields change (title, notes, counterparty), payments are NOT regenerated
- This prevents unnecessary churn and preserves all payment metadata (including snooze state)

---

## Finding Payments

### By UUID (Preferred)
```swift
// ✅ Best: Direct lookup by stable UUID
let targetId = payment.id
let found = loan.payments.first(where: { $0.id == targetId })
```

### By Date (Fallback Only)
```swift
// ⚠️ Use only when UUID is not available
// Note: Multiple payments may have same dueDate
let found = loan.payments.filter { $0.dueDate == targetDate }
```

### By Status
```swift
// ✅ Good for filtering
let unpaidPayments = loan.payments.filter { $0.status == .planned }
let paidPayments = loan.payments.filter { $0.status == .paid }
```

---

## Scroll and Focus Behavior

### LoanDetailView
Uses `payment.id` to scroll to specific payments:

```swift
// ✅ Stable scroll target
.id("payment-\(payment.id)")

// ✅ Scroll to by UUID
proxy.scrollTo("payment-\(payment.id)", anchor: .center)
```

**Why this works:**
- Payment IDs never change, even if the list is re-sorted
- Adding/removing payments doesn't affect scroll targets
- Works across app restarts (if payment is saved)

---

## Notification Identifiers

### Format
```
payment_{loanId}_{paymentId}
snooze_{paymentId}
```

**Examples:**
```
payment_A1B2C3D4-..._E5F6G7H8-...
snooze_E5F6G7H8-...
```

**Rules:**
- Always include payment UUID in notification identifier
- Use consistent format for easy filtering
- Allow cancellation by payment ID without full notification identifier

---

## Testing Payment Identity

### Manual Test Cases

**TC-ID-01: Payment UUID Stability**
1. Create loan with 12 payments
2. Record UUID of first payment
3. Mark payment 1 as paid
4. Restart app
5. Verify payment 1 still has same UUID

**TC-ID-02: Paid Payment Preservation**
1. Create loan with 12 payments
2. Mark payments 1-3 as paid
3. Record UUIDs of paid payments
4. Edit loan (change title only)
5. Verify payments 1-3 still exist with same UUIDs

**TC-ID-03: Scroll Target Stability**
1. Create loan with 100 payments
2. Scroll to payment #50
3. Mark payment #10 as paid
4. Schedule regenerates (adds/removes payments)
5. Verify scroll to payment #50 still works

---

## Migration Notes

**Current State:** ✅ Fully implemented
- All views use `payment.id` correctly
- No index-based lookups exist
- Paid payment preservation implemented in edit flow

**No migration needed.**

---

## Related Documentation
- [FinanceRules.md](./FinanceRules.md) - Payment calculation rules
- [GoldenTestCases.md](./GoldenTestCases.md) - Test case TC-D02 validates payment identity

---

**Last Updated:** December 17, 2025  
**Status:** ✅ Production-ready

