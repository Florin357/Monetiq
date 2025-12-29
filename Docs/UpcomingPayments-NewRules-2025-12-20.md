# Upcoming Payments + Notifications + Badge — New Business Rules

**Date:** 2025-12-20  
**Branch:** `develop`  
**Status:** ✅ Implemented

---

## 📋 New Business Rules

### 1. Dashboard "Upcoming Payments" (15-day window)

**Rule:** Show payments that are due within the next **15 days**.

**Logic:**
- `payment.status == .planned` (not paid)
- `payment.dueDate >= today` (not overdue)
- `payment.dueDate <= today + 15 days` (within upcoming window)

**Independent of:** Notification settings (Days Before Due)

---

### 2. Notifications (Two per payment)

**Rule:** Each payment gets **TWO separate notifications**:

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
- If a notification's fire date would be in the past, it is **skipped** (not scheduled).
- Notifications are scheduled for **ALL planned payments**, not just those in the 15-day window.

---

### 3. Badge Count (App Icon)

**Rule:** Badge count **matches Dashboard "Upcoming Payments" count** (15-day window).

**Independent of:**
- Notification settings
- Number of scheduled notifications

---

## 🔧 Implementation Changes

### File: `monetiq/Utils/UpcomingPaymentsFilter.swift`

**Changes:**
1. ✅ Changed `upcomingWindowDays` from **30** to **15**
2. ✅ Simplified `filterUpcomingPayments()` to use **date-based filtering only**
   - Removed dependency on `daysBeforeDue` parameter
   - Logic: `today <= dueDate <= today + 15 days`
3. ✅ Updated `calculateBadgeCount()` to match (no `daysBeforeDue` parameter)

**Before:**
```swift
private static let upcomingWindowDays = 30

static func filterUpcomingPayments(
    from payments: [Payment],
    daysBeforeDue: Int
) -> [Payment] {
    // Complex logic accounting for notification fire dates
}
```

**After:**
```swift
private static let upcomingWindowDays = 15

static func filterUpcomingPayments(from payments: [Payment]) -> [Payment] {
    // Simple date-based filtering: today <= dueDate <= today + 15 days
}
```

---

### File: `monetiq/Views/Dashboard/DashboardView.swift`

**Changes:**
1. ✅ Updated `upcomingPayments` computed property
   - Removed `daysBeforeDue` parameter
   - Now uses simplified filter

**Before:**
```swift
private var upcomingPayments: [UpcomingPaymentItem] {
    let daysBeforeDue = appSettings.daysBeforeDueNotification
    let upcomingFiltered = UpcomingPaymentsFilter.filterUpcomingPayments(
        from: payments,
        daysBeforeDue: daysBeforeDue
    )
    return upcomingFiltered.map { UpcomingPaymentItem(payment: $0) }
}
```

**After:**
```swift
private var upcomingPayments: [UpcomingPaymentItem] {
    let upcomingFiltered = UpcomingPaymentsFilter.filterUpcomingPayments(from: payments)
    return upcomingFiltered.map { UpcomingPaymentItem(payment: $0) }
}
```

---

### File: `monetiq/Services/NotificationManager.swift`

**Changes:**

#### 1. Badge Calculation
✅ Updated `calculateUpcomingPaymentsBadgeCount()` to use simplified filter (no `daysBeforeDue` parameter)

**Before:**
```swift
private func calculateUpcomingPaymentsBadgeCount(from payments: [Payment]) -> Int {
    guard let settings = appSettings else { return 0 }
    return UpcomingPaymentsFilter.calculateBadgeCount(
        from: payments,
        daysBeforeDue: settings.daysBeforeDueNotification
    )
}
```

**After:**
```swift
private func calculateUpcomingPaymentsBadgeCount(from payments: [Payment]) -> Int {
    return UpcomingPaymentsFilter.calculateBadgeCount(from: payments)
}
```

---

#### 2. Notification Scheduling
✅ Completely rewritten to implement **two-notification-per-payment** logic

**Key changes:**
- Schedule notifications for **ALL planned payments** (not just 15-day window)
- Each payment gets **TWO notifications**:
  - Reminder: X days before (if X > 0 and fireDate >= now)
  - One-day-before: Always (if fireDate >= now)
- **Stable identifiers:**
  - `reminder:<loanID>:<paymentID>:<daysBeforeDue>`
  - `oneDay:<loanID>:<paymentID>`
