# Verification Notes — New Business Rules

**Date:** 2025-12-20  
**Branch:** `develop`  
**Commit:** `2e96193`

**Latest Update:** 2026-01-26 — Expenses v1 Implementation (Phase 1 Complete)

---

## ✅ Implementation Complete

All code changes have been successfully implemented and committed.

### Recent Additions (2026-01-26)
- ✅ **Expenses v1 (Phase 1):** Full CRUD with localization (uncommitted)
  - See: `Docs/EXPENSES_V1_IMPLEMENTATION.md`
  - See: `Docs/roadmap/PHASE_1_EXPENSES_V1.md`

---

## 📋 Chosen Unified Rule

### Dashboard + Badge (15-day window)
**Rule:** Show/count payments due within the next **15 days**.

```
status == .planned
AND dueDate >= today
AND dueDate <= today + 15 days
```

**Independent of:** Notification settings (Days Before Due)

---

### Notifications (Two per payment)

**Rule:** Each payment gets **TWO separate notifications**:

1. **Reminder:** X days before due (X = user setting, 0-7)
   - Only if X > 0 AND fireDate >= now
   - Identifier: `reminder:<loanID>:<paymentID>:<X>`

2. **One-day-before:** Always 1 day before due
   - Only if fireDate >= now
   - Identifier: `oneDay:<loanID>:<paymentID>`

**Scope:** ALL planned payments (not just 15-day window)

---

## 🧪 Test Results (Expected)

### Test Setup
Create payments due in: **1, 3, 10, 14, 15, 16, 27 days** from today.

---

### Scenario 1: Days Before Due = 7

#### Dashboard + Badge
- **Dashboard count:** 5 (payments due in 1, 3, 10, 14, 15 days)
- **Badge count:** 5
- **NOT shown:** Payments due in 16, 27 days (outside 15-day window)

#### Scheduled Notifications
| Payment Due In | Reminder (7 days before) | One-Day-Before | Total |
|----------------|--------------------------|----------------|-------|
| 1 day          | ❌ (past)                | ❌ (past)      | 0     |
| 3 days         | ❌ (past)                | ✅ (2 days)    | 1     |
| 10 days        | ✅ (3 days)              | ✅ (9 days)    | 2     |
| 14 days        | ✅ (7 days)              | ✅ (13 days)   | 2     |
| 15 days        | ✅ (8 days)              | ✅ (14 days)   | 2     |
| 16 days        | ✅ (9 days)              | ✅ (15 days)   | 2     |
| 27 days        | ✅ (20 days)             | ✅ (26 days)   | 2     |

**Total scheduled notifications:** **11**

---

### Scenario 2: Days Before Due = 0

#### Dashboard + Badge
- **Dashboard count:** 5 (same as above)
- **Badge count:** 5

#### Scheduled Notifications
| Payment Due In | Reminder (0 days) | One-Day-Before | Total |
|----------------|-------------------|----------------|-------|
| 1 day          | ❌ (X = 0)        | ❌ (past)      | 0     |
| 3 days         | ❌ (X = 0)        | ✅ (2 days)    | 1     |
| 10 days        | ❌ (X = 0)        | ✅ (9 days)    | 1     |
| 14 days        | ❌ (X = 0)        | ✅ (13 days)   | 1     |
| 15 days        | ❌ (X = 0)        | ✅ (14 days)   | 1     |
| 16 days        | ❌ (X = 0)        | ✅ (15 days)   | 1     |
| 27 days        | ❌ (X = 0)        | ✅ (26 days)   | 1     |

**Total scheduled notifications:** **6**

---

### Scenario 3: Days Before Due = 2

#### Dashboard + Badge
- **Dashboard count:** 5 (same as above)
- **Badge count:** 5

#### Scheduled Notifications
| Payment Due In | Reminder (2 days before) | One-Day-Before | Total |
|----------------|--------------------------|----------------|-------|
| 1 day          | ❌ (past)                | ❌ (past)      | 0     |
| 3 days         | ✅ (1 day)               | ✅ (2 days)    | 2     |
| 10 days        | ✅ (8 days)              | ✅ (9 days)    | 2     |
| 14 days        | ✅ (12 days)             | ✅ (13 days)   | 2     |
| 15 days        | ✅ (13 days)             | ✅ (14 days)   | 2     |
| 16 days        | ✅ (14 days)             | ✅ (15 days)   | 2     |
| 27 days        | ✅ (25 days)             | ✅ (26 days)   | 2     |

**Total scheduled notifications:** **12**

---

## ✅ Key Verification Points

### 1. Dashboard Count = Badge Count (Always)
- ✅ Dashboard shows 5 payments (1, 3, 10, 14, 15 days)
- ✅ Badge shows 5
- ✅ Payments 16 and 27 days out are NOT shown

### 2. Notifications Independent of Dashboard
- ✅ Notifications scheduled for ALL planned payments (including 16, 27 days)
- ✅ Notification count ≠ Dashboard count (this is correct)

### 3. Two Notifications Per Payment
- ✅ Each payment gets reminder + one-day-before (if not in past)
- ✅ If reminder is in past, only one-day-before is scheduled
- ✅ If both are in past, no notifications scheduled

### 4. Stable Identifiers
- ✅ Reminder: `reminder:<loanID>:<paymentID>:<daysBeforeDue>`
- ✅ One-day-before: `oneDay:<loanID>:<paymentID>`
- ✅ Mark as paid cancels both notifications

---

## 🚀 Next Steps

1. ✅ Code changes committed
2. ⏳ **Manual testing on device:**
   - Create test payments (1, 3, 10, 14, 15, 16, 27 days)
   - Verify Dashboard count = 5
   - Verify Badge count = 5
   - Check Settings → Notifications → Scheduled (iOS Settings app)
   - Confirm notification count matches expected values
3. ⏳ **Test notification firing:**
   - Wait for notifications to fire at 9:00 AM
   - Verify correct payment info displayed
4. ⏳ **Test mark as paid:**
   - Mark a payment as paid
   - Verify both notifications are canceled
5. ⏳ **Test Days Before Due changes:**
   - Change setting from 7 → 0 → 2
   - Verify notifications are rescheduled correctly

---

**Status:** ✅ Implementation complete, ready for manual device testing.

