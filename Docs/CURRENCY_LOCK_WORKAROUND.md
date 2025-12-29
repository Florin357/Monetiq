# Currency Lock Workaround — Disable Currency Change on Edit

**Date:** December 21, 2025  
**Branch:** `develop`  
**Status:** ✅ IMPLEMENTED (not committed, ready for local testing)

---

## Purpose

**Temporary workaround** to prevent the Payment Schedule bug that occurs when changing a loan's currency during edit.

### Background
- **Known Issue:** Changing currency when editing an existing loan can cause the Payment Schedule to become incomplete or disappear.
- **Root Cause:** Logic inconsistency in payment regeneration (documented separately).
- **This Workaround:** Disable currency editing entirely for existing loans until the underlying bug is fixed.

---

## Implementation

### UX Behavior

#### When Creating a NEW Loan:
✅ Currency selector is fully editable  
✅ User can select any supported currency  
✅ No restrictions or warnings  

#### When Editing an EXISTING Loan:
🔒 Currency selector is **disabled** (greyed out, non-interactive)  
ℹ️ Helper text displayed: "Currency can't be changed after the loan is created."  
✅ All other fields remain editable (amount, frequency, duration, etc.)  

### Visual Design
- **Disabled State:** Standard SwiftUI `.disabled()` modifier (greyed out appearance)
- **Helper Text:** 
  - Font: `MonetiqTheme.Typography.caption`
  - Color: `MonetiqTheme.Colors.textSecondary`
  - Placement: Directly below the currency picker, inside the same section
  - Padding: Horizontal + top spacing for clean alignment

---

## Code Changes

### 1. Localization Keys (All 9 Languages)

**New Key:** `currency_locked_message`

#### English (EN)
```
"currency_locked_message" = "Currency can't be changed after the loan is created.";
```

#### Romanian (RO)
```
"currency_locked_message" = "Moneda nu poate fi schimbată după crearea împrumutului.";
```

#### German (DE)
```
"currency_locked_message" = "Die Währung kann nach der Erstellung des Darlehens nicht mehr geändert werden.";
```

#### Italian (IT)
```
"currency_locked_message" = "La valuta non può essere modificata dopo la creazione del prestito.";
```

#### Spanish (ES)
```
"currency_locked_message" = "La moneda no se puede cambiar después de crear el préstamo.";
```

#### French (FR)
```
"currency_locked_message" = "La devise ne peut pas être modifiée après la création du prêt.";
```

#### Russian (RU)
```
"currency_locked_message" = "Валюту нельзя изменить после создания займа.";
```

#### Hindi (HI)
```
"currency_locked_message" = "ऋण बनाने के बाद मुद्रा नहीं बदली जा सकती।";
```

#### Chinese Simplified (ZH-Hans)
```
"currency_locked_message" = "创建贷款后无法更改货币。";
```

---

### 2. AddEditLoanView.swift Changes

**File:** `monetiq/Views/Loans/AddEditLoanView.swift`  
**Section:** Financial Details (line 158-174)

#### Before:
```swift
Section(L10n.string("financial_details_section")) {
    HStack {
        TextField(L10n.string("amount_placeholder"), text: $principalAmount)
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
            .onChange(of: principalAmount) { oldValue, newValue in
                principalAmount = formatNumericInput(newValue, allowDecimals: true)
            }
        
        Picker(L10n.string("currency_label"), selection: $selectedCurrency) {
            ForEach(currencies, id: \.self) { currency in
                Text(currency).tag(currency)
            }
        }
        .pickerStyle(.menu)
    }
}
```

