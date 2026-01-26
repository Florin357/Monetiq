# Phase 1: Expenses v1 Implementation Plan

## Overview
Add manual and recurring Expenses tracking to Ypsilon with full CRUD capabilities, multi-platform support, and complete localization.

**Version:** 1.1 (Build 8+)  
**Branch:** `develop`  
**Status:** Phase 1 - Foundation Only

---

## Goals

### What We ARE Adding
- **Expense Model:** New SwiftData entity for tracking expenses (one-time and recurring)
- **Expense Occurrences:** Individual expense instances with paid/planned status
- **Expenses Tab:** New tab in main navigation between Dashboard and Income
- **Full CRUD:** Add, Edit, Delete expenses on all platforms (iPhone, iPad, Mac)
- **Active/Completed Sections:** Visual separation with purple styling for completed
- **Localization:** All strings in 9 supported languages
- **Cross-Platform UX:** Swipe actions on iOS/iPad, context menu + EditButton on Mac

### What We Are NOT Adding (Phase 1)
- ❌ Dashboard "TO PAY" integration (Phase 2)
- ❌ Upcoming Payments integration (Phase 2)
- ❌ Cashflow chart integration (Phase 2)
- ❌ Notification reminders for expenses (Phase 2)
- ❌ Expense categories (optional field only, no predefined categories)
- ❌ Expense analytics or reports
- ❌ Expense attachments or receipts

---

## Data Model

### Expense Entity
```swift
@Model
final class Expense {
    var id: UUID
    var title: String
    var amount: Double
    var currencyCode: String
    var frequency: ExpenseFrequency
    var startDate: Date
    var endDate: Date?  // optional, for recurring
    var notes: String?
    var category: String?  // optional, user-defined
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade)
    var occurrences: [ExpenseOccurrence]
}
```

**Frequency Options:**
- `oneTime` - Single expense
- `weekly` - Repeats every week
- `monthly` - Repeats every month
- `quarterly` - Repeats every 3 months
- `yearly` - Repeats every year

### ExpenseOccurrence Entity
```swift
@Model
final class ExpenseOccurrence {
    var id: UUID
    var dueDate: Date
    var amount: Double
    var status: ExpenseStatus  // planned, paid
    var paidDate: Date?
    
    var expense: Expense?
}
```

**Computed Properties** (similar to IncomeSource):
- `nextDueDate: Date?` - Next planned occurrence
- `isCompleted: Bool` - All occurrences paid or endDate passed
- `upcomingOccurrences: [ExpenseOccurrence]` - Planned occurrences sorted by date

---

## UI Design

### Tab Structure
**Order:** Dashboard → **Expenses** → Income → Loans → Calculator → Settings

**Tab Icon:** `cart.fill` (distinct from existing icons)

### ExpenseListView
```
┌─────────────────────────────┐
│ Expenses             [+]    │ ← Header + Add button
│ Track your spending         │
├─────────────────────────────┤
│ ACTIVE                      │ ← Section 1
│                             │
│ ┌─────────────────────────┐│
│ │ 🛒 Groceries            ││
│ │ $150.00 USD             ││
│ │ Next: Jan 28, 2026      ││
│ └─────────────────────────┘│
│                             │
│ ┌─────────────────────────┐│
│ │ 💡 Utilities            ││
│ │ €75.00 EUR              ││
│ │ Monthly • Next: Feb 1   ││
│ └─────────────────────────┘│
├─────────────────────────────┤
│ COMPLETED                   │ ← Section 2 (purple)
│                             │
│ ┌─────────────────────────┐│
│ │ 🎭 Concert Ticket       ││
│ │ $45.00 USD              ││
│ │ On: Dec 15, 2025        ││
│ └─────────────────────────┘│
└─────────────────────────────┘
```

**Row Display:**
- Title (bold, 17pt)
- Amount + currency (formatted)
- Frequency indicator (for recurring)
- Next due date (for active)
- Category badge (if present, subtle)

### AddEditExpenseView
**Form Fields:**
1. Title (required)
2. Amount (required, decimal input)
3. Currency (picker, default from app settings)
4. Frequency (picker: one-time, weekly, monthly, quarterly, yearly)
5. Start Date (date picker)
6. End Date (optional, only visible for recurring)
7. Category (optional text field)
8. Notes (optional text area)

**Actions:**
- Save (validates required fields)
- Cancel (dismisses without saving)
- Delete (only when editing, shows confirmation)

---

## Cross-Platform Support

### iPhone/iPad
- **Swipe Left:** Edit, Delete buttons
- **Tap Row:** Opens edit sheet
- **Long Press:** Context menu (bonus)

### macOS
- **Context Menu (Right-Click):** Edit, Delete options
- **EditButton in Toolbar:** Native list edit mode
- **Click Row:** Opens edit sheet
- **No Swipe Actions:** Platform-specific guards

**Implementation:**
```swift
#if !os(macOS)
.swipeActions(edge: .trailing) { /* actions */ }
#endif
.contextMenu { /* same actions, all platforms */ }
```

---

## Localization

### String Keys (9 Languages)

**Languages:** English, German, Spanish, French, Hindi, Italian, Romanian, Russian, Chinese (Simplified)

**Required Keys:**
```
// Tab
tab_expenses

// Expenses Screen
expenses_title
expenses_subtitle
expenses_empty_title
expenses_empty_subtitle
expenses_add_title
expenses_edit_title

// Sections
expenses_section_active
expenses_section_completed

// Form Fields
expenses_field_title
expenses_field_amount
expenses_field_currency
expenses_field_frequency
expenses_field_start_date
expenses_field_end_date
expenses_field_category
expenses_field_notes

// Frequencies
frequency_onetime
frequency_weekly
frequency_monthly
frequency_quarterly
frequency_yearly

// Actions
expenses_delete_title
expenses_delete_message

// Row Display
expenses_next
expenses_one_time_on
```

