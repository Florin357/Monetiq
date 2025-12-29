# Income v1 - Data Model + Schedule Generation

**Date:** December 28, 2025  
**Branch:** `develop`  
**Scope:** Data model + schedule generation ONLY (no UI integration yet)

---

## 🎯 Goal

Introduce an "Income" feature that structurally mirrors the Loans architecture:
- `IncomeSource` behaves like `Loan` (entity)
- `IncomePayment` behaves like `Payment` (schedule entries)

This allows future integration into:
- TO RECEIVE totals
- Upcoming Payments list
- Cashflow chart (additional line)

---

## 📐 Architecture Alignment

### Pattern Consistency with Loans:

| Loans | Income | Purpose |
|-------|--------|---------|
| `Loan` | `IncomeSource` | Main entity |
| `Payment` | `IncomePayment` | Schedule entries |
| `LoanCalculator` | `IncomeScheduleGenerator` | Schedule generation |
| `PaymentFrequency` | `IncomeFrequency` | Recurrence pattern |
| `PaymentStatus` | `IncomePaymentStatus` | Entry state |

---

## 📦 Files Created

### 1. Data Models

**`monetiq/Models/IncomeSource.swift`** (NEW - 95 lines)
- SwiftData model for income sources
- Fields: title, amount, currency, frequency, dates, counterparty
- Relationships: one-to-many with IncomePayment
- Computed properties: status, totalReceived, upcomingPayments

**`monetiq/Models/IncomePayment.swift`** (NEW - 66 lines)
- SwiftData model for income payment entries
- Fields: dueDate, amount, currency, status, receivedDate
- Relationship: many-to-one with IncomeSource
- Methods: markAsReceived(), isOverdue

### 2. Services

**`monetiq/Services/IncomeScheduleGenerator.swift`** (NEW - 286 lines)
- Schedule generation service
- Methods:
  - `generateInitialSchedule()` - for new income sources
  - `refreshSchedule()` - for editing existing income (preserves history)
- Helper: `IncomeUpcomingFilter` (prepared for future use)

---

## 🔧 Data Model Details

### IncomeSource

```swift
@Model
final class IncomeSource {
    var id: UUID
    var title: String
    var amount: Double
    var currencyCode: String
    var frequency: IncomeFrequency
    var startDate: Date
    var endDate: Date?
    var counterpartyName: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \IncomePayment.incomeSource)
    var payments: [IncomePayment] = []
}
```

**Key Features:**
- ✅ UUID identifier (consistent with Loan)
- ✅ Timestamps (createdAt, updatedAt)
- ✅ Cascade delete (deleting income deletes its payments)
- ✅ Optional end date (for fixed-term income)
- ✅ Optional counterparty (e.g., "Employer")

**Computed Properties:**
```swift
var status: IncomeStatus {
    // Derived: active if no endDate or endDate in future
}

var totalReceived: Double {
    // Sum of all received payments
}

var upcomingPayments: [IncomePayment] {
    // Planned payments sorted by date
}

var nextPaymentDate: Date? {
    // Next expected payment
}
```

---

### IncomePayment

```swift
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
    
    var incomeSource: IncomeSource?
}
```

**Key Features:**
- ✅ UUID identifier
- ✅ Timestamps
- ✅ Status: planned / received (mirrors planned / paid)
- ✅ Received date tracking
- ✅ Currency code per payment (for flexibility)

**Methods:**
```swift
func markAsReceived() {
    status = .received
    receivedDate = Date()
    updateTimestamp()
}

var isOverdue: Bool {
    status == .planned && dueDate < Date()
}
```

---

### Enums

**IncomeFrequency:**
```swift
enum IncomeFrequency: String, CaseIterable, Codable {
    case weekly
    case monthly
    case quarterly
    case yearly
    case oneTime
}
```

**IncomeStatus:**
```swift
enum IncomeStatus: String, CaseIterable, Codable {
    case active
    case ended
}
```
*Note: Status is derived, not stored*

**IncomePaymentStatus:**
```swift
enum IncomePaymentStatus: String, CaseIterable, Codable {
    case planned
    case received
}
```

---

