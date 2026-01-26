# Ypsilon Finance Rules & Calculation Standards

**Last Updated:** January 26, 2026  
**Purpose:** Define the single source of truth for all financial calculations in Ypsilon.

**Recent Changes:**
- 2026-01-26: Added Expenses tracking rules (Phase 1)
- 2025-12-20: Updated notification rules (dual notifications)
- 2025-12-20: Updated upcoming window (15 days)

---

## Interest Calculation Modes

### 1. Bank Credit (Role: `bankCredit`)
**Formula:** Amortization using PMT (Present Value Annuity)

```
PMT = P × [r(1+r)^n] / [(1+r)^n - 1]

Where:
- P = Principal amount
- r = Periodic interest rate (APR / periods per year)
- n = Total number of payments
```

**Characteristics:**
- Uses **compound interest** with periodic compounding
- Interest calculated on **remaining balance** each period
- Compounding frequency matches payment frequency (monthly, weekly, etc.)
- Appropriate for bank loans, mortgages, and institutional credits

**Example:**
- Principal: 10,000 RON
- APR: 10% (0.10)
- Frequency: Monthly (12 periods/year)
- Duration: 12 months
- **Expected:** ~879 RON/month, ~10,548 RON total

---

### 2. Annual Percentage Mode (Interest Mode: `percentageAnnual`)
**Formula:** Amortization using PMT (same as Bank Credit)

**Note:** This mode should use **amortized interest**, not simple interest.
- For personal loans between individuals, amortization provides fair and predictable payment schedules
- Matches standard lending practices
- Future: May add "Simple Interest" as a separate option for informal loans

---

### 3. Fixed Total Mode (Interest Mode: `fixedTotal`)
**Formula:** Direct division

```
Payment per period = Fixed Total / Number of Periods
```

**Characteristics:**
- No interest calculation
- User specifies exact total to repay
- Useful for interest-free loans with agreed total
- **Stays as-is** (current implementation is correct)

---

### 4. No Interest Mode (Interest Mode: `none`)
**Formula:** Direct division

```
Payment per period = Principal / Number of Periods
```

**Characteristics:**
- Zero interest
- Simple equal payments
- **Stays as-is** (current implementation is correct)

---

## Rounding Rules

### Currency Precision
**Standard:** All currency amounts MUST be rounded to 2 decimal places (minor units).

**Implementation:**
- Use `Decimal` type for financial calculations (not `Double`)
- Round to 2 decimals BEFORE storage and display
- Apply banker's rounding (round half to even) for fairness

**Example:**
```swift
let amount = Decimal(string: "879.3333")!
let rounded = (amount as NSDecimalNumber).rounding(
    accordingToBehavior: NSDecimalNumberHandler(
        roundingMode: .bankers,
        scale: 2,
        raiseOnExactness: false,
        raiseOnOverflow: false,
        raiseOnUnderflow: false,
        raiseOnDivideByZero: false
    )
) // 879.33
```

### Last Payment Adjustment
The **last payment** in a schedule adjusts for cumulative rounding errors:

```
Last Payment = Total To Repay - Sum(All Previous Payments)
```

This ensures the schedule always sums exactly to the total.

---

## Payment Schedule Rules

### Date Calculation
- Use `Calendar.current.date(byAdding:)` for date arithmetic
- First payment due date = start date + 1 period
- Respect calendar boundaries (e.g., Feb 31 → Feb 28/29)

### Frequency Mapping
| Frequency | Calendar Component | Periods per Year |
|-----------|-------------------|------------------|
| Weekly | `.weekOfYear` | 52 |
| Monthly | `.month` | 12 |
| Quarterly | `.month` (×3) | 4 |
| Yearly | `.year` | 1 |

---

## Data Integrity Rules

### Payment Status Preservation
**CRITICAL:** Paid payments are **IMMUTABLE**.

- Editing a loan MUST NOT delete paid payments
- Paid payments preserve: `paidDate`, `amount`, `status`
- Only **planned** payments may be regenerated on loan edit

### Unique Identifiers
- Every payment has a stable UUID (`payment.id`)
- Payment identity NEVER depends on array index or position
- Safe for deep-linking, notifications, and persistence

---

## Notification Rules

### Upcoming Window (Dashboard + Badge)
**Definition:** Payments are "upcoming" if:
```
status == .planned
AND dueDate >= today
AND dueDate <= today + 15 days
```

**Business Rule:** **15-day window** (updated from 30 days on 2025-12-20)

**Consistency:**
- Dashboard "Upcoming Payments" uses this filter
- Badge count reflects this filter
- **Independent of notification settings** (Days Before Due)
- Single source of truth: `UpcomingPaymentsFilter.swift`

---

### Notification Scheduling

**Business Rule:** Each payment gets **TWO separate notifications**:

#### Notification A: X days before due
- **When:** X = user setting "Days Before Due" (0-7)
- **Condition:** Only schedule if X > 0 AND fireDate >= now
- **Identifier:** `reminder:<loanID>:<paymentID>:<X>`
- **Fire time:** 9:00 AM, X days before due date

#### Notification B: 1 day before due (always)
- **When:** Always, 1 day before due date
- **Condition:** Only schedule if fireDate >= now
- **Identifier:** `oneDay:<loanID>:<paymentID>`
- **Fire time:** 9:00 AM, 1 day before due date

**Important:**
- Notifications are scheduled for **ALL planned payments**, not just the 15-day window
- If a notification's fire date would be in the past, it is **skipped** (not scheduled)
- When a payment is marked as paid or deleted, **both notifications** are canceled

---

### Badge Count Policy

**IMPLEMENTED:** Badge shows upcoming count (15-day window) **regardless of notification settings**