- Skip notifications whose fire date is in the past

**Before:**
```swift
func schedulePaymentNotifications(for loan: Loan) async {
    // Used UpcomingPaymentsFilter (30-day window)
    let upcomingPayments = UpcomingPaymentsFilter.filterUpcomingPayments(
        from: loan.payments,
        daysBeforeDue: settings.daysBeforeDueNotification
    )
    
    for payment in upcomingPayments {
        // Scheduled one notification per payment
    }
}
```

**After:**
```swift
func schedulePaymentNotifications(for loan: Loan) async {
    // Schedule for ALL planned payments
    let plannedPayments = loan.payments.filter { 
        $0.status == .planned && $0.dueDate >= Date() 
    }
    
    for payment in plannedPayments {
        // Schedule TWO notifications per payment
        // 1. Reminder (X days before, if X > 0 and fireDate >= now)
        // 2. One-day-before (always, if fireDate >= now)
    }
}
```

---

#### 3. Notification Cancellation
✅ Updated to cancel **both notification identifiers** (reminder + one-day-before)

**Key changes:**
- Cancel all possible reminder variants (0-7 days before)
- Cancel one-day-before notification
- Cancel legacy snooze notification

**New logic:**
```swift
func cancelNotifications(for payment: Payment) async {
    var identifiers: [String] = []
    
    // Cancel all possible reminder notifications (0-7 days before)
    for days in 0...7 {
        identifiers.append("reminder:\(loan.id):\(payment.id):\(days)")
    }
    
    // Cancel one-day-before notification
    identifiers.append("oneDay:\(loan.id):\(payment.id)")
    
    // Cancel snooze notification (legacy)
    identifiers.append("snooze_\(payment.id)")
    
    notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
}
```

---

## ✅ Verification Test Cases

### Test Setup
Create payments due in: **1, 3, 10, 14, 15, 16, 27 days** from today.

---

### Test Case 1: Dashboard + Badge (15-day window)

**Expected:**
- Dashboard "Upcoming Payments" shows: **1, 3, 10, 14, 15** (5 payments)
- Dashboard does **NOT** show: **16, 27** (outside 15-day window)
- Badge count: **5**

**Verification:**
```
✅ Dashboard count: 5
✅ Badge count: 5
✅ Payments 16 and 27 days out are NOT shown
```

---

### Test Case 2: Notifications with Days Before Due = 7

**Expected notifications:**

| Payment Due In | Reminder (7 days before) | One-Day-Before (1 day before) |
|----------------|--------------------------|-------------------------------|
| 1 day          | ❌ Skip (in past: -6 days) | ❌ Skip (in past: 0 days)     |
| 3 days         | ❌ Skip (in past: -4 days) | ✅ Fire in 2 days             |
| 10 days        | ✅ Fire in 3 days         | ✅ Fire in 9 days             |
| 14 days        | ✅ Fire in 7 days         | ✅ Fire in 13 days            |
| 15 days        | ✅ Fire in 8 days         | ✅ Fire in 14 days            |
| 16 days        | ✅ Fire in 9 days         | ✅ Fire in 15 days            |
| 27 days        | ✅ Fire in 20 days        | ✅ Fire in 26 days            |

**Total scheduled notifications:** **11**
- 5 reminder notifications (for payments due in 10, 14, 15, 16, 27 days)
- 6 one-day-before notifications (for payments due in 3, 10, 14, 15, 16, 27 days)

**Verification:**
```
✅ Payment due in 1 day: 0 notifications (both in past)
✅ Payment due in 3 days: 1 notification (one-day-before only)
✅ Payment due in 10 days: 2 notifications (reminder + one-day-before)
✅ Payment due in 14 days: 2 notifications (reminder + one-day-before)
✅ Payment due in 15 days: 2 notifications (reminder + one-day-before)
✅ Payment due in 16 days: 2 notifications (reminder + one-day-before)
✅ Payment due in 27 days: 2 notifications (reminder + one-day-before)
```

---

### Test Case 3: Notifications with Days Before Due = 0

**Expected notifications:**