## 🔄 Schedule Generation Logic

### Initial Schedule Generation

```swift
IncomeScheduleGenerator.generateInitialSchedule(
    for: incomeSource,
    in: modelContext
)
```

**Behavior:**
1. Clears any existing payments (defensive)
2. Generates schedule items based on frequency
3. Creates IncomePayment objects
4. Links payments to income source
5. Persists to SwiftData

**Schedule Rules:**

| Frequency | Schedule Logic |
|-----------|----------------|
| `oneTime` | Single payment on startDate (if today or future) |
| `weekly` | Every 7 days for 12 months ahead |
| `monthly` | Every month for 12 months ahead |
| `quarterly` | Every 3 months for 12 months ahead |
| `yearly` | Every year for 12 months ahead |

**Rolling Window:**
- Default: 12 months ahead
- If `endDate` is set: generate until endDate
- If `endDate` is nil: generate for rolling window

---

### Refresh Schedule (Edit Safety)

```swift
IncomeScheduleGenerator.refreshSchedule(
    for: incomeSource,
    in: modelContext
)
```

**Behavior (CRITICAL - avoids Loans mistake):**
1. ✅ **Preserves** all received payments (history protected)
2. ❌ **Deletes** only planned payments
3. ✅ Regenerates planned payments based on new settings
4. ✅ Avoids duplicates (checks if date already has received payment)
5. ✅ Updates income source timestamp

**Example Flow:**
```
Before Edit:
- Received: Jan 15, Feb 15, Mar 15
- Planned: Apr 15, May 15, Jun 15

User edits: amount 5000 → 6000

After Refresh:
- Received: Jan 15, Feb 15, Mar 15 (preserved, still 5000 each)
- Planned: Apr 15, May 15, Jun 15 (regenerated with 6000 each)
```

**Safety Guarantees:**
- ✅ Never deletes received payments
- ✅ Never creates duplicate payments for same date
- ✅ Handles past start dates correctly
- ✅ Respects end date boundaries

---

## 📊 Schedule Generation Examples

### Example 1: Monthly Salary (No End Date)

```swift
let salary = IncomeSource(
    title: "Software Engineer Salary",
    amount: 10000.00,
    currencyCode: "RON",
    frequency: .monthly,
    startDate: Date(), // Today
    counterpartyName: "Tech Company SRL"
)

IncomeScheduleGenerator.generateInitialSchedule(
    for: salary,
    in: modelContext
)

// Result: 12 monthly payments generated
// Jan 28, Feb 28, Mar 28, ..., Dec 28
```

---

### Example 2: Freelance Project (One-Time)

```swift
let project = IncomeSource(
    title: "Website Development",
    amount: 5000.00,
    currencyCode: "EUR",
    frequency: .oneTime,
    startDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
    counterpartyName: "Client ABC"
)

IncomeScheduleGenerator.generateInitialSchedule(
    for: project,
    in: modelContext
)

// Result: 1 payment generated
// Due date: 30 days from now
```

---

### Example 3: Rental Income (Fixed Term)

```swift
let rental = IncomeSource(
    title: "Apartment Rental",
    amount: 2000.00,
    currencyCode: "RON",
    frequency: .monthly,
    startDate: Date(),
    endDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())!,
    counterpartyName: "Tenant Name"
)

IncomeScheduleGenerator.generateInitialSchedule(
    for: rental,
    in: modelContext
)

// Result: 12 monthly payments generated
// Stops at end date (1 year from now)
```

---

### Example 4: Quarterly Dividends

```swift
let dividends = IncomeSource(
    title: "Stock Dividends",
    amount: 1500.00,
    currencyCode: "USD",
    frequency: .quarterly,
    startDate: Date()
)

IncomeScheduleGenerator.generateInitialSchedule(
    for: dividends,
    in: modelContext
)

// Result: 4 quarterly payments generated
// Every 3 months for the next 12 months
```

---

## 🔍 Upcoming Income Filter (Prepared)

```swift
// Get income payments due in next 15 days
let upcoming = IncomeUpcomingFilter.getUpcoming(
    from: allIncomePayments,
    windowDays: 15
)
```