#### After:
```swift
Section(L10n.string("financial_details_section")) {
    HStack {
        TextField(L10n.string("amount_placeholder"), text: $principalAmount)
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
            .onChange(of: principalAmount) { oldValue, newValue in
                principalAmount = formatNumericInput(newValue, allowDecimals: true)
            }
        
        Picker(L10n.string("currency_label"), selection: $selectedCurrency) {
            ForEach(currencies, id: \.self) { currency in
                Text(currency).tag(currency)
            }
        }
        .pickerStyle(.menu)
        .disabled(editingLoan != nil) // ✅ ADDED: Disable when editing
    }
    
    // ✅ ADDED: Show helper text when editing
    if editingLoan != nil {
        Text(L10n.string("currency_locked_message"))
            .font(MonetiqTheme.Typography.caption)
            .foregroundColor(MonetiqTheme.Colors.textSecondary)
            .padding(.horizontal, MonetiqTheme.Spacing.md)
            .padding(.top, MonetiqTheme.Spacing.xs)
    }
}
```

**Key Changes:**
1. Added `.disabled(editingLoan != nil)` to the currency Picker
2. Added conditional helper text that only appears when `editingLoan != nil`

---

## Manual Testing Checklist

### Test Case 1: Create New Loan (Currency Editable)
- [ ] Tap "+" to create new loan
- [ ] Navigate to Financial Details section
- [ ] **Expected:** Currency picker is enabled (not greyed out)
- [ ] **Expected:** No helper text visible
- [ ] Tap currency picker → select different currency (e.g., USD → EUR)
- [ ] **Expected:** Currency changes successfully
- [ ] Complete and save loan

### Test Case 2: Edit Existing Loan (Currency Locked)
- [ ] Open an existing loan (e.g., 10,000 EUR loan)
- [ ] Tap "Edit" button
- [ ] Navigate to Financial Details section
- [ ] **Expected:** Currency picker is **disabled** (greyed out)
- [ ] **Expected:** Helper text visible: "Currency can't be changed after the loan is created."
- [ ] Try tapping the currency picker
- [ ] **Expected:** Nothing happens (picker is non-interactive)
- [ ] Verify all other fields are still editable (amount, frequency, etc.)

### Test Case 3: Localization (All Languages)
For each language (EN, RO, DE, IT, ES, FR, RU, HI, ZH-Hans):
- [ ] Change app language in Settings
- [ ] Edit an existing loan
- [ ] **Expected:** Helper text appears in the correct language
- [ ] **Expected:** No raw localization keys (e.g., `currency_locked_message`) displayed
- [ ] **Expected:** Text is readable and fits within the UI (no truncation)

#### Quick Verification (Sample Languages):
- [ ] **English:** "Currency can't be changed after the loan is created."
- [ ] **Romanian:** "Moneda nu poate fi schimbată după crearea împrumutului."
- [ ] **German:** "Die Währung kann nach der Erstellung des Darlehens nicht mehr geändert werden."
- [ ] **Hindi:** "ऋण बनाने के बाद मुद्रा नहीं बदली जा सकती।"
- [ ] **Chinese:** "创建贷款后无法更改货币。"

### Test Case 4: Light & Dark Mode
- [ ] Edit existing loan in Light mode
- [ ] **Expected:** Helper text is readable (secondary text color)
- [ ] Switch to Dark mode
- [ ] **Expected:** Helper text adapts to dark theme and remains readable

### Test Case 5: Small Screen Devices
- [ ] Test on iPhone SE or smallest supported device
- [ ] Edit existing loan
- [ ] **Expected:** Helper text does not overflow or break layout
- [ ] **Expected:** Text wraps gracefully if needed

### Test Case 6: Edge Cases
- [ ] Create loan → immediately edit it (before any payments are made)
- [ ] **Expected:** Currency is still locked (workaround applies to all existing loans)
- [ ] Create loan → mark some payments as paid → edit loan
- [ ] **Expected:** Currency is locked, helper text visible

---

## Impact Assessment

### What Changed
✅ Currency picker disabled when editing existing loans  
✅ Helper text added to explain why currency is locked  
✅ Localization added for all 9 supported languages  

### What Did NOT Change
✅ No changes to business logic or payment calculations  
✅ No changes to loan creation flow (currency still editable for new loans)  
✅ No changes to other fields in edit mode (all remain editable)  
✅ No changes to data model or persistence  
✅ No changes to other screens (Dashboard, Loans list, Loan Details, etc.)  