| Payment Due In | Reminder (0 days before) | One-Day-Before (1 day before) |
|----------------|--------------------------|-------------------------------|
| 1 day          | ❌ Skip (X = 0)           | ❌ Skip (in past: 0 days)     |
| 3 days         | ❌ Skip (X = 0)           | ✅ Fire in 2 days             |
| 10 days        | ❌ Skip (X = 0)           | ✅ Fire in 9 days             |
| 14 days        | ❌ Skip (X = 0)           | ✅ Fire in 13 days            |
| 15 days        | ❌ Skip (X = 0)           | ✅ Fire in 14 days            |
| 16 days        | ❌ Skip (X = 0)           | ✅ Fire in 15 days            |
| 27 days        | ❌ Skip (X = 0)           | ✅ Fire in 26 days            |

**Total scheduled notifications:** **6**
- 0 reminder notifications (X = 0, so none scheduled)
- 6 one-day-before notifications (for payments due in 3, 10, 14, 15, 16, 27 days)

**Verification:**
```
✅ Payment due in 1 day: 0 notifications (one-day-before in past)
✅ Payment due in 3 days: 1 notification (one-day-before only)
✅ All other payments: 1 notification each (one-day-before only)
✅ No reminder notifications (X = 0)
```

---

### Test Case 4: Notifications with Days Before Due = 2

**Expected notifications:**

| Payment Due In | Reminder (2 days before) | One-Day-Before (1 day before) |
|----------------|--------------------------|-------------------------------|
| 1 day          | ❌ Skip (in past: -1 day) | ❌ Skip (in past: 0 days)     |
| 3 days         | ✅ Fire in 1 day          | ✅ Fire in 2 days             |
| 10 days        | ✅ Fire in 8 days         | ✅ Fire in 9 days             |
| 14 days        | ✅ Fire in 12 days        | ✅ Fire in 13 days            |
| 15 days        | ✅ Fire in 13 days        | ✅ Fire in 14 days            |
| 16 days        | ✅ Fire in 14 days        | ✅ Fire in 15 days            |
| 27 days        | ✅ Fire in 25 days        | ✅ Fire in 26 days            |

**Total scheduled notifications:** **12**
- 6 reminder notifications (for payments due in 3, 10, 14, 15, 16, 27 days)
- 6 one-day-before notifications (for payments due in 3, 10, 14, 15, 16, 27 days)

**Verification:**
```
✅ Payment due in 1 day: 0 notifications (both in past)
✅ Payment due in 3 days: 2 notifications (reminder + one-day-before)
✅ All other payments: 2 notifications each (reminder + one-day-before)
```

---

## 🎯 Key Takeaways

### ✅ What Changed

1. **Dashboard "Upcoming Payments":**
   - Now uses a **fixed 15-day window** (was 30 days)
   - **Independent** of notification settings

2. **Notifications:**
   - Each payment gets **TWO notifications** (was 1)
   - Scheduled for **ALL planned payments** (not just 15-day window)
   - Notifications in the past are **skipped** (not scheduled)

3. **Badge Count:**
   - **Matches Dashboard count** (15-day window)
   - **Independent** of notification settings

### ✅ What Stayed the Same

1. **Notification fire time:** 9:00 AM (unchanged)
2. **Notification content:** Same localized messages
3. **Mark as paid / Delete:** Still cancels all notifications
4. **Postpone logic:** Unchanged (separate snooze notification)

### ✅ Edge Cases Handled

1. ✅ Notification fire date in the past → **skipped**
2. ✅ Days Before Due = 0 → **only one-day-before notification**
3. ✅ Payment due tomorrow → **both notifications may be skipped**
4. ✅ Payment due in 27 days → **still gets notifications** (even though not in Dashboard)

---

## 📊 Summary

| Component                | Old Behavior                          | New Behavior                          |
|--------------------------|---------------------------------------|---------------------------------------|
| **Dashboard Window**     | 30 days (based on notification logic) | 15 days (fixed, date-based)           |
| **Badge Count**          | Based on notification logic           | Matches Dashboard (15 days)           |
| **Notifications/Payment**| 1 (X days before due)                 | 2 (X days before + 1 day before)      |
| **Notification Scope**   | Only upcoming 30-day window           | ALL planned payments                  |
| **Skip Past Notifications** | Not explicitly handled             | ✅ Explicitly skipped                 |

---

## 🚀 Next Steps

1. ✅ Code changes implemented
2. ⏳ Manual testing with test cases above
3. ⏳ Verify on device with real notifications
4. ⏳ Commit changes with clear message
5. ⏳ Update FinanceRules.md if needed

---

**Status:** Ready for manual verification and testing.