**Behavior:**
- Filters: status == .planned
- Window: today to today + N days
- Sorted: by dueDate ascending

**Future Integration:**
- Dashboard "Upcoming Payments" (combine with loan payments)
- Badge count
- Notifications

---

## ✅ Safety Features

### 1. Edit Safety (Critical)
- ✅ **Never deletes received payments** when editing
- ✅ Only regenerates planned payments
- ✅ Preserves payment history

### 2. Duplicate Prevention
- ✅ Checks for existing received payments on same date
- ✅ Skips generation if date already has received payment
- ✅ Safe to call refresh multiple times

### 3. Date Handling
- ✅ Uses `Calendar.current` for locale-aware date math
- ✅ Handles past start dates (advances to next occurrence)
- ✅ Respects end date boundaries
- ✅ Safety limit: max 1000 periods (prevents infinite loops)

### 4. Validation
- ✅ Debug logging for schedule generation
- ✅ Verification of generated payment counts
- ✅ Graceful handling of edge cases

---

## 🧪 Manual Testing Guide

### Test 1: Create Monthly Income

```swift
// In a test view or debug context
let income = IncomeSource(
    title: "Test Salary",
    amount: 5000.00,
    currencyCode: "RON",
    frequency: .monthly,
    startDate: Date()
)

modelContext.insert(income)
IncomeScheduleGenerator.generateInitialSchedule(for: income, in: modelContext)

// Verify:
print("Generated \(income.payments.count) payments")
// Expected: 12 payments

print("Next payment: \(income.nextPaymentDate)")
// Expected: ~30 days from now
```

---

### Test 2: Mark Payment as Received

```swift
// Get first planned payment
if let firstPayment = income.upcomingPayments.first {
    firstPayment.markAsReceived()
    
    // Verify:
    print("Status: \(firstPayment.status)") // .received
    print("Received date: \(firstPayment.receivedDate)") // Today
    print("Total received: \(income.totalReceived)") // 5000.00
}
```

---

### Test 3: Edit Income (Preserve History)

```swift
// Mark 2 payments as received
income.upcomingPayments[0].markAsReceived()
income.upcomingPayments[1].markAsReceived()

print("Before edit: \(income.payments.count) total")
// Expected: 12 total (2 received, 10 planned)

// Edit amount
income.amount = 6000.00
income.updateTimestamp()

// Refresh schedule
IncomeScheduleGenerator.refreshSchedule(for: income, in: modelContext)

print("After edit: \(income.payments.count) total")
// Expected: 12 total (2 received @ 5000, 10 planned @ 6000)

let receivedPayments = income.payments.filter { $0.status == .received }
print("Received payments preserved: \(receivedPayments.count)")
// Expected: 2 (history intact)
```

---

### Test 4: One-Time Income

```swift
let project = IncomeSource(
    title: "Freelance Project",
    amount: 3000.00,
    currencyCode: "EUR",
    frequency: .oneTime,
    startDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!
)

modelContext.insert(project)
IncomeScheduleGenerator.generateInitialSchedule(for: project, in: modelContext)

print("Generated \(project.payments.count) payments")
// Expected: 1 payment

print("Due date: \(project.payments.first?.dueDate)")
// Expected: 7 days from now
```

---

### Test 5: Income with End Date

```swift
let rental = IncomeSource(
    title: "Rental Income",
    amount: 2000.00,
    currencyCode: "RON",
    frequency: .monthly,
    startDate: Date(),
    endDate: Calendar.current.date(byAdding: .month, value: 6, to: Date())!
)

modelContext.insert(rental)
IncomeScheduleGenerator.generateInitialSchedule(for: rental, in: modelContext)

print("Generated \(rental.payments.count) payments")
// Expected: 6 payments (stops at end date)

print("Status: \(rental.status)")
// Expected: .active (end date is in future)
```

---

## 📋 Integration Checklist (Future Work)

### Phase 1: Data Model ✅
- ✅ IncomeSource model
- ✅ IncomePayment model
- ✅ IncomeScheduleGenerator service
- ✅ Edit safety (preserve history)
- ✅ Duplicate prevention