### Risk Level
**VERY LOW** — This is a purely UI-level restriction:
1. Uses standard SwiftUI `.disabled()` modifier (no custom logic)
2. Conditional rendering based on existing `editingLoan` flag
3. No impact on existing data or calculations
4. Fully reversible (can be removed when underlying bug is fixed)

---

## Files Modified

### Swift Code
1. **`monetiq/Views/Loans/AddEditLoanView.swift`**
   - Line 167-174: Added `.disabled()` modifier and conditional helper text

### Localization Files (All 9 Languages)
2. **`monetiq/Resources/Localizable.strings`** (English)
3. **`monetiq/Resources/ro.lproj/Localizable.strings`** (Romanian)
4. **`monetiq/Resources/de.lproj/Localizable.strings`** (German)
5. **`monetiq/Resources/it.lproj/Localizable.strings`** (Italian)
6. **`monetiq/Resources/es.lproj/Localizable.strings`** (Spanish)
7. **`monetiq/Resources/fr.lproj/Localizable.strings`** (French)
8. **`monetiq/Resources/ru.lproj/Localizable.strings`** (Russian)
9. **`monetiq/Resources/hi.lproj/Localizable.strings`** (Hindi)
10. **`monetiq/Resources/zh-Hans.lproj/Localizable.strings`** (Chinese Simplified)

### Documentation
11. **`Docs/CURRENCY_LOCK_WORKAROUND.md`** (NEW - this file)

---

## Future Considerations

### When to Remove This Workaround
This workaround should be removed once the underlying Payment Schedule bug is fixed:
1. Fix the root cause (synchronize deletion and regeneration checks in `AddEditLoanView.swift`)
2. Thoroughly test currency change during edit
3. Confirm Payment Schedule remains intact after currency change
4. Remove `.disabled(editingLoan != nil)` modifier
5. Remove conditional helper text
6. (Optional) Keep the localization key for potential future use, or remove it

### Alternative Approach (If Needed)
If the underlying bug cannot be fixed immediately, consider:
- **Option A (Current):** Keep currency locked for all existing loans
- **Option B (Advanced):** Allow currency change but show a warning dialog:
  - "Changing currency will regenerate the payment schedule. Paid payments will be preserved. Continue?"
  - Requires implementing the fix first, then adding confirmation UI

---

## Commit Message (Suggested)

```
Workaround: Disable currency change when editing existing loans

PROBLEM:
Changing currency when editing a loan causes Payment Schedule to
become incomplete or disappear (known bug).

TEMPORARY SOLUTION:
Disable currency picker when editing existing loans to prevent users
from triggering the bug.

UX CHANGES:
✅ New loans: Currency fully editable (no change)
✅ Existing loans: Currency picker disabled (greyed out)
✅ Helper text: "Currency can't be changed after the loan is created."
✅ Localized in all 9 supported languages

IMPLEMENTATION:
- Added .disabled(editingLoan != nil) to currency Picker
- Added conditional helper text below currency picker
- Added 'currency_locked_message' key to all localization files

IMPACT: VERY LOW RISK
- UI-only restriction using standard SwiftUI .disabled()
- No changes to business logic or data model
- Fully reversible when underlying bug is fixed

FILES MODIFIED:
- monetiq/Views/Loans/AddEditLoanView.swift (disable picker + helper text)
- monetiq/Resources/*.lproj/Localizable.strings (9 languages)
- Docs/CURRENCY_LOCK_WORKAROUND.md (NEW - comprehensive documentation)

NEXT STEPS:
Remove this workaround once Payment Schedule bug is fixed.
```

---

## Status: ✅ READY FOR LOCAL TESTING

**DO NOT COMMIT YET** — User requested local testing first.

### How to Test
1. Run the app in DEBUG or Release mode
2. Create a new loan → verify currency is editable
3. Edit that loan → verify currency is disabled + helper text visible
4. Test in at least 3 languages (EN, RO, one other)
5. Test in Light & Dark mode
6. Confirm no linter errors
7. Confirm no crashes or UI breaks