---

## Phase 2 Integration Points

### Dashboard "TO PAY" Card
**Implementation:** (Phase 2)
- Query all active ExpenseOccurrences where status = planned
- Sum by currency
- Add to existing TO PAY aggregation
- Show expense breakdown in detail view

**Estimated:** ~2 hours

### Upcoming Payments Section
**Implementation:** (Phase 2)
- Extend `UpcomingItemType` enum: add `case expenseOccurrence`
- Add `UpcomingPaymentItem` initializer for ExpenseOccurrence
- Include expenses in next 30 days query
- Sort by due date alongside loans/income

**Estimated:** ~3 hours

### Cashflow Chart (30 days)
**Implementation:** (Phase 2)
- Include expense occurrences in "To Pay" line calculation
- Aggregate expense amounts by day
- Maintain separate tracking from loan payments
- Update chart legend if needed

**Estimated:** ~2 hours

### Notifications
**Implementation:** (Phase 2)
- Schedule local notifications for upcoming expense due dates
- Use existing NotificationManager pattern
- Add expense-specific notification content
- Cancel notifications when expense deleted

**Estimated:** ~2 hours

**Total Phase 2 Estimated:** ~9 hours

---

## Test Checklist

### Functional Tests
- [ ] App compiles on iOS 17+
- [ ] Expenses tab appears between Dashboard and Income
- [ ] Tab icon is `cart.fill` (distinct from other tabs)
- [ ] Empty state displays when no expenses
- [ ] Add expense → appears in Active section
- [ ] Edit expense via tap (all platforms)
- [ ] Edit expense via swipe (iOS/iPad only)
- [ ] Edit expense via context menu (all platforms)
- [ ] Delete expense with confirmation
- [ ] One-time expense shows correct date
- [ ] Recurring expense shows next due date
- [ ] Completed expenses appear in Completed section
- [ ] Completed section header is purple/violet
- [ ] Category displays when present (subtle)

### Platform-Specific Tests
**iPhone:**
- [ ] Swipe left shows Edit, Delete
- [ ] Context menu works on long press
- [ ] Sheet navigation works

**iPad:**
- [ ] Same as iPhone
- [ ] Layout adapts to landscape

**macOS:**
- [ ] EditButton appears in toolbar
- [ ] Context menu (right-click) works
- [ ] No swipe actions visible
- [ ] List edit mode works correctly

### Localization Tests
- [ ] All strings resolve (no raw keys)
- [ ] English (EN) spot check
- [ ] Romanian (RO) spot check
- [ ] Currency formatting respects locale
- [ ] Date formatting respects locale

### Data Integrity Tests
- [ ] Expense persists after app restart
- [ ] Occurrences generate correctly
- [ ] Delete cascade works (expense + occurrences)
- [ ] No interference with Loans/Income data

---

## Files Created

### Models
- `monetiq/Models/Expense.swift`
- `monetiq/Models/ExpenseOccurrence.swift`

### Views
- `monetiq/Views/Expenses/ExpenseListView.swift`
- `monetiq/Views/Expenses/ExpenseRowView.swift`
- `monetiq/Views/Expenses/AddEditExpenseView.swift`

### Documentation
- `Docs/roadmap/PHASE_1_EXPENSES_V1.md` (this file)

---

## Files Modified

- `monetiq/Views/ContentView.swift` - Add Expenses tab
- `monetiq/App/monetiqApp.swift` - Register Expense/ExpenseOccurrence models
- `monetiq/Resources/Localizable.strings` - Add expense strings (EN)
- `monetiq/Resources/de.lproj/Localizable.strings` - German
- `monetiq/Resources/es.lproj/Localizable.strings` - Spanish
- `monetiq/Resources/fr.lproj/Localizable.strings` - French
- `monetiq/Resources/hi.lproj/Localizable.strings` - Hindi
- `monetiq/Resources/it.lproj/Localizable.strings` - Italian
- `monetiq/Resources/ro.lproj/Localizable.strings` - Romanian
- `monetiq/Resources/ru.lproj/Localizable.strings` - Russian
- `monetiq/Resources/zh-Hans.lproj/Localizable.strings` - Chinese (Simplified)

---

## Files NOT Changed

- Dashboard logic and views
- Cashflow calculations
- Notification manager
- Loan models and views
- Income models and views
- Settings
- Calculator

---

## Success Criteria

Phase 1 is complete when:

1. ✅ Expenses tab is visible and functional
2. ✅ User can add/edit/delete expenses on all platforms
3. ✅ Active/Completed sections work correctly
4. ✅ All strings are localized in 9 languages
5. ✅ No impact on existing Loans/Income functionality
6. ✅ App builds and runs without errors
7. ✅ No commits made yet (ready for testing)

---

## Next Steps (Phase 2)

1. Implement Dashboard TO PAY integration
2. Add expenses to Upcoming Payments section
3. Integrate expenses into Cashflow chart
4. Add expense notifications
5. Consider expense categories (predefined list)
6. Test complete workflow end-to-end
7. Commit Phase 1 + Phase 2 together

---

**Document Version:** 1.0  
**Created:** 2026-01-26  
**Last Updated:** 2026-01-26  
**Author:** AI Assistant (Cursor)