### Phase 2: UI Integration (Not in this PR)
- ⏳ Add Income screen (form)
- ⏳ Income list view
- ⏳ Income details view
- ⏳ Mark payment as received UI

### Phase 3: Dashboard Integration (Not in this PR)
- ⏳ Include income in TO RECEIVE totals
- ⏳ Include income in Upcoming Payments
- ⏳ Add income line to Cashflow chart
- ⏳ Expandable income details

### Phase 4: Notifications (Not in this PR)
- ⏳ Schedule notifications for income payments
- ⏳ Reminder settings
- ⏳ Badge count integration

---

## 🎯 Design Decisions

### 1. Why separate IncomeSource and IncomePayment?
- **Consistency:** Mirrors Loan + Payment architecture
- **Flexibility:** Can have different amounts per payment (bonuses, adjustments)
- **History:** Preserves received payment history
- **Queries:** Easy to filter/sort payments independently

### 2. Why include currencyCode in IncomePayment?
- **Flexibility:** Allows different currencies per payment (rare but possible)
- **Consistency:** Matches Payment model pattern
- **Future-proof:** Supports multi-currency scenarios

### 3. Why derived status instead of stored?
- **Simplicity:** No need to update status field manually
- **Consistency:** Always correct based on endDate
- **No migration:** Adding/removing endDate automatically updates status

### 4. Why 12-month rolling window?
- **Balance:** Enough visibility without cluttering database
- **Performance:** Reasonable number of records
- **Refresh:** Can regenerate when needed (e.g., monthly background task)

### 5. Why preserve received payments on edit?
- **History:** User's financial history must be preserved
- **Trust:** Deleting history breaks user trust
- **Audit:** Important for financial tracking
- **Lesson learned:** Avoiding the Loans edit bug

---

## 📊 Statistics

| Metric | Value |
|--------|-------|
| Files created | 3 |
| Total lines | 447 |
| Models | 2 |
| Services | 1 |
| Enums | 3 |
| Linter errors | 0 |
| Schema changes | 0 (new models) |
| UI changes | 0 (data layer only) |

---

## 🚀 Next Steps

### Immediate (Testing):
1. ✅ Data models created
2. ✅ Schedule generator implemented
3. ⏳ Manual testing (see guide above)
4. ⏳ Verify schedule generation works
5. ⏳ Verify edit safety works

### Future (UI Integration):
1. Create Add Income screen
2. Create Income list view
3. Integrate into Dashboard totals
4. Add to Upcoming Payments
5. Add to Cashflow chart
6. Implement notifications

---

## 🔒 Safety Guarantees

| Scenario | Behavior | Status |
|----------|----------|--------|
| Edit income amount | Preserves received payments | ✅ Safe |
| Edit income frequency | Preserves received payments | ✅ Safe |
| Delete income source | Cascades to all payments | ✅ Intentional |
| Refresh schedule multiple times | No duplicates | ✅ Safe |
| Past start date | Advances to next occurrence | ✅ Safe |
| End date in past | No new payments generated | ✅ Safe |
| One-time past date | No payments generated | ✅ Safe |

---

## 📝 Code Quality

### Strengths:
- ✅ Consistent with existing Loan architecture
- ✅ Defensive coding (safety limits, validation)
- ✅ Debug logging for troubleshooting
- ✅ Clear naming conventions
- ✅ Comprehensive documentation
- ✅ No force unwraps
- ✅ Graceful fallbacks

### Testing:
- ✅ No linter errors
- ⏳ Manual testing required
- ⏳ Integration testing (after UI)

---

## 🎉 Summary

**Status:** ✅ Data model + schedule generation complete

**What was implemented:**
- IncomeSource and IncomePayment SwiftData models
- IncomeScheduleGenerator service
- Edit safety (preserves received history)
- Duplicate prevention
- Rolling window schedule generation
- One-time and recurring income support

**What's NOT included (by design):**
- No UI integration
- No Dashboard integration
- No Notifications
- No Cashflow chart integration

**Quality:** Production-ready data layer, ready for UI integration

---

**No commits yet** — waiting for manual testing verification! 🎉