**Rationale:**
- The badge is a **finance reminder**, not just a notification indicator
- Users should always see they have upcoming payments, even if notifications are disabled
- Badge count = upcoming payments count from **data model**, NOT from pending notifications
- Provides consistent user experience across notification preferences

**Implementation:**
```swift
// Badge derives from Payment data model (SOURCE OF TRUTH)
let badgeCount = payments.filter { payment in
    payment.status == .planned &&
    payment.dueDate >= today &&
    payment.dueDate <= today + 15 days
}.count
```

**Alternative (Not Implemented):**
- Option B: Badge = 0 when notifications disabled
- This was rejected because it hides financial obligations from the user

### Postpone/Snooze Behavior
**Rule:** "Postpone 1 day" = **snooze reminder only**

- Does NOT change payment due date
- Does NOT modify payment schedule
- Only reschedules the notification trigger
- Snooze state stored in `payment.snoozeUntil`

**Example:**
- Payment due: Jan 15
- User postpones on Jan 10
- Due date: Still Jan 15 (unchanged)
- Notification: Moved to Jan 11 (1 day snooze)

---

## Validation Rules

### Input Validation
**Principal Amount:**
- MUST be > 0 (reject zero and negative)
- Practical range: 1 – 1,000,000,000 (adjustable)

**Interest Rate (APR):**
- MUST be >= 0 (allow zero)
- Practical range: 0 – 100% (warn above 50%)

**Number of Periods:**
- MUST be >= 1
- Practical range: 1 – 600 (50 years monthly)

**Currency Code:**
- MUST be valid ISO 4217 code
- MUST match loan currency throughout schedule

---

## Edge Cases

### Single Payment (n=1)
- PMT formula still applies
- For 0% interest: payment = principal
- For interest: payment = principal + interest

### Very Small Amounts
- Minimum: 0.01 in currency minor units
- Example: 0.01 RON = 1 ban

### Large Numbers
- Validate calculations remain finite
- Check for overflow/underflow
- Fallback to principal on error

---

## Migration Notes

### Current → Target
**Previous State (v1.0 - v1.0.2):**
- Used simple interest: `P × r × t`
- Incorrect for bank credits and standard loans

**Current State (v1.1+):** ✅ IMPLEMENTED
- Uses amortization: PMT formula
- All new loans use correct calculation
- Existing loans created before v1.1 may show legacy calculations
- Paid payment history always preserved

**Migration Strategy:**
- ✅ New loans automatically use PMT formula
- ✅ Editing existing loans regenerates schedule with correct formula
- ✅ Paid payments are NEVER recalculated (data integrity preserved)
- Future: Optional "recalculate" action for legacy loans in UI

---

## Expenses Tracking Rules

**Implementation Date:** 2026-01-27  
**Version:** v1.1+ (Phase 1.5 - Polished)

### Expense Occurrence Generation

**Business Rule:** Rolling 12-month window for recurring expenses

```
For recurring expenses:
- Generate occurrences from startDate to min(endDate, today + 12 months)
- One-time expenses: Generate single occurrence on startDate
```

**Frequency Mapping:**
| Frequency | Calendar Component | Occurrences/Year |
|-----------|-------------------|------------------|
| One-time | N/A | 1 (single) |
| Weekly | `.weekOfYear` | ~52 |
| Monthly | `.month` | 12 |
| Quarterly | `.month` (×3) | 4 |
| Yearly | `.year` | 1 |

### Expense Completion & Archiving Rules

**Definition:** An expense is "completed" if:
```
(endDate exists AND endDate < today)
OR (frequency == .oneTime AND all occurrences status == .paid)
```

**Definition:** An expense is "archived" if:
```
For one-time:
  expense month < current month (month-based, not day-based)

For recurring:
  (no planned occurrences >= today) OR (endDate < today)
```

**Visual Indicators (Phase 1.5):**
- Active recurring (on-time): Indigo accent + badge
- Active recurring (overdue): Red accent + badge
- Active one-time: Teal accent + badge
- Archived/Completed: Purple accent + badge

**Subscription Age Display:**
- Shows time-based duration: "Subscribed: X months/years"
- Calculated from `startDate` to `today` using `Calendar.dateComponents`
- Formula: `max(1, calculated_periods + 1)` to show "currently in period X"
- Future subscriptions: "Starts in X days"

### Occurrence Preservation

**CRITICAL:** Paid expense occurrences are **IMMUTABLE**.

- Editing an expense MUST NOT delete paid occurrences
- Paid occurrences preserve: `paidDate`, `amount`, `status`
- Only **planned** occurrences may be regenerated on expense edit

### Phase 2 Integration Rules (Planned)

**Dashboard TO PAY:**
```
Sum all ExpenseOccurrence where:
- status == .planned
- dueDate within calculation window
Group by: currencyCode
```

**Upcoming Payments (15-day window):**
```
Include ExpenseOccurrence where:
- status == .planned
- dueDate >= today
- dueDate <= today + 15 days
```

**Cashflow Chart (30-day window):**
```
Include ExpenseOccurrence in "To Pay" line where:
- status == .planned
- dueDate within chart window (today to today + 30 days)
Aggregate by: day
```

**Notifications:**
- Same dual-notification pattern as loan payments:
  - Reminder: X days before due (X = user setting)
  - One-day-before: Always 1 day before due
- Scheduled for ALL planned expense occurrences
- Canceled when occurrence marked as paid or expense deleted

**Status:** Phase 2 integration documented but not yet implemented.

---

## Testing Standards

All calculations MUST pass:
1. **Golden cases** (see GoldenTestCases.md)
2. **Rounding verification** (sum equals total)
3. **Edge case handling** (zero interest, single payment)
4. **Consistency checks** (upcoming = notifications = badge)
5. **Expense schedule generation** (recurring occurrences, one-time handling)

---

**End of Finance Rules**

